using ParallelReductionPipes

@custom_reduction begin
    @parallel_indices (ix, iy, iz) inbounds = true function kernel!(Input::Array{Float64}, Output::Array{Float64})
        Output[ix,iy,iz] = 100 * Input[ix,iy,iz]

        return nothing
    end
end "by100"

pipe = newPipe("mandel", "./sstfile", "./adios_config.xml", [1000, 1000, 1], Float64)

# Add layer
w10x10 = window([10, 10, 1])
pipe = reduction(pipe, w10x10, :average)

# Add layer
w10x10 = window([1, 1])
pipe = reduction(pipe, w10x10, "by100")

# Launch
ParallelReductionPipes.build(pipe)
