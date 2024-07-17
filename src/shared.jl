
# Defines the variables used to comunicate a pipeline configuration
function definePipelineConfigurationStructure(adios_io::ADIOS2.AIO)
    #TODO
    for (_, var) in var_repository
        if length(var.shape) > 0
            sh = Tuple(var.shape)
            st = Tuple([0 for i in var.shape])
            cn = Tuple(var.shape)
        else
            sh = nothing
            st = nothing
            cn = nothing
        end
        define_variable(adios_io, var.name, var.type, sh, st, cn)
    end
end


# Inquires the variables used to comunicate a pipeline configuration
function inquirePipelineConfigurationStructure(adios_io::ADIOS2.AIO)::Dict{Symbol,ADIOS2.Variable}

    result = Dict{Symbol,ADIOS2.Variable}()
    try
        for (key, var) in var_repository
            y = inquire_variable(adios_io, var.name)
            result[key] = y
        end
    catch e
        @warn "Failure inquiring variables"
        return Dict{Symbol,ADIOS2.Variable}()
    end

    return result
end


# Gets the variables used to comunicate a pipeline configuration
function getPipelineConfigurationStructure(adios_engine::ADIOS2.Engine, vars::Dict{Symbol,ADIOS2.Variable})::Dict{Symbol,Any}

    result = Dict{Symbol,Any}()
    for (key, var) in vars
        sh = shape(var)
        if length(sh) > 0
            reference = Array{type(var),length(sh)}(undef, sh...)
        else
            reference = Ref{type(var)}()
        end

        get(adios_engine, var, reference)


        perform_gets(adios_engine)
        result[key] = reference isa Ref ? reference.x : reference
    end


    return result
end


function _get(io::ADIOS2.AIO, engine::ADIOS2.Engine, key::Symbol)::Any
    if key in metadata
        y = inquire_variable(io, var_repository[key].name)

        if isnothing(y)
            e = ArgumentError("Invalid key $key, value is not available on the specified IO")
            throw(e)
        end

        sh = shape(y)
        if length(sh) > 0
            reference = Array{type(y), length(sh)}(undef, sh...)
        else
            reference = Ref{type(y)}()
        end

        get(engine, y, reference)

        perform_gets(engine)

        return reference isa Ref ? reference.x : reference
    else
        if key in var_repository
        else
            e = ArgumentError("Invalid key $key")
            throw(e)
        end
    end
end

function set(io::ADIOS2.IO, engine::ADIOS2.Engine, key::Symbol, value::Any)
    if key in metadata
        y = inquire_variable(io, var_repository[key].name)

        if isnothing(y)
            e = ArgumentError("Invalid key $key, value is not available on the specified IO")
            throw(e)
        end

        put!(engine, y, value)

        perform_puts!(engine)

    else
        if key in var_repository

        else
            e = ArgumentError("Invalid key $key")
            throw(e)
        end
    end
end

function declare_and_set(io::ADIOS2.AIO, engine::ADIOS2.Engine, var_data::Var, value::Any)
    y = inquire_variable(io, var_data.name)

    if !isnothing(y)
        e = ArgumentError("Invalid definition $var_data.name, already defined on the specified IO")
        throw(e)
    end

    if length(var_data.shape) > 0
        sh = Tuple(var_data.shape)
        st = Tuple([0 for i in var_data.shape])
        cn = Tuple(var_data.shape)
    else
        sh = nothing
        st = nothing
        cn = nothing
    end
    y = define_variable(io, var_data.name, var_data.type, sh, st, cn)

    put!(engine, y, value)

    perform_puts!(engine)
end
