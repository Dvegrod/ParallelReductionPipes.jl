
"""Saves the information about a pipe input that is the ADIOS2 parameters"""
struct Input
    var_name        :: AbstractString
    engine_name     :: AbstractString
    config_file     :: AbstractString
    var_shape       :: Vector{Int}
    var_type        :: Type
end

"""As known as window, this saves window dimensions"""
struct Kernel
    dims            :: Vector{Int}
    trim            :: Bool  # Y/N? Trims border areas that do not fit an entire kernel space TODO
end

"""Saves the registration of an operator (just its I/O not the actual function)"""
struct Operator
    name            :: String
    in_type         :: Type
    out_type        :: Type
    id              :: Int32
    kind            :: Int32
    symbol          :: Symbol
end

"""Combines a operator and a kernel to make a layer, also registers its output properties"""
struct Layer
    kernel             :: Kernel
    operator           :: Operator
    output_shape       :: Vector{Int}
    remainder          :: Vector{Int} # Used when the input is not divisible by the kernel, always same length as input shape
end
_shape(layer::Layer) = Tuple(layer.output_shape)

"""This is a blueprint for a pipe, it can be launched to the runtime"""
struct PipelineBuilder
    input              :: Input
    layers             :: Vector{Layer}
    process_space_size :: Int  # MPI
end

Pipe = PipelineBuilder

"""A var field used to define valid attributes to be sent through the control channel"""
struct Var
    name :: String
    type :: Type
    shape:: Vector{Int}
end

"""Control channel: control flags"""
metadata = Dict([
    :ready      => Var("config_ready", Int, []),
    :exec_ready => Var("reducer_ready", Int, []),
    :stop       => Var("stop"        , Int, []),
    :debug      => Var("debug"       , Int, []),
    :custom     => Var("custom_module", String, []),
])

# Debug:
#    0: normal execution
# Reducer ready (runtime writes here):
#    1: runtime is listening for pipeline configuration
#    2: runtime got configuration, pipeline start
# Config ready (launcher writes here):
#    1: launcher has posted the pipeline configuration

"""Control channel: pipe serialization"""
var_repository = Dict([
    :engine       => Var("input_engine", String, []),
    :var_name     => Var("input_var_name", String, []),
    :uses_config  => Var("uses_config", Int, []),
    :config       => Var("adios_config", String, []),
    :var_shape    => Var("input_var_shape", Int, [3]),
    :var_type     => Var("input_var_type", Int, []),
    :n_layers     => Var("number_of_layers"  , Int   , []),
    :layer_config => Var("layer_config_table", Int   , [32, 8])
])
