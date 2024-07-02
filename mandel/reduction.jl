
using ParallelStencil: @parallel_indices_cuda, init_parallel_stencil
using MPI: MPI_File
using ADIOS2
using MPI
using Plots
using ParallelStencil

@init_parallel_stencil(Threads, Float64, 2);


MPI.Init()

# Setup local view
function get_data_chunk(rank, dims, side_size)
    # Init adios
    adios = adios_init_mpi(MPI.COMM_WORLD)
    io = declare_io(adios, "io")
    @warn "cazzo"
    engine = open(io, "buffer.bp", mode_readRandomAccess)
    
    var = inquire_variable(io, "mandel")
    @show var
    # Specify slice dimensions
    slice_side_x = div(side_size, dims[0])
    slice_side_y = div(side_size, dims[1])
    start = (div(rank, dims[0]) * slice_side_x, rem(rank, dims[0]) * slice_side_y)
    size = (slice_side_x, slice_side_y)
    set_selection(var, start, size)

    mandel = Ref{Matrix}
    get(engine, var, mandel)
    perform_gets(engine)
    return mandel
end
# Reduction
# Assembly

rank = MPI.Comm_rank(MPI.COMM_WORLD)
size = MPI.Comm_size(MPI.COMM_WORLD)

if rank == 0
    dims = MPI.Dims_create(size, (0,0))

    c = get_data_chunk(0, dims, 1000)
    @show c
end
