


TRIALS = 2000

flags = Dict{String,Bool}([
    "--log" => true
])

global logfile = undef

# Requires write mode
function ready(io :: ADIOS2.AIO, engine :: ADIOS2.Engine, comm :: MPI.Comm)

    if MPI.Comm_rank(comm) == 0
        var = metadata[:exec_ready]
        declare_and_set(io, engine, var, 1)
        @warn "READY"
    end
    MPI.Barrier(comm)
end

# Requires read mode
function listen(io::ADIOS2.AIO, engine::ADIOS2.Engine, comm::MPI.Comm)::Bool
    bool = false

    if MPI.Comm_rank(comm) == 0
        for _ in 1:TRIALS
            config_ready = _get(io, engine, :ready)

            if config_ready > 0
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


function get_input(io :: ADIOS2.AIO, engine::ADIOS2.Engine, var_name :: String,
                   rank :: Int, dims :: Union{Tuple, Vector}) :: LocalDomain

    y = inquire_variable(io, var_name)

    if isnothing(y)
        e = ArgumentError("Invalid value, it is not available on the specified IO")
        throw(e)
    end

    # Perform slicing
    start, size, _ = localChunkSelection(shape(y), rank, dims)

    set_selection(y, start, size)

    array = Array{type(y)}(undef, size...)

    _get(engine, y, array)

    perform_gets(engine)

    return LocalDomain(start, size, array)
end

function execute_layer(input :: LocalDomain, config ::Array) :: LocalDomain

    # Config are 7 numbers, x1 operator x3 kernel shape x3 output shape in that order

    in_shape = shape(input)
    ker_shape = Tuple(config[2:4])
    out_shape = Tuple(config[5:7])

    # TODO Save on allocation time
    output = transform(input, ker_shape, Array(undef, out_shape...))

    @parallel (1:out_shape[1], 1:out_shape[2], 1:out_shape[3]) reduction_functions[config[1]](input.data, output.data,
        in_shape, ker_shape)
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

function submit_output(io::ADIOS2.AIO, engine::ADIOS2.Engine, input::LocalDomain)

    y = inquire_variable(io, "out")

    if isnothing(y)
        e = ArgumentError("Out var has not been defined yet")
        throw(e)
    end

    # Set local selection
    set_selection(y, input.start, input.size)

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


    # Flag parse
    for i in ARGS
        if i in keys(flags)
            # Switch flag
            flags[i] = !flags[i]
        end
    end

    # ADIOS INIT COMMUNICATION STREAM
    adios = adios_init_mpi(MPI.COMM_WORLD)
    comm_io = declare_io(adios, "OUTCOMMIO")

    comm_engine = open(comm_io, "reducer.bp", mode_write)

    # ready(comm_io, comm_engine, MPI.COMM_WORLD)

    # close(comm_engine)
    # comm_engine = open(comm_io, "reducer.bp", mode_readRandomAccess)

    # # LISTEN FOR CONFIGURATION ARRIVAL
    # if !listen(comm_io, comm_engine, MPI.COMM_WORLD)
    #     error("Listen timeout, $TRIALS trials.")
    # end

    # # Logger
    # if flags["--log"]
    #     logfile = open("./reducer-logs.log", mode_write)
    # end

    # # Get pipeline config
    # pipeline_vars = inquirePipelineConfigurationStructure(comm_io)
    # pipeline_config = getPipelineConfigurationStructure(comm_engine, pipeline_vars)

    # # ADIOS INIT INPUT STREAM
    # input_io = declare_io(adios, "INPUT_IO")

    # input_engine = open(input_io, pipeline_config[:engine], mode_readRandomAccess)

    # # ADIOS INIT OUTPUT STREAM
    # output_io = declare_io(adios, "OUTPUT_IO")

    # output_engine = open(output_io, pipeline_config[:engine], mode_readRandomAccess)

    # # Execute pipeline

    # # INPUT CHUNK
    # output = get_input(input_io, input_engine, pipeline_config[:var_name])
    # # PROCESS CHUNK
    # for i in 1:pipeline_vars[:n_layers]
    #     output = execute_layer(output, pipeline_config[:layer_info][i])
    # end
    # # OUTPUT CHUNK
    # submit_output(output_io, output_engine, output)

    close(comm_engine)
    MPI.Finalize()

end


function mainv2()
    # Initialization
    # Parallel stencil

    # MPI
    MPI.Init()

    rank = MPI.Comm_rank(MPI.COMM_WORLD)
    size = MPI.Comm_size(MPI.COMM_WORLD)


    # Flag parse
    for i in ARGS
        if i in keys(flags)
            # Switch flag
            flags[i] = !flags[i]
        end
    end

    # ADIOS INIT COMMUNICATION STREAM
    adios = adios_init_mpi(MPI.COMM_WORLD)
    comm_io = declare_io(adios, "OUTCOMMIO")

    comm_engine = open(comm_io, "reducer.bp", mode_write)

    # ready(comm_io, comm_engine, MPI.COMM_WORLD)

    # close(comm_engine)
    # comm_engine = open(comm_io, "reducer.bp", mode_readRandomAccess)

    # # LISTEN FOR CONFIGURATION ARRIVAL
    # if !listen(comm_io, comm_engine, MPI.COMM_WORLD)
    #     error("Listen timeout, $TRIALS trials.")
    # end

    # # Logger
    # if flags["--log"]
    #     logfile = open("./reducer-logs.log", mode_write)
    # end

    # # Get pipeline config
    # pipeline_vars = inquirePipelineConfigurationStructure(comm_io)
    # pipeline_config = getPipelineConfigurationStructure(comm_engine, pipeline_vars)

    # # ADIOS INIT INPUT STREAM
    # input_io = declare_io(adios, "INPUT_IO")

    # input_engine = open(input_io, pipeline_config[:engine], mode_readRandomAccess)

    # # ADIOS INIT OUTPUT STREAM
    # output_io = declare_io(adios, "OUTPUT_IO")

    # output_engine = open(output_io, pipeline_config[:engine], mode_readRandomAccess)

    # # Execute pipeline

    # # INPUT CHUNK
    # output = get_input(input_io, input_engine, pipeline_config[:var_name])
    # # PROCESS CHUNK
    # for i in 1:pipeline_vars[:n_layers]
    #     output = execute_layer(output, pipeline_config[:layer_info][i])
    # end
    # # OUTPUT CHUNK
    # submit_output(output_io, output_engine, output)

    close(comm_engine)
    MPI.Finalize()

end
