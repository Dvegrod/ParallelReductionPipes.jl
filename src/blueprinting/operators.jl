
# Singleton that keeps record of the avaiable operators for reduction accesible by code and name
let

    operator_by_id::Vector{Operator} = Operator[
        Operator(
            "average",
            Float64,
            Float64,
            1,
            :average
        ),
    ]

    operator_by_name::Dict{Symbol,Operator} = Dict{Symbol,Operator}([i.symbol => i for i in operator_by_id])

    custom_operator_by_id::Vector{Operator} = Operator[]

    custom_operator_by_name(name ::String) = Dict{Symbol,Operator}([i.symbol => i for i in operator_by_id])[name]

    #global parseOperator;

    global function parseOperator(operator_alias::Union{Symbol,String,Int})
        @show operator_alias
        if operator_alias isa Int
            if operator_alias > 0
                return operator_by_id[operator_alias]
            else
                return custom_operator_by_id[operator_alias * -1]
            end
        elseif operator_alias isa Symbol
            return operator_by_name[operator_alias]
        else
            return operator_by_name[Symbol(operator_alias)]
        end
    end

    global function addCustomOperatorToBlueprints(name::String, symbol :: Symbol)
        push!(custom_operator_by_id, Operator(name, Float64, Float64, -1 * (length(custom_operator_by_id)  + 1), symbol))
        return length(custom_operator_by_id)
    end
end
