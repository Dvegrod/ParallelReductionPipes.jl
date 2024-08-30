"""
  Creates a new window.

# Arguments
 - `dims` : the size of the kernel in 1D,2D or 3D
 - `trim` : UNUSED AS OF NOW, specifies if in the case the domain and the window are not divisible, the borders should be trimmed or compute smaller windows at the border.
"""
function kernel(dims :: Union{AbstractArray, NTuple}, trim :: Bool = false) :: Kernel
    return Kernel(
        dims,
        trim
    )
end

window = kernel
