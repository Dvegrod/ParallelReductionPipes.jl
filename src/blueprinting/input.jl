"""
Creates a new pipe. Layers can then be added to it.

# Arguments
 - `var_name` : the name of the ADIOS2 variable that shall be taken as input for the pipe
 - `engine_name` : the name of the ADIOS2 engine where the variable is available
 - `config_file` : the path to the configuration file that should be used when connecting to the data supplier
 - `var_shape` : shape of the input variable
 - `var_type` : type of the data points on the input (as of now only `Float64` is supported)
"""
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

newPipe = input

