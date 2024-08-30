"""
  Represents a layer in a reducer process. It holds the buffer where its output local domain is saved.
"""
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

"""
  Represents an instance of a reduction pipe execution.
  It registers information about the I/O streams, the configuration of the pipe and the collection of layers with their memory buffers.
"""
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

"""
  Given a pipe get the LOCAL input shape
"""
input_shape(e::ExecutionInstance) = e.localized_layers[1].input_shape
"""
  Given a pipe get the LOCAL input start (at which global index the local domain starts)
"""
input_start(e::ExecutionInstance) = e.localized_layers[1].input_start

"""
  Given a pipe get the LOCAL output shape
"""
output_shape(e::ExecutionInstance) = e.localized_layers[end].output_shape
"""
  Given a pipe get the LOCAL output start (at which global index the local domain starts)
"""
output_start(e::ExecutionInstance) = e.localized_layers[end].output_start
