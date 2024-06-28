
function kernel(dims :: Union{AbstractArray, NTuple}, collapse :: Bool = true) :: Kernel
    return Kernel(
        dims,
        collapse
    )
end

