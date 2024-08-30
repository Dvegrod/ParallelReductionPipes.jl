
# ADDING DINAMICALLY
custom = nothing
custom_file_location = "PRP_temp.jl"

"""
  This macro is used to dynamically define a custom operation. Additionally, this version

# Arguments:
  - `body` : an expression, which has to be an expression that results in a singular value.
           This expression can use the following symbols to its disposition:
               Big : an array with the input data to be reduced
               ix,iy,iz : the indices of the current output data cell that is being calculated
               low[x,y,z] : the lower bound of the window
               high[x,y,z] : the higher bound of the window
  - `name` : a unique name for the new operator.

# Example
    @custom_reduction_mini begin
       sum(Big[lowx:highx, lowy:highy, lowz:highz]) * 2
    end
This will sum the window together into one value, and multiply it by two.
"""
macro custom_reduction_mini(body :: Expr, name::String)

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

    addCustomOperatorToBlueprints(name, Int32(2))

    open(custom_file_location, "w") do file
        write(file, string(draft))
    end
    #declare_and_set(connection.io_comm_write, connection.engine_comm_write, metadata[:custom], "./temp.jl")

    return quote
        @info $status
    end
end


"""
  This macro is used to dynamically define a custom operation. There are some considerations to
  take into account when defining such.

# Arguments:
  - `body` : an expression, which has to be a function and has to fit the following template (fill the [brackets]):
    @parallel_indices ([indexes]) inbounds = true function [name]([input arg] ::Data.Array, [output arg] :: Data.Array)
       [body]
       return;
    end
  - `name` : a unique name for the new operator.

# Example:
    @parallel_indices (ix, iy, iz) inbounds = true function kernel!(IN :: Data.Array, OUT :: Data.Array)
            OUT[ix,iy,iz] = IN[ix,iy,iz] * 100
            return
    end
This will multiply by 100 the correspondent input. This kernel is designed for a window of 1 since just 1 value is used in the right side of the "=".
"""
macro custom_reduction(body :: Expr, name::String)

    status = "Successful custom kernel construction"

    draft = quote
        module Custom
        using ParallelStencil
        @init_parallel_stencil(Threads, Float64, 3)

        $body
        end
    end

    draft = MacroTools.unblock(MacroTools.flatten(draft))

    addCustomOperatorToBlueprints(name, Int32(2))

    open(custom_file_location, "w") do file
        write(file, string(draft))
    end

    #declare_and_set(connection.io_comm_write, connection.engine_comm_write, metadata[:custom], "./temp.jl")

    return quote
        @info $status
    end
end


# ADDING STATICALLY

precompilable_custom_operators = Function[]

"""
  This macro is used to statically define a custom operation. There are some considerations to
  take into account when defining such.

# Arguments
  - `reduction` : a function, that has to fit the following template (fill the [brackets]):
    @parallel_indices ([indexes]) inbounds = true function [name]([input arg] ::Data.Array, [output arg] :: Data.Array)
       [body]
       return;
    end
  - `name` : a unique name for the new operator.

"""
function addCustomReduction(reduction :: Function, name :: String)
    # Register the operator
    id = addCustomOperatorToBlueprints(name, Int32(1))
    # Save the function for the runtime
    push!(precompilable_custom_operators, reduction)

    return id
end
