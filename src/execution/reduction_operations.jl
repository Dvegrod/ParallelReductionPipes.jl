
#TODO : change to agnostic array
@parallel_indices (ix, iy, iz) inbounds = true function reduction_avg!(Big::Data.Array, Small::Data.Array)
    factor = div.(size(Big), size(Small))
    remdr = rem.(size(Big), size(Small))
    if sum(remdr) == 0
        # Index over a kernel region caution: Julia indexing makes it confusing (+1 and -1 added for that)
        lowx = 1 + (ix - 1) * factor[1]
        lowy = 1 + (iy - 1) * factor[2]
        lowz = 1 + (iz - 1) * factor[3]
        highx = factor[1] + lowx - 1
        highy = factor[2] + lowy - 1
        highz = factor[3] + lowz - 1

        Small[ix, iy, iz] = reduce(+, Big[lowx:highx, lowy:highy, lowz:highz]) ./ prod(factor)
    else
        error("Sizes dont match $remdr")
    end
    return
end


module CCustom
end


function loadCustomOperations(path :: String)
    include(path)
    push!(custom_reduction_functions!, Custom.kernel!)
end


reduction_functions! = Function[
    reduction_avg!
]

custom_reduction_functions! = Function[]

function loadStaticCustomOperations()
    for kernel! in reducer.precompilable_custom_operators
        push!(custom_reduction_functions!, kernel!)
    end
end
