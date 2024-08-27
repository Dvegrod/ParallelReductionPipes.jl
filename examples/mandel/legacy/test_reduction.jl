using ParallelStencil: @parallel_indices_cuda, init_parallel_stencil
using MPI: MPI_File
using ADIOS2
using MPI
using Plots
using ParallelStencil


@init_parallel_stencil(Threads, Float64, 2);

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

function grid_process_setup(rank::Int, size::Int, limx_min, limy_min, limx_max, limy_max)
    row_len = sqrt(size)
    row = div(rank, row_len)
    col = rem(rank, row_len)

    space_x_len = (limx_max - limx_min) / row_len
    space_y_len = (limy_max - limy_min) / row_len
    startx, starty = (limx_min + space_x_len * row, limy_min + col * space_y_len)

    return (startx, startx + space_x_len, starty, starty + space_y_len)
end


"""
  Computes a section of the set
"""
@parallel_indices (ix, iy) function worker!(
                transform :: Function, max_iter :: Int, result_buffer :: Array{Float64})
    # Execute task
    result_buffer[ix, iy] = convenient_function(
        mandel_iter_calc(
            transform(ix, iy), max_iter)
    )
    return
end



function main()
    # MPI Setup
    MPI.Init()


    comm = MPI.COMM_WORLD
    rank = MPI.Comm_rank(comm)
    size = MPI.Comm_size(comm)

    # Domain setup
    side_dim = parse(Int, ARGS[1])
    local_side_dim = div(side_dim,Int(sqrt(size)))

    max_iter = parse(Int, ARGS[2])
    vis_side_dim = parse(Int, ARGS[3])
    local_vis_side_dim = vis_side_dim / sqrt(size)

    # Buffer setup
    buffer = Float64[0. for _ in 1:side_dim, _ in 1:side_dim]

    # Setup transform
    #transform = grid_transform_setup(side_dim, grid_process_setup(rank, size, -2.0, -1.5, 1.5, 1.5)...)
    transform = grid_transform_setup(side_dim, -2.0, 1.5, -1.5, 1.5)

    # Setup ADIOS
    adios = adios_init_mpi(comm)
    io = declare_io(adios, "IO")
    engine = open(io, "buffer.bp", mode_write)

    # Declare var
    i = grid_process_setup(rank, size, -2.0, -1.5, 1.5, 1.5)
    matrix = define_variable(io, "mandel", Float64, (side_dim, side_dim), (i[1], i[3]), (i[2], i[4]))

    @warn "Process $rank: doing $i"

    # Compute mandelbrot
    @parallel (1:local_side_dim, 1:local_side_dim) worker!(transform, max_iter, buffer)

    spy(buffer)
    savefig("out$rank.png")

    # Save computation
    put!(engine, matrix, buffer)
    perform_puts!(engine)

    MPI.Barrier(comm)
    @warn "Barrier: $rank"
    close(engine)
end


main()
