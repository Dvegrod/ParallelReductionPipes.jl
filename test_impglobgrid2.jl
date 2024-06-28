using ImplicitGlobalGrid: @periodz, get_global_grid

using MPI
using ImplicitGlobalGrid


nx = 5
ny = 5

MPI.Init()

rank = MPI.Comm_rank(MPI.COMM_WORLD)

gg = init_global_grid_instance(nx, ny, 1; periodx = 1, periody = 1, init_MPI= false)

sleep(0.01 * rank)

A = zeros(Float64, nx, ny)

A = A .+ rank

update_halo!(A)

sleep(0.01 * rank)
@show A

nx2 = 3
ny2 = 3

gg2 = init_global_grid_instance(nx2, ny2, 1; periodx=1, periody=1, init_MPI=false, quiet = true)

A = zeros(Float64, 6, 6)

A = A .+ rank

update_halo!(A)

sleep(0.05 * rank)
@show gg2


switch(gg)

@show get_global_grid()
