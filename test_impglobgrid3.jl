
using MPI
using ImplicitGlobalGrid


nx = 10
ny = 10
nx2 = 5
ny2 = 5

function reduction_sum!(Big :: Array{Float64}, Small :: Array{Float64})
    factor = div.(size(Big), size(Small))
    remdr = rem.(size(Big), size(Small))
    if sum(remdr) == 0
        for matrix_idx in CartesianIndices(Small)
            for kernel_idx in CartesianIndices((1:factor[1], 1:factor[2]))
                Small[matrix_idx] += Big[2 * (matrix_idx - CartesianIndex(1,1)) + kernel_idx]
            end
        end
    else
        error("Sizes dont match $remdr")
    end
end

MPI.Init()

rank = MPI.Comm_rank(MPI.COMM_WORLD)

gg_big   = init_global_grid_instance(nx, ny, 1;   periodx= 0, periody= 0, init_MPI= false)
gg_small = init_global_grid_instance(nx2, ny2, 1; periodx= 0, periody= 0, init_MPI= false)

Big = zeros(Float64, nx, ny)
Small = zeros(Float64, nx2, ny2)

Big = Big .+ rank

update_halo!(gg_big, Big)
reduction_sum!(Big, Small)
update_halo!(gg_small, Small)

sleep(0.1 * rank)
@show Small
