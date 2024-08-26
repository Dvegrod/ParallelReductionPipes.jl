module reducer_CUDAExt

using reducer
using MPI
using ParallelStencil
using ADIOS2
import CUDA

@init_parallel_stencil(CUDA, Float64, 3)


include("../src/execution/structs.jl")
include("../src/execution/local_domains.jl")
include("../src/execution/reduction_operations.jl")
include("../src/execution/communication.jl")

reducer.connect(connection :: MPIConnection) = connect(connection)
reducer.setup(connection :: MPIConnection) = setup(connection)

include("../src/execution/main.jl")


reducer.main(backend :: Type{<: reducer.CUDABackend}) = main()
end
