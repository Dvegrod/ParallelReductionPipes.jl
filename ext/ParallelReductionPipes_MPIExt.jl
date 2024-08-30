"""
  The reducer runtime, CPU backend.
"""
module ParallelReductionPipes_MPIExt
#ParallelReductionPipes.MPIConnection = MPIConnection

using MPI
using ParallelStencil
using ADIOS2
using ParallelReductionPipes


@init_parallel_stencil(Threads, Float64, 3)

include("../src/execution/structs.jl")
include("../src/execution/local_domains.jl")
include("../src/execution/reduction_operations.jl")
include("../src/execution/communication.jl")

ParallelReductionPipes.connect(connection :: MPIConnection) = connect(connection)
ParallelReductionPipes.setup(connection :: MPIConnection) = setup(connection)

include("../src/execution/main.jl")


ParallelReductionPipes.main(backend :: Type{<: ParallelReductionPipes.CPUBackend}, connection_location = "") = main(connection_location)

end
