using MacroTools

macro custom_reduction(body :: Expr, name::String)

    status = "Successful custom kernel construction"

    draft = quote
        module Custom
        using ParallelStencil
        @init_parallel_stencil(Threads, Float64, 3)

        @parallel_indices (ix, iy, iz) inbounds = true function kernel!(Big::Array{Float64}, Small::Array{Float64})
            factor = div.(size(Big), size(Small))
            remdr = rem.(size(Big), size(Small))
            if sum(remdr) == 0
                # Index over a kernel region caution: Julia indexing makes it confusing (+1 and -1 added for that)
                lowx = 1 + (ix - 1) * factor[1]
                lowy = 1 + (iy - 1) * factor[2]
                highx = factor[1] + lowx - 1
                highy = factor[2] + lowy - 1

                Small[ix, iy, iz] = $body
            else
                error("Sizes dont match $remdr")
            end
            return
        end
        end
    end

    draft = MacroTools.unblock(MacroTools.flatten(draft))

    addCustomOperatorToBlueprints(name, Symbol(name))

    open("temp.jl", "w") do file
        write(file, string(draft))
    end

    #declare_and_set(connection.io_comm_write, connection.engine_comm_write, metadata[:custom], "./temp.jl")

    return quote
        @info $status
    end
end

