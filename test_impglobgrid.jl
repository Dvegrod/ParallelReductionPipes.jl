using ImplicitGlobalGrid: @periodz

using MPI
using ImplicitGlobalGrid


nx = 11
ny = 11

MPI.Init()

rank = MPI.Comm_rank(MPI.COMM_WORLD)

cart = init_global_grid(nx, ny, 1; periodx = 0, periody = 0, overlaps=(6,6,6), init_MPI= false)

sleep(0.01 * rank)
@show cart

A = zeros(Float64, nx, ny)

A = A .+ rank

update_halo!(A)

sleep(0.1 * rank)
@show A

# nx2 = 3
# ny2 = 3

# finalize_global_grid(; finalize_MPI=false)
# init_global_grid(nx, ny, 1; periodx=1, periody=1, init_MPI=false)

# A = zeros(Float64, 6, 6)

# A = A .+ rank

# update_halo!(A)

# sleep(0.01 * rank)
# @show A
