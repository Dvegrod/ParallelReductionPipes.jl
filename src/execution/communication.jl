

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
    @info "CONNECTION: connected to $side $(stacktrace())"
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

TRIALS = 2

function ready(connection :: MPIConnection, ready_val :: Int)
    if MPI.Comm_rank(connection.comm) == 0
        var = reducer.metadata[:exec_ready]
        c = reducer.Connection(connection.location, connection.side, connection.timeout)
        if ready_val == 1
            reducer.declare_and_set(c, var, 1)
        else
            reducer.declare_and_set(c, var, ready_val)
        end
        @warn "READY $ready_val"
    end
    MPI.Barrier(connection.comm)
end


function listen(connection :: MPIConnection, last_id :: Int)::Bool
    bool = false

    # if MPI.Comm_rank(connection.comm) == 0
    #     for _ in 1:TRIALS
    #         config_ready = reducer._get(connection, :ready)

    #         @show config_ready

    #         if config_ready !== nothing && config_ready > last_id
    #             bool = true
    #             break
    #         end

    #         @warn "LISTENING"
    #         sleep(1)
    #     end
    # end
    # bool = MPI.Bcast(bool, 0, connection.comm)
    config_ready = reducer._get(connection, :ready)

    @show config_ready

    if config_ready !== nothing && config_ready > last_id
        bool = true
    end

    return bool
end
