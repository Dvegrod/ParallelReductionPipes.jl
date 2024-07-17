
function input(var_name, engine_name, config_file, var_shape :: Union{AbstractArray, NTuple}, var_type :: Type) :: PipelineBuilder

    shape = Int[]
    for i in var_shape
        if i isa Int
            push!(shape, i)
        else
            throw(TypeError("input", Int, typeof(i)))
        end
    end

    i = Input(
        var_name,
        engine_name,
        config_file,
        [i for i in shape],
        var_type in supported_types ? var_type : throw(ErrorException("Unsupported type $var_type"))
    )

    return PipelineBuilder(
        i,
        Layer[],
        0
    )
end
