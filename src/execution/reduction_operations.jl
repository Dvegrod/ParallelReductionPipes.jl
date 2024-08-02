
#TODO
@parallel_indices (ix, iy, iz) inbounds = true function reduction_avg!(Big::Array{Float64}, Small::Array{Float64})
    factor = div.(size(Big), size(Small))
    remdr = rem.(size(Big), size(Small))
    if sum(remdr) == 0
        # Index over a kernel region caution: Julia indexing makes it confusing (+1 and -1 added for that)
        lowx = 1 + (ix - 1) * factor[1]
        lowy = 1 + (iy - 1) * factor[2]
        highx = factor[1] + lowx - 1
        highy = factor[2] + lowy - 1

        Small[ix, iy] = reduce(+, Big[lowx:highx, lowy:highy]) ./ prod(factor)
    else
        error("Sizes dont match $remdr")
    end
    return
end




reduction_functions! = Function[
    reduction_avg!
]
