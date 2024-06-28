
quote
@parallel_indices (ix, iy) inbounds = true function reduction_avg!(Big::Array{Float64}, Small::Array{Float64})
    factor = div.(size(Big), size(Small))
    remdr = rem.(size(Big), size(Small))
    if sum(remdr) == 0
        lowx = 1 + (ix - 1) * 2
        lowy = 1 + (iy - 1) * 2
        highx = factor[1] + (ix - 1) * 2
        highy = factor[2] + (iy - 1) * 2

        Small[ix, iy] = reduce(+, Big[lowx:highx, lowy:highy]) ./ prod(factor)
    else
        error("Sizes dont match $remdr")
    end
    return
end

@parallel_indices (ix, iy) inbounds = true function reduction_max!(Big::Array{Float64}, Small::Array{Float64})
    factor = div.(size(Big), size(Small))
    remdr = rem.(size(Big), size(Small))
    if sum(remdr) == 0
        lowx = 1 + (ix - 1) * 2
        lowy = 1 + (iy - 1) * 2
        highx = factor[1] + (ix - 1) * 2
        highy = factor[2] + (iy - 1) * 2

        Small[ix, iy] = reduce(+, Big[lowx:highx, lowy:highy]) ./ prod(factor)
    else
        error("Sizes dont match $remdr")
    end
    return
end

@parallel_indices (ix, iy) inbounds = true function reduction_min!(Big::Array{Float64}, Small::Array{Float64})
    factor = div.(size(Big), size(Small))
    remdr = rem.(size(Big), size(Small))
    if sum(remdr) == 0
        lowx = 1 + (ix - 1) * 2
        lowy = 1 + (iy - 1) * 2
        highx = factor[1] + (ix - 1) * 2
        highy = factor[2] + (iy - 1) * 2

        Small[ix, iy] = reduce(+, Big[lowx:highx, lowy:highy]) ./ prod(factor)
    else
        error("Sizes dont match $remdr")
    end
    return
end

@parallel_indices (ix, iy) inbounds = true function reduction_mean!(Big::Array{Float64}, Small::Array{Float64})
    factor = div.(size(Big), size(Small))
    remdr = rem.(size(Big), size(Small))
    if sum(remdr) == 0
        lowx = 1 + (ix - 1) * 2
        lowy = 1 + (iy - 1) * 2
        highx = factor[1] + (ix - 1) * 2
        highy = factor[2] + (iy - 1) * 2

        Small[ix, iy] = reduce(+, Big[lowx:highx, lowy:highy]) ./ prod(factor)
    else
        error("Sizes dont match $remdr")
    end
    return
end


@parallel_indices (ix, iy) inbounds = true function reduction_sample!(Big::Array{Float64}, Small::Array{Float64})
    factor = div.(size(Big), size(Small))
    remdr = rem.(size(Big), size(Small))
    if sum(remdr) == 0
        lowx = 1 + (ix - 1) * 2
        lowy = 1 + (iy - 1) * 2
        highx = factor[1] + (ix - 1) * 2
        highy = factor[2] + (iy - 1) * 2

        Small[ix, iy] = reduce(+, Big[lowx:highx, lowy:highy]) ./ prod(factor)
    else
        error("Sizes dont match $remdr")
    end
    return
end
end
