



struct Input
    var_name        :: AbstractString
    engine_name     :: AbstractString
    config_file     :: AbstractString
    var_shape       :: Vector{Int}
    var_type        :: Type
end

struct Kernel
    dims            :: Vector{Int}
    trim            :: Bool  # Y/N? Trims border areas that do not fit an entire kernel space TODO
end

struct Operator
    name            :: String
    in_type         :: Type
    out_type        :: Type
    id              :: Int32
    symbol          :: Symbol
end

struct Layer
    kernel             :: Kernel
    operator           :: Operator
    output_shape       :: Vector{Int}
    remainder          :: Vector{Int} # Used when the input is not divisible by the kernel, always same length as input shape
end
_shape(layer::Layer) = Tuple(layer.output_shape)

struct LocalLayer
    operator_id ::Int
    input_start ::Tuple
    input_shape ::Tuple
    output_start::Tuple
    output_shape::Tuple
    kernel_shape::Tuple

    out_buffer :: Data.Array
end

struct PipelineBuilder
    input              :: Input
    layers             :: Vector{Layer}
    process_space_size :: Int  # MPI
end

struct Var
    name :: String
    type :: Type
    shape:: Vector{Int}
end

struct Connection
    adios       :: ADIOS2.Adios
    io_read     :: ADIOS2.AIO
    io_write    :: ADIOS2.AIO
    engine_read :: ADIOS2.Engine
    engine_write :: ADIOS2.Engine
end

metadata = Dict([
    :ready      => Var("config_ready", Int, []),
    :exec_ready => Var("reducer_ready", Int, []),
    :stop       => Var("stop"        , Int, []),
    :debug      => Var("debug"       , Int, []),
])

# Debug:
#    0: normal execution
#    1: ready handshake between launcher and execution and exit execution (when reducer_ready = 2)
# Reducer ready (runtime writes here):
#    1: runtime is listening for pipeline configuration
#    2: runtime got configuration, pipeline start
# Config ready (launcher writes here):
#    1: launcher has posted the pipeline configuration


var_repository = Dict([
    :engine       => Var("input_engine", String, []),
    :var_name     => Var("input_var_name", String, []),
    :uses_config  => Var("uses_config", Int, []),
    :config       => Var("adios_config", String, []),
    :var_shape    => Var("input_var_shape", Int, [3]),
    :var_type     => Var("input_var_type", Int, []),
    :n_layers     => Var("number_of_layers"  , Int   , []),
    :layer_config => Var("layer_config_table", Int   , [32, 7])
])
