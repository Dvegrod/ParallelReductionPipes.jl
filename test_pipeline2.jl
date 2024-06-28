
using Base: SmallSigned
using ParallelStencil: @parallel_indices_cuda
using Plots
using ImplicitGlobalGrid: has_neighbor

const USE_GPU = false
using ImplicitGlobalGrid
import MPI
using ParallelStencil

@static if USE_GPU
    @init_parallel_stencil(CUDA, Float64, 2);
else
    @init_parallel_stencil(Threads, Float64, 2);
end


@parallel_indices (ix, iy) function reduction_average!(Big::Array{Float64}, Small::Array{Float64}, ker :: Vector{Int})
    factor = ker
    lowx = 1 + (ix - 1) * ker[1]
    lowy = 1 + (iy - 1) * ker[2]
    highx = factor[1] + (ix - 1) * ker[1]
    highy = factor[2] + (iy - 1) * ker[2]

    if requires_halo
        @show [lowx:highx, lowy:highy]
        @show reduce(+, Big[lowx:highx, lowy:highy]) / prod(ker)
    end

    Small[ix, iy] = reduce(+, Big[lowx:highx, lowy:highy]) / prod(ker)
    return
end


function calculate_sidx()
    ix = (1*has_neighbor(1, 1)+1):(-1*(has_neighbor(2, 1) && !requires_halo || uneven && !has_neighbor(2,1))+nx2)
    iy = (1*has_neighbor(1, 2)+1):(-1*(has_neighbor(2, 2) && !requires_halo || uneven && !has_neighbor(2,2))+ny2)
    return (ix, iy)
end

function compute_overlap(kernel_len :: Int)
    
end

function global_to_adjusted_global(glob :: Int) :: Int
    if rem(glob + olap * (proc - 1), proc) > 0
end

function global_to_local(glob :: Int, olap :: Int, proc :: Int) :: Int
    l = div(glob + olap * (proc - 1), proc)
    if rem(glob + olap * (proc - 1), proc) > 0
        @warn "A"
        l += 1
    end
    return l
end

MPI.Init()

global_x = 200
global_y = 200
procs = MPI.Dims_create(9, (0,0))
print("We have the following node dist $procs")

nx = global_to_local(202, 10, 3)
ny = nx

# SETUP 1
nx2 = 4
ny2 = 4
requires_halo = false
uneven = true


rank = MPI.Comm_rank(MPI.COMM_WORLD)

gg_big = init_global_grid_instance(nx, ny, 1; periodx=0, periody=0, overlaps=(10, 10, 10), init_MPI=false)
gg_small = init_global_grid_instance(nx2, ny2, 1; periodx=0, periody=0, init_MPI=false)

# Big = zeros(Float64, nx, ny)
# Small = zeros(Float64, nx2, ny2)

# Big = Big .+ rank


# @show calculate_sidx()
# @parallel calculate_sidx() reduction_average!(Big, Small, [40, 40])
# sleep(0.1 * rank)
# @show Small
# print("\n")
# update_halo!(gg_small, Small)

# sleep(0.1 * rank)
# @show Small
