

if ARGS[1] == "CPU"
    using MPI
    using ParallelReductionPipes

    @info pwd()
    ParallelReductionPipes.main(ParallelReductionPipes.CPUBackend)
else
    using CUDA
    using MPI

    using ParallelReductionPipes

    ParallelReductionPipes.main(ParallelReductionPipes.CUDABackend)
end
