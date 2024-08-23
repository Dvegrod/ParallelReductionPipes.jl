module reducer_MPIExt
   using reducer, MPI

export MPIConnection

   # Code related to the actual execution of the pipeline

   struct MPIConnection <: reducer.AbstractConnection
       location :: String
       side     :: Bool
       timeout  :: Int
       comm     :: MPI.Comm
   end


function connect(connection :: MPIConnection)

    side = joinpath(connection.location, reducer.connectionGetSide(connection.side))

    reducer.wait_for_existence(side, connection.timeout)

    adios = adios_init_mpi(connection.comm)
    comm_io = declare_io(adios, side * "IO")
    comm_engine = open(comm_io, side, mode_readRandomAccess)
    @info "CONNECTION: connected to $side"
    return (adios,comm_io,comm_engine)
end


function setup(connection :: MPIConnection)

    side = joinpath(connection.location, reducer.connectionGetSide(!connection.side))

    adios = adios_init_mpi(connection.comm)
    comm_io = declare_io(adios, side * "IOw")
    comm_engine = open(comm_io, side, mode_write)
    @info "SETUP: connected to $side"
    return (adios,comm_io,comm_engine)
end

#reducer.MPIConnection = MPIConnection

reducer.connect(connection :: MPIConnection) = connect(connection)
reducer.setup(connection :: MPIConnection) = setup(connection)

using MPI
using ParallelStencil
using ADIOS2

@init_parallel_stencil(Threads, Float64, 3)

include("../src/execution/structs.jl")
include("../src/execution/local_domains.jl")
include("../src/execution/reduction_operations.jl")
include("../src/execution/communication.jl")
include("../src/execution/main.jl")

reducer.main() = main()

end
