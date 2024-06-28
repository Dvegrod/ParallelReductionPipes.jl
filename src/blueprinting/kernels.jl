
function kernel(dims :: Union{AbstractArray, NTuple}, collapse :: Bool = true, trim :: Bool = false) :: Kernel
    return Kernel(
        dims,
        collapse,
        trim
    )
end
