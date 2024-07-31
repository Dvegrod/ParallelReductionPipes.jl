
struct ExecutionInstance
    # Execution instance id
    id            ::Int

    # MPI
    rank          ::Int
    size          ::Int
    dims          ::Tuple

    # IN and OUT
    input_IO      ::ADIOS2.AIO
    output_IO     ::ADIOS2.AIO
    input_engine  ::ADIOS2.Engine
    output_engine ::ADIOS2.Engine

    # Parameters to setup reduction pipeline
    # Keys defined at: ../structs.jl
    pipeline_config :: Dict{Symbol, Any}

    # Local version of the layers with chunk based sizes
    localized_layers :: LocalLayer[]

    global_output_shape :: Tuple
end

input_shape(e::ExecutionInstance) = e.localized_layers[1].input_shape
input_start(e::ExecutionInstance) = e.localized_layers[1].input_start

output_shape(e::ExecutionInstance) = e.localized_layers[end].output_shape
output_start(e::ExecutionInstance) = e.localized_layers[end].output_start


flags = Dict{String,Bool}([
   "--log" => true
])

global logfile = undef


function get_input(io :: ADIOS2.AIO, engine::ADIOS2.Engine,
                   var_name :: String, start :: Tuple, size :: Tuple) :: LocalDomain

    y = inquire_variable(io, var_name)

    if isnothing(y)
        e = ArgumentError("Invalid value, it is not available on the specified IO")
        throw(e)
    end

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
        if i > 1
            push!(t, i)
        else
            # push!(t, 1)
        end
    end

    return Tuple(t)
end

function execute_layer(input :: LocalDomain, config :: LocalLayer) :: LocalDomain

    # TODO Save on allocation time
    output = transform(input, config.kernel_shape, Array{Float64}(undef, config.output_shape...))

    @show output.size

    # TODO
    @parallel (1:output.size[1], 1:output.size[2], 1:output.size[3]) reduction_functions[config.operator_id](input.data, output.data)
    #in_shape, ker_shape)
    return output
end


function submit_output(io::ADIOS2.AIO, engine::ADIOS2.Engine, input::LocalDomain, global_shape)

    define_variable(io, "out", Float64, global_shape, input.start, input.size)

    y = inquire_variable(io, "out")

    # TODO COLLAPSE

    if isnothing(y)
        e = ArgumentError("Out var has not been defined yet")
        throw(e)
    end

    @show input.start, input.size, global_shape

    put!(engine, y, input.data)
    perform_puts!(engine)
end


function reduction_execution(e :: ExecutionInstance)
    # STEP LOOP
    while begin_step(e.input_engine) == step_status_ok

        begin_step(e.output_engine)
        @warn "STEP"
        # INPUT CHUNK
        output = get_input(e.input_IO, e.input_engine,
                           e.pipeline_config[:var_name],
                           input_shape(e), input_start(e))

        # PROCESS CHUNK
        for i in 1:e.pipeline_config[:n_layers]
            output = execute_layer(output, e.localized_layers[i])
        end

        # OUTPUT CHUNK TODO SIMPLIFY
        submit_output(e.output_IO, e.output_engine, output, e.global_output_shape)

        end_step(e.input_engine)
        end_step(e.output_engine)
    end
end

function cleanup_instance(e :: ExecutionInstance)
    close(e.input_engine)
    close(e.output_engine)
    GC.gc()
end


# THERE ARE 4 ADIOS STREAMS GOING ON
#   A. CONTROL PLANE (BP5) (called comm in variable names)
#      1. Runtime writes (i.e. to send status to listeners)
#      2. Runtime reads (i.e to get config parameters)
#   B. DATA PLANE (BP5 or SST)
#      1. Input data
#      2. Output data

function main()
    # Initialization
    # MPI
    MPI.Init()

    rank = MPI.Comm_rank(MPI.COMM_WORLD)
    size = MPI.Comm_size(MPI.COMM_WORLD)

    dims = MPI.Dims_create(size, [0,0,1])

    # Flag parse
    for i in ARGS
        if i in keys(flags)
            # Switch flag
            flags[i] = !flags[i]
        end
    end

    # ADIOS INIT COMMUNICATION STREAM
    adios = adios_init_mpi("adios_config.xml", MPI.COMM_WORLD)

    comm_io = declare_io(adios, "OUTCOMMIO_WRITE")

    comm_engine = open(comm_io, "reducer-r.bp", mode_write)

    ready(comm_io, comm_engine, MPI.COMM_WORLD, 1)

    comm_io2 = declare_io(adios, "OUTCOMMIO_READ")

    # WAIT FOR reducer-l.bp existence
    # TODO

    # # Logger
    # if flags["--log"]
    #     logfile = open("./reducer-logs.log", mode_write)
    # end

    comm_engine2 = open(comm_io2, "reducer-l.bp", mode_readRandomAccess)

    last_id = 0
    for _ in 1:1
        # LISTEN FOR CONFIGURATION ARRIVAL
        if !listen(comm_io2, comm_engine2, MPI.COMM_WORLD, last_id)
            error("Listen timeout, $TRIALS trials.")
        end
        last_id = _get(comm_io2, comm_engine2, :ready)

        # Get pipeline config
        pipeline_vars = inquirePipelineConfigurationStructure(comm_io2)
        pipeline_config = getPipelineConfigurationStructure(comm_engine2, pipeline_vars)

        ready(comm_io, comm_engine, MPI.COMM_WORLD, 2)

        # ADIOS INIT INPUT STREAM
        input_io = declare_io(adios, "INPUT_IO")

        input_engine = open(input_io, "/scratch/snx3000/dvegarod/sst-file", mode_read)#pipeline_config[:engine], mode_read)

        # ADIOS INIT OUTPUT STREAM
        output_io = declare_io(adios, "OUTPUT_IO")

        output_engine = open(output_io, "reducer-o.bp", mode_write)

        @warn "Reached pipeline beginning $input_engine"

        # Calculate local pipeline shapes
        layers = calculateShape(pipeline_config[:layer_config], Tuple(pipeline_config[:var_shape]), pipeline_config[:n_layers], rank, dims)

        exec_instance = ExecutionInstance(
            last_id,
            rank,
            size,
            dims,
            input_io,
            output_io,
            input_engine,
            output_engine,
            pipeline_config,
            layers,
            Tuple(pipeline_config[:layer_config][pipeline_config[:n_layers], 5:7])
        )

        reduction_execution(exec_instance)
        cleanup_instance(exec_instance)

        ready(comm_io, comm_engine, MPI.COMM_WORLD, 1)
    end

    close(comm_engine)
    close(comm_engine2)
    MPI.Finalize()

end

