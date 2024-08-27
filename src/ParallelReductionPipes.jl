module ParallelReductionPipes

using ADIOS2
using MacroTools

ALL::Int = -1

slice_mode = :v1

supported_types = Type[
    Float64
]

# Code related to configuring and deploying a reduction pipeline
include("blueprinting/structs.jl")

include("shared.jl")
include("blueprinting/input.jl")
include("blueprinting/kernels.jl")
include("blueprinting/operators.jl")
include("blueprinting/custom.jl")
include("blueprinting/reduction.jl")
include("blueprinting/build.jl")


abstract type AbstractBackend end
struct CUDABackend <: AbstractBackend end
struct CPUBackend <: AbstractBackend end

main(backend :: Type{<: AbstractBackend}) = error("Invalid, or disabled backend, check dependencies ($backend)")


end
