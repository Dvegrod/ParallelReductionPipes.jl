

# Code related to the actual execution of the pipeline

struct MPIConnection <: ParallelReductionPipes.AbstractConnection
    location :: String
    side     :: Bool
    timeout  :: Int
    comm     :: MPI.Comm
end


function connect(connection :: MPIConnection)

    side = joinpath(connection.location, ParallelReductionPipes.connectionGetSide(connection.side))

    ParallelReductionPipes.wait_for_existence(side, connection.timeout)

    adios = adios_init_mpi(connection.comm)
    comm_io = declare_io(adios, side * "IO")
    comm_engine = open(comm_io, side, mode_readRandomAccess)
    @debug "CONNECTION: connected to $side"
    return (adios,comm_io,comm_engine)
end


function setup(connection :: MPIConnection)

    side = joinpath(connection.location, ParallelReductionPipes.connectionGetSide(!connection.side))

    adios = adios_init_mpi(connection.comm)
    comm_io = declare_io(adios, side * "IOw")
    comm_engine = open(comm_io, side, mode_write)
    @debug "SETUP: connected to $side"
    return (adios,comm_io,comm_engine)
end

TRIALS = 2

function ready(connection :: MPIConnection, ready_val :: Int)
    if MPI.Comm_rank(connection.comm) == 0
        var = ParallelReductionPipes.metadata[:exec_ready]
        c = ParallelReductionPipes.Connection(connection.location, connection.side, connection.timeout)
        if ready_val == 1
            ParallelReductionPipes.declare_and_set(c, var, 1)
        else
            ParallelReductionPipes.declare_and_set(c, var, ready_val)
        end
        @warn "READY $ready_val"
    end
    MPI.Barrier(connection.comm)
end


function listen(connection :: MPIConnection, last_id :: Int)::Bool
    bool = false

    config_ready = ParallelReductionPipes._get(connection, :ready)

    @debug config_ready

    if config_ready !== nothing && config_ready > last_id
        bool = true
    end

    return bool
end
