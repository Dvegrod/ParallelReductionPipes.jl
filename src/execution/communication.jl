
TRIALS = 2000

# Requires write mode
function ready(io :: ADIOS2.AIO, engine :: ADIOS2.Engine, comm :: MPI.Comm, ready_val :: Int)
    if MPI.Comm_rank(comm) == 2
        var = metadata[:exec_ready]
        if ready_val == 1
            declare_and_set(io, engine, var, 1)
        else
            _set(io, engine, :exec_ready, ready_val)
        end
        @warn "READY $ready_val"
    end
    MPI.Barrier(comm)
end


# Requires read mode
function listen(io::ADIOS2.AIO, engine::ADIOS2.Engine, comm::MPI.Comm, last_id :: Int)::Bool
    bool = false

    if MPI.Comm_rank(comm) == 0
        for _ in 1:TRIALS
            config_ready = _get(io, engine, :ready)

            @show config_ready

            if config_ready !== nothing && config_ready > last_id
                bool = true
                break
            end

            @warn "LISTENING"
            sleep(1)
        end
    end
    bool = MPI.Bcast(bool, 0, comm)
    return bool
end
