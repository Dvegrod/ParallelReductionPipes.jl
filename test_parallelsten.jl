using Base: SmallSigned
using ParallelStencil: @parallel_indices_cuda

const USE_GPU = false
using ImplicitGlobalGrid
import MPI
using ParallelStencil

@static if USE_GPU
    @init_parallel_stencil(CUDA, Float64, 2);
else
    @init_parallel_stencil(Threads, Float64, 2);
end


@parallel_indices (ix, iy) inbounds=true function reduction_sum!(Big::Array{Float64}, Small::Array{Float64})
    factor = div.(size(Big), size(Small))
    remdr = rem.(size(Big), size(Small))
    if sum(remdr) == 0
        lowx = 1 + (ix - 1) * 2
        lowy = 1 + (iy - 1) * 2
        highx = factor[1] + (ix - 1) * 2
        highy = factor[2] + (iy - 1) * 2

        Small[ix, iy] = reduce(+, Big[lowx:highx, lowy:highy])
    else
        error("Sizes dont match $remdr")
    end
    return
end

MPI.Init()

nx = 10
ny = 10
nx2 = 5
ny2 = 5

rank = MPI.Comm_rank(MPI.COMM_WORLD)

gg_big = init_global_grid_instance(nx, ny, 1; periodx=0, periody=0, init_MPI=false)
gg_small = init_global_grid_instance(nx2, ny2, 1; periodx=0, periody=0, init_MPI=false)

Big = zeros(Float64, nx, ny)
Small = zeros(Float64, nx2, ny2)

Big = Big .+ rank

update_halo!(gg_big, Big)
@parallel (1:size(Small,1),1:size(Small,2)) reduction_sum!(Big, Small)
update_halo!(gg_small, Small)

sleep(0.1 * rank)
@show Small
