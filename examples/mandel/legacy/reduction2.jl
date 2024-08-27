
using ParallelStencil: @parallel_indices_cuda, init_parallel_stencil, @parallel_threads
using MPI: MPI_File
using ADIOS2
using MPI
using Plots
using ParallelStencil

@init_parallel_stencil(Threads, Float64, 2);

# ORDER -> (X,Y)

MPI.Init()

function slicer(rank :: Int, side_size :: Int, dims :: Union{Tuple,Vector})
    slice_side_x = div(side_size, dims[1])
    slice_side_y = div(side_size, dims[2])
    rem_x = rem(side_size, dims[1])
    rem_y = rem(side_size, dims[2])
    start = (rem(rank, dims[1]) * slice_side_x, div(rank, dims[1]) * slice_side_y)
    size = (slice_side_x, slice_side_y)
    end_x = start[1] + size[1]
    end_y = start[2] + size[2]

    return (start, size, (end_x, end_y))
end

# Setup local view
function get_data_chunk(rank, dims, side_size)
    # Init adios
    adios = adios_init_mpi(MPI.COMM_WORLD)
    io = declare_io(adios, "io")
    engine = open(io, "buffer.bp", mode_readRandomAccess)
    var = inquire_variable(io, "mandel")
    # Specify slice dimension
    slice_side_x = div(side_size, dims[1])
    slice_side_y = div(side_size, dims[2])
    start = (rem(rank, dims[1]) * slice_side_x, div(rank, dims[1]) * slice_side_y)
    size = (slice_side_x, slice_side_y)
    @show rank, start, size
    # TRANSPOSITION WARNING
    set_selection(var, (start[1], start[2]), (size[1], size[2]))

    mandel = Array{Float64}(undef, slice_side_x, slice_side_y)
    get(engine, var, mandel)
    perform_gets(engine)
    close(engine)
    return mandel
end

# Reduction
@parallel_indices (ix, iy) function reduction_average!(Big::Array{Float64}, Small::Array{Float64}, ker::Vector{Int})
    factor = ker
    lowx = 1 + (ix - 1) * ker[1]
    lowy = 1 + (iy - 1) * ker[2]
    highx = factor[1] + (ix - 1) * ker[1]
    highy = factor[2] + (iy - 1) * ker[2]

    Small[ix, iy] = reduce(+, Big[lowx:highx, lowy:highy]) / prod(ker)
    return
end
# Assembly

function array_fusion(comm :: MPI.Comm, local_array, dims)
    if MPI.Comm_rank(comm) == 0
        data = Array{Float64}(undef, OUT_SIZE_B, OUT_SIZE_B)
        for i in (0 + 1):(MPI.Comm_size(comm) - 1)
            position = slicer(i, OUT_SIZE_B, dims)
            @warn "Fusing $i: $position"
            buffer= MPI.Buffer(view(data, (position[1][1]+1):position[3][1], (position[1][2]+1):position[3][2]))
            MPI.Recv!(buffer, comm; source=i)
        end

        # Self
        p = slicer(0, OUT_SIZE_B, dims)
        @warn "Local: $p"
        data[(p[1][1]+1):(p[3][1]),(p[1][2] + 1):(p[3][2])] .= local_array

        return data
    else
        buffer = MPI.Buffer(local_array)
        MPI.Send(buffer,  comm; dest=0)

        return nothing
    end
end

# global
SIDE_SIZE = 1000
REDUCTION = 10
OUT_SIZE_B = div(SIDE_SIZE, REDUCTION)

function main()
    # MPI
    rank = MPI.Comm_rank(MPI.COMM_WORLD)
    size = MPI.Comm_size(MPI.COMM_WORLD)

    if rank == 0
        @show size
    end
    MPI.Barrier(MPI.COMM_WORLD)

    dims = MPI.Dims_create(size, (0, 0))

    # Use ADIOS to get a simulation chunk

    c = get_data_chunk(rank, dims, SIDE_SIZE)
    c_size = Base.size(c)

    OUT_SIZE_A = div.(c_size, REDUCTION)
    @show OUT_SIZE_A
    # Begin reduction
    reduced_c = Array{Float64}(undef, OUT_SIZE_A[1], OUT_SIZE_A[2])

    # Kernel that reduces from original to outsize A
    ker = [REDUCTION for _ in 1:2]

    @parallel (1:OUT_SIZE_A[1], 1:OUT_SIZE_A[2]) reduction_average!(c, reduced_c, ker)

    # Array fusion
    data = array_fusion(MPI.COMM_WORLD, reduced_c, dims)
    if (rank == 0)
        @show Base.size(data)
        spy(data)
        savefig("out.png")
    end

end


main()
