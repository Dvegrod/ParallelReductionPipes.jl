
let
    global get_operator

    averages = [
        Operator(
            "average",
            Float64,
            Float64,
            0
        ),
    ]

    medians = [
        Operator(
            "median",
            Float64,
            Float64,
            0
        ),
    ]

    maximums = [
        Operator(
            "maximum",
            Float64,
            Float64,
            0
        ),
    ]

    minimums = [
        Operator(
            "minimum",
            Float64,
            Float64,
            0
        ),
    ]

    samples = [
        Operator(
            "sample",
            Float64,
            Float64,
            0
        ),
    ]

    operators::Dict{String, Vector{Operator}} = Dict([
        "average" => averages,
        "median" => medians,
        "maximum" => maximums,
        "minimum" => minimums,
        "sample" => samples
    ])

    get_operator(name::String, in :: Type, out:: Type) = operators[name][1]
end
