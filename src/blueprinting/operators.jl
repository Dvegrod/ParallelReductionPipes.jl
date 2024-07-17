
# Singleton that keeps record of the avaiable operators for reduction accesible by code and name
let

    operator_by_id::Vector{Operator} = Operator[
        Operator(
            "average",
            Float64,
            Float64,
            1,
            :average
        )
    ]

    operator_by_name::Dict{Symbol,Operator} = Dict{Symbol,Operator}([i.symbol => i for i in operator_by_id])


    #global parseOperator;

    global function parseOperator(operator_alias::Union{Symbol,String,Int})
        if operator_alias isa Int
            return operator_by_id[operator_alias]
        elseif operator_alias isa Symbol
            return operator_by_name[operator_alias]
        else
            return operator_by_name[Symbol(operator_alias)]
        end
    end
end
