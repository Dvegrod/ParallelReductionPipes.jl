"""
  The reducer runtime, GPU backend.
"""
module ParallelReductionPipes_CUDAExt

using ParallelReductionPipes
using MPI
using ParallelStencil
using ADIOS2
import CUDA

@init_parallel_stencil(CUDA, Float64, 3)


include("../src/execution/structs.jl")
include("../src/execution/local_domains.jl")
include("../src/execution/reduction_operations.jl")
include("../src/execution/communication.jl")

ParallelReductionPipes.connect(connection::MPIConnection) = connect(connection)
ParallelReductionPipes.setup(connection::MPIConnection) = setup(connection)

include("../src/execution/main.jl")


ParallelReductionPipes.main(_::Type{<:ParallelReductionPipes.CUDABackend}, connection_location="") = main(connection_location)
end
