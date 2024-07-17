module reducer
export PipelineBuilder, reduction, input, kernel

using MPI
using ADIOS2
using ImplicitGlobalGrid
using ParallelStencil

@init_parallel_stencil(Threads, Float64, 3)

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
include("blueprinting/reduction.jl")
include("blueprinting/build.jl")

# Code related to the actual execution of the pipeline
include("execution/inflate.jl")
include("execution/local_domains.jl")
include("execution/reduction_operations.jl")
include("execution/main.jl")

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

end # module reducer
