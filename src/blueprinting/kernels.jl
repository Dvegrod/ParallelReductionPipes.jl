
function kernel(dims :: Union{AbstractArray, NTuple}, trim :: Bool = false) :: Kernel
    return Kernel(
        dims,
        trim
    )
end
