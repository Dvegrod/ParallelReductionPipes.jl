

side_a = "reducer-r.bp"
side_b = "reducer-l.bp"

connectionGetSide(b :: Bool) = b ? side_b : side_a

abstract type AbstractConnection end

struct Connection <: AbstractConnection
    location :: String
    side     :: Bool
    timeout  :: Int
end

function wait_for_existence(filename :: String, timeout :: Int)
    i = 1
    while !isdir(filename) && i <= timeout
        @show filename
        sleep(1)
        i += 1
    end
    if i > timeout
        e = ErrorException("Connection trial timed out")
        throw(e)
    end
end

function connect(connection :: Connection)

    side = joinpath(connection.location, connectionGetSide(connection.side))

    wait_for_existence(side, connection.timeout)

    adios = adios_init_serial()
    comm_io = declare_io(adios, side * "IO")
    comm_engine = open(comm_io, side, mode_readRandomAccess)
    return (adios,comm_io,comm_engine)
end

function setup(connection :: Connection)

    side = joinpath(connection.location, connectionGetSide(!connection.side))

    adios = adios_init_serial()
    comm_io = declare_io(adios, side * "IOw")
    comm_engine = open(comm_io, side, mode_write)
    return (adios,comm_io,comm_engine)
end

function poll_inquire(connection :: AbstractConnection, var_name :: String)

    (a,io,engine) = connect(connection)

    @show var_name

    y = inquire_variable(io, var_name)

    i = 1
    while y isa Nothing && i <= connection.timeout
        sleep(1)
        a,io,engine = connect(connection)
        y = inquire_variable(io, var_name)
        i += 1
    end

    return a,io,engine,y
end


# macro check_for_val_w_timeout(func :: Expr, val :: Any, time_sec :: Int)

#     f = eval(func)

#     return quote
# 	      for i in 1:$time_sec
#             r = f()
#             if r !== nothing && r == $val
#                 return true
#             end
#         end
#         return false
#     end
# end

# Defines the variables used to comunicate status
function defineMetadata(adios_io::ADIOS2.AIO)
    #TODO
    for (_, var) in metadata
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


function _get(connection::AbstractConnection, key::Symbol)::Any

    @show connection,key
    if key in keys(metadata)

        a,io,engine,y = poll_inquire(connection, metadata[key].name)

        if isnothing(y)
            #e = ArgumentError("Invalid key $key, value is not available on the specified IO")
            #throw(e)
            return nothing
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
            e = ErrorException("Not implemented for var_repository")
            throw(e)
        else
            e = ArgumentError("Invalid key $key")
            throw(e)
        end
    end
end

function _set(connection :: AbstractConnection, key::Symbol, value::Any)


    a,io,engine = setup(connection)

    if key in keys(metadata)
        y = inquire_variable(io, metadata[key].name)

        if isnothing(y)
            e = ArgumentError("Invalid key $key, value is not available on the specified IO")
            throw(e)
        end

        put!(engine, y, value)

        perform_puts!(engine)

    else
        if key in var_repository
            e = ErrorException("Not implemented for var_repository")
            throw(e)
        else
            e = ArgumentError("Invalid key $key")
            throw(e)
        end
    end

    close(engine)
end

# WARNING THE FIRST OVERWRITES THE ENTIRE FILE THIS ONE DOES NOT
function _set(io, ADIOS2::AIO, engine :: ADIOS2.Engine, key::Symbol, value::Any)

    if key in keys(metadata)
        y = inquire_variable(io, metadata[key].name)

        if isnothing(y)
            e = ArgumentError("Invalid key $key, value is not available on the specified IO")
            throw(e)
        end

        put!(engine, y, value)

        perform_puts!(engine)

    else
        if key in var_repository
            e = ErrorException("Not implemented for var_repository")
            throw(e)
        else
            e = ArgumentError("Invalid key $key")
            throw(e)
        end
    end

end

function _set(io :: ADIOS2.AIO, engine :: ADIOS2.Engine, var :: Var, value::Any)

        y = inquire_variable(io, var.name)

        if isnothing(y)
            e = ArgumentError("Invalid key $key, value is not available on the specified IO")
            throw(e)
        end

        put!(engine, y, value)

        perform_puts!(engine)


end

function declare_and_set(connection :: AbstractConnection, var_data::Var, value::Any)

    a,io,engine = setup(connection)

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

    close(engine)
    finalize(a)
end


function declare_and_set(io :: ADIOS2.AIO, engine :: ADIOS2.Engine, var_data::Var, value::Any)


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
