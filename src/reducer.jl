module reducer

using ImplicitGlobalGrid
using ParallelStencil

ALL :: Int = -1

supported_types = Type[
    Float64
]

# Code related to configuring and deploying a reduction pipeline
include("blueprinting/structs.jl")
include("blueprinting/input.jl")
include("blueprinting/kernels.jl")
include("blueprinting/operators.jl")
include("blueprinting/reduction.jl")
include("blueprinting/build.jl")

# Code related to the actual execution of the pipeline
include("execution/local_domains.jl")
include("execution/reduction_operations.jl")


end # module reducer
