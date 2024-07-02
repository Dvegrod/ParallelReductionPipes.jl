using MPI: MPI_File
using ADIOS2
using MPI

"""
  This app computes the mandelbrot set in parallel using MPI. Its used as a test app for trying ADIOS2

  Execution:
    mpiexec -n [# procs] julia test_generator.jl [side length of the square domain] [max iters on each pixel]

  There's n processes:
    x1 Master process: executes master(), assigns pieces of the domain on demand to the workers until the domain is complete
    x(n-1) Workers: receive tasks of computing the mandelbrot set on horizontal tranches of the domain and write them.
"""


"""
  Computes mandelbrot on a pixel
"""
function mandel_iter_calc(c :: ComplexF64, max_iter :: Int)
    z = c
    for n in 1:max_iter
        if abs(z) > 2
            return n
        end
        z = z * z + c
    end

    return max_iter
end

"""
  Used just to get a more desirable result image for the example, it does not have any particular semantics
"""
function convenient_function(x :: Int)::Float64
    return 1 / Float64(x)
end

"""
  Transfoms grid coordinates into number space coordinates given a domain specification
"""
function grid_transform_setup(side_dim :: Int,
                              limx_min :: Float64, limx_max :: Float64,
                              limy_min ::Float64, limy_max :: Float64)

    return (i, j) -> ComplexF64(((i - 1) / (side_dim - 1) * (limx_max - limx_min) + limx_min),
                                ((j - 1) / (side_dim - 1) * (limy_max - limy_min) + limy_min))
end

"""
  Dispatches tasks
"""
function master(comm :: MPI.Comm, size::Int, tranche_width :: Int, side_dim :: Int)
    # Determine task bounds
    taskmap = Int.([i for i in 1:ceil(side_dim/tranche_width)])
    tasklims = [((i - 1) * tranche_width + 1,
                 min(side_dim - (i - 1) * tranche_width - 1, tranche_width)) for i in taskmap]

    completed = 0
    buffer = [0, 0]

    # Dispatch tasks on demand
    while completed < length(taskmap)
        @warn "[i] Completed $completed tasks... $((tasklims[completed+1][1] -1)/side_dim * 100)%"
        MPI.Recv!(buffer, MPI.ANY_SOURCE, MPI.ANY_TAG, comm, nothing)
        dest = buffer[1]
        buffer[1] = tasklims[completed+1][1]
        buffer[2] = tasklims[completed+1][2]
        MPI.Send(buffer, comm; dest=dest)
        completed +=1
    end

    # Communicate finalisation
    for i in 0:(size-1)
        buffer = [-1,-1]
        MPI.Send(buffer, comm; dest=i)
    end
    @warn "ALL SENT"
end

"""
  Computes tasks
"""
function worker(comm :: MPI.Comm, rank :: Int, engine::ADIOS2.Engine, var :: ADIOS2.Variable,
                transform :: Function, side_dim :: Int, max_iter :: Int, result_buffer :: Array{Float64})
    taskbounds = [0,0]
    while true
        # Request task
        taskbounds[1] = rank
        MPI.Send(taskbounds, comm; dest=0)
        # Receive task if theres left
        MPI.Recv!(taskbounds, 0, MPI.ANY_TAG, comm, nothing)
        if taskbounds[1] <= 0
            @warn "Worker $rank received finalisation signal"
            break
        end

        # Execute task
        for row in taskbounds[1]:(taskbounds[1]+taskbounds[2] - 1)
            for col in 1:side_dim
                result_buffer[row - taskbounds[1] + 1, col] = convenient_function(
                    mandel_iter_calc(
                        transform(row, col), max_iter)
                )
            end
        end

        # Write
        @show ndims(var)
        set_selection(var, (taskbounds[1], 0), (taskbounds[2], side_dim))
        put!(engine, var, result_buffer, mode_sync)
        result_buffer = result_buffer .* 0.
    end
end



function main()
    # MPI Setup
    MPI.Init()

    comm = MPI.COMM_WORLD
    rank = MPI.Comm_rank(comm)
    size = MPI.Comm_size(comm)

    # Domain setup
    side_dim = parse(Int, ARGS[1])
    max_iter = parse(Int, ARGS[2])

    # Vertical division of domain max width
    tranche_width = 100
    # Memory buffer to store computation results of a task
    mandel_tranche = zeros(Float64, tranche_width, side_dim)

    # Setup transform
    transform = grid_transform_setup(side_dim, -2.0, 1.0, -1.5, 1.5)

    # Setup ADIOS
    adios = adios_init_mpi("adios_config.xml", comm)
    io = declare_io(adios, "IO")
    engine = open(io, "buffer.bp", mode_write)

    # ADIOS Var def
    side_dim_var = define_variable(io, "side_dim", side_dim)

    mandel_global_var = define_variable(io, "mandel", Float64, (side_dim, side_dim), (0,0), (tranche_width, side_dim); constant_dims=false)

    begin_step(engine)
    # Task array
    # MASTER
    if rank == 0
        put!(engine, side_dim_var, side_dim)
        if size < 2
            perform_puts!(engine)
            close(engine)
            error("No workers, just master (nprocs < 2)")
            exit(-1)
        end
        master(comm, size, tranche_width, side_dim)
    else # WORKERS
        worker(comm, rank, engine, mandel_global_var, transform, side_dim, max_iter, mandel_tranche)
    end
    end_step(engine)



    @warn "Barrier: $rank"
    MPI.Barrier(comm)
    perform_puts!(engine)
    MPI.Barrier(comm)
    @warn "Barrier: $rank"
    close(engine)
end


main()
