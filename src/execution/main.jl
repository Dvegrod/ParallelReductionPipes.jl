
using Plots

TRIALS = 2000

flags = Dict{String,Bool}([
    "--log" => true
])

global logfile = undef

# Requires write mode
function ready(io :: ADIOS2.AIO, engine :: ADIOS2.Engine, comm :: MPI.Comm, ready_val :: Int)
    if MPI.Comm_rank(comm) == 2
        var = metadata[:exec_ready]
        if ready_val == 1
            declare_and_set(io, engine, var, 1)
        else
            _set(io, engine, :exec_ready, ready_val)
        end
        @warn "READY $ready_val"
    end
    MPI.Barrier(comm)
end

# Requires read mode
function listen(io::ADIOS2.AIO, engine::ADIOS2.Engine, comm::MPI.Comm)::Bool
    bool = false

    if MPI.Comm_rank(comm) == 0
        for _ in 1:TRIALS
            config_ready = _get(io, engine, :ready)

            @show config_ready

            if config_ready !== nothing && config_ready > 0
                bool = true
                break
            end

            @warn "LISTENING"
            sleep(1)
        end
    end
    bool = MPI.Bcast(bool, 0, comm)
    return bool
end


function get_input(io :: ADIOS2.AIO, engine::ADIOS2.Engine,
                   var_name :: String, var_shape :: Tuple,
                   rank :: Int, dims :: Union{Tuple, Vector}) :: LocalDomain

    y = inquire_variable(io, var_name)

    if isnothing(y)
        e = ArgumentError("Invalid value, it is not available on the specified IO")
        throw(e)
    end

    # Perform slicing
    start, size, _ = localChunkSelection(var_shape, (0,0,), rank, dims)

    @show start,size

    set_selection(y, start, size)

    array = Array{type(y)}(undef, size...)

    get(engine, y, array)

    perform_gets(engine)

    @show sum(array)

    return LocalDomain(array, start, size)
end

function reduce_dim(in :: Tuple) :: Tuple

    t = Int[]
    for i in in
        if i > 0
            push!(t, i)
        else
            # push!(t, 1)
        end
    end

    return Tuple(t)
end

function execute_layer(input :: LocalDomain, config ::Array) :: LocalDomain

    # Config are 7 numbers, x1 operator x3 kernel shape x3 output shape in that order

    in_shape = input.size
    ker_shape = reduce_dim(Tuple(config[2:4]))
    out_shape = reduce_dim(Tuple(config[5:7]))

    # TODO Save on allocation time
    output = transform(input, ker_shape, Array{Float64}(undef, [50,50]...))

    @show output.size

    # TODO
    @parallel (1:output.size[1], 1:output.size[2], 1:1) reduction_functions[config[1]](input.data, output.data)
    #in_shape, ker_shape)
    return output
end

function define_output(io::ADIOS2.AIO, out_shape::Tuple{Int}) :: ADIOS2.Variable


    # TODO
    sh = out_shape
    st = Tuple([0 for i in out_shape])
    cn = out_shape

    y = define_variable(io, "out", Float64, sh, st, cn)

    return y
end

function submit_output(io::ADIOS2.AIO, engine::ADIOS2.Engine, input::LocalDomain, global_shape)

    define_variable(io, "out", Float64, global_shape, input.start, input.size)

    y = inquire_variable(io, "out")

    if isnothing(y)
        e = ArgumentError("Out var has not been defined yet")
        throw(e)
    end

    @show input.start, input.size, global_shape

    put!(engine, y, input.data)
    perform_puts!(engine)
end

function main()
    # Initialization
    # Parallel stencil

    # MPI
    MPI.Init()

    rank = MPI.Comm_rank(MPI.COMM_WORLD)
    size = MPI.Comm_size(MPI.COMM_WORLD)

    dims = MPI.Dims_create(size, [0,0])

    # Flag parse
    for i in ARGS
        if i in keys(flags)
            # Switch flag
            flags[i] = !flags[i]
        end
    end

    # ADIOS INIT COMMUNICATION STREAM
    adios = adios_init_mpi(MPI.COMM_WORLD)
    comm_io = declare_io(adios, "OUTCOMMIO_WRITE")

    comm_engine = open(comm_io, "reducer-r.bp", mode_write)

    ready(comm_io, comm_engine, MPI.COMM_WORLD, 1)

    comm_io2 = declare_io(adios, "OUTCOMMIO_READ")

    # WAIT FOR reducer-l.bp existence
    # TODO

    comm_engine2 = open(comm_io2, "reducer-l.bp", mode_readRandomAccess)

    # LISTEN FOR CONFIGURATION ARRIVAL
    if !listen(comm_io2, comm_engine2, MPI.COMM_WORLD)
        error("Listen timeout, $TRIALS trials.")
    end

    # # Logger
    # if flags["--log"]
    #     logfile = open("./reducer-logs.log", mode_write)
    # end

    # Get pipeline config
    pipeline_vars = inquirePipelineConfigurationStructure(comm_io2)
    pipeline_config = getPipelineConfigurationStructure(comm_engine2, pipeline_vars)

    ready(comm_io, comm_engine, MPI.COMM_WORLD, 2)

    # ADIOS INIT INPUT STREAM
    input_io = declare_io(adios, "INPUT_IO")

    input_engine = open(input_io, pipeline_config[:engine], mode_readRandomAccess)

    # ADIOS INIT OUTPUT STREAM
    output_io = declare_io(adios, "OUTPUT_IO")

    output_engine = open(output_io, "reducer-o.bp", mode_write)

    # Execute pipeline

    # STEP LOOP

    # INPUT CHUNK
    output = get_input(input_io, input_engine,
                       pipeline_config[:var_name], reduce_dim(Tuple(pipeline_config[:var_shape])),
                       rank, dims)

    spy(output.data)
    savefig("in-$rank.png")
    # PROCESS CHUNK
    @show pipeline_config[:layer_config][1, :]
    for i in 1:pipeline_config[:n_layers]
        output = execute_layer(output, pipeline_config[:layer_config][i,:])
        @show output.start, output.size
    end

    spy(output.data)
    savefig("out-$rank.png")
    # OUTPUT CHUNK
    submit_output(output_io, output_engine, output, reduce_dim(Tuple(pipeline_config[:layer_config][pipeline_config[:n_layers], 5:7])))

    close(comm_engine)
    close(comm_engine2)
    close(input_engine)
    close(output_engine)
    MPI.Finalize()

end

