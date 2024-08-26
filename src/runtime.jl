

if ARGS[1] == "CPU"
    using MPI
    using reducer


    reducer.main(reducer.CPUBackend)
else
    using CUDA
    using MPI

    using reducer

    reducer.main(reducer.CUDABackend)
end
