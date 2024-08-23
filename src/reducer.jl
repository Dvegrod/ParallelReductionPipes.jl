module reducer

abstract type AbstractBackend end
struct CPUBackend <: AbstractBackend end
struct CUDABackend <: AbstractBackend end

backend = CPUBackend

using ADIOS2

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


main(n :: Nothing) = error("MPI is needed for the reducer runtime, use MPI to enable the extension")

end
