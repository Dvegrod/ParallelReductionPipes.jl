
function getOverlaps(kernel:: Kernel) :: Vector{Int}
    return kernel.dims .- 1
end


function globalToLocalSize(input_shape::Vector{Int}, kernel :: Kernel, processes :: Vector{Int}) :: Vector{Int}
    if length(kernel.dims) != length(input_shape)
        throw(DimensionMismatch("The kernel and the input have different dimensions: K: $(kernel.dims) IN: $(input_shape)"))
    end
    local_dims = Int[]
    return Int[]
end
