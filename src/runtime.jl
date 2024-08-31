

if ARGS[1] == "CPU"
    using MPI
    using ParallelStencil
    using ParallelReductionPipes

    @info pwd()
    ParallelReductionPipes.main(ParallelReductionPipes.CPUBackend)
else
    using CUDA
    using MPI
    using ParallelStencil

    using ParallelReductionPipes

    ParallelReductionPipes.main(ParallelReductionPipes.CUDABackend)
end
