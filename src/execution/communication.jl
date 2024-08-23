
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
