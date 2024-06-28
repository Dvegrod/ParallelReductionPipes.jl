
struct Input
    var_name        :: AbstractString
    engine_name     :: AbstractString
    config_file     :: AbstractString
    var_shape       :: Vector{Int}
    var_type        :: Type
end

struct Kernel
    dims            :: Vector{Int}
    collapse        :: Bool  # Reduces dimensions if they get reduce to one value?
    trim            :: Bool  # Trims border areas that do not fit an entire kernel space
end

struct Operator
    name            :: String
    in_type         :: Type
    out_type        :: Type
    table_id        :: Int
end

struct Layer
    kernel             :: Kernel
    operator           :: Operator
    output_shape       :: Vector{Int}
    type               :: Type
    remainder          ::Vector{Int} # Used when the input is not divisible by the kernel, always same length as input shape
end

struct PipelineBuilder
    input              :: Input
    layers             :: Vector{Layer}
    process_space_size :: Int  # MPI
end

