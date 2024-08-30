
# Object that keeps record of the avaiable operators for reduction accesible by code and name
let

    operator_by_id::Vector{Operator} = Operator[
        Operator(
        "average",
        Float64,
        Float64,
        1,
        0,
        :average
    ),
    ]

    operator_by_name::Dict{Symbol,Operator} = Dict{Symbol,Operator}([i.symbol => i for i in operator_by_id])

    custom_operator_by_id::Vector{Operator} = Operator[]

    custom_operator_by_name(name::Symbol) = Dict{Symbol,Operator}([i.symbol => i for i in custom_operator_by_id])[name]

"""
  Given an operator identifier, retrieves the operator register used in pipe building

# Arguments:
  - `operator_alias` : it can be de numerical id (positive for native operators, negative for custom ones), the key symbol or the name
"""
    global function parseOperator(operator_alias::Union{Symbol,String,Int})
        @show operator_alias
        if operator_alias isa Int
            if operator_alias > 0
                return operator_by_id[operator_alias]
            else
                return custom_operator_by_id[operator_alias * -1]
            end
        elseif operator_alias isa Symbol
            if operator_alias in keys(operator_by_name)
                return operator_by_name[operator_alias]
            elseif true # TODO
                return custom_operator_by_name(operator_alias)
            else
                throw(ArgumentError("Invalid operator symbol, operator not found"))
            end
        else
            operator_alias = Symbol(operator_alias)
            if operator_alias in keys(operator_by_name)
                return operator_by_name[operator_alias]
            elseif true
                return custom_operator_by_name(operator_alias)
            else
                throw(ArgumentError("Invalid operator name, operator not found"))
            end
        end
    end

"""
  Adds a new custom operator to the register of available operators for pipe construction.

# Arguments:
 - `name` : a unique name for the operator
 - `kind` : 1 of its a static custom operator (imported before runtime) or 2 if its a dynamic one (imported during runtime)
"""
    global function addCustomOperatorToBlueprints(name::String, kind :: Int32)
        push!(custom_operator_by_id, Operator(name, Float64, Float64, -1 * (length(custom_operator_by_id)  + 1), kind, Symbol(name)))
        global custom = "something"
        return length(custom_operator_by_id)
    end
end
