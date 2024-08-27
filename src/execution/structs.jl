
struct LocalLayer
    operator_id   ::Int
    operator_kind :: Int
    input_start   ::Tuple
    input_shape   ::Tuple
    output_start  ::Tuple
    output_shape  ::Tuple
    kernel_shape  ::Tuple

    out_buffer    :: Data.Array
end

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
    localized_layers :: Vector{LocalLayer}

    global_output_shape :: Tuple
end

input_shape(e::ExecutionInstance) = e.localized_layers[1].input_shape
input_start(e::ExecutionInstance) = e.localized_layers[1].input_start

output_shape(e::ExecutionInstance) = e.localized_layers[end].output_shape
output_start(e::ExecutionInstance) = e.localized_layers[end].output_start
