
using Pkg

if ARGS[1] == "CPU"
    Pkg.add("MPI")

    using MPI
    using ParallelReductionPipes

    @info pwd()
    ParallelReductionPipes.main(ParallelReductionPipes.CPUBackend)
else
    Pkg.add("MPI")
    Pkg.add("CUDA")
    using CUDA
    using MPI

    using ParallelReductionPipes

    ParallelReductionPipes.main(ParallelReductionPipes.CUDABackend)
end
