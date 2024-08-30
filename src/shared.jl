
# CONNECTION

side_a = "reducer-r.bp"
side_b = "reducer-l.bp"

connectionGetSide(b :: Bool) = b ? side_b : side_a

"""
  A connection object is used to create a duplex communication channel
  between the runtime and the pipe-builder/control process

  A connection has two sides, each side reads and writes from opposite streams.

  Make sure to not have a connection with 2 writers on the same side.
"""
abstract type AbstractConnection end

"""
  Serial connection.
"""
struct Connection <: AbstractConnection
    location :: String
    side     :: Bool
    timeout  :: Int
end

"""
  Used to check if a adios stream file has been already created, if its not the case the function waits
"""
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

"""
  Given a connection, this method will open the READING stream
"""
function connect(connection :: Connection)

    side = joinpath(connection.location, connectionGetSide(connection.side))

    wait_for_existence(side, connection.timeout)

    adios = adios_init_serial()
    comm_io = declare_io(adios, side * "IO")
    comm_engine = open(comm_io, side, mode_readRandomAccess)
    return (adios,comm_io,comm_engine)
end

"""
  Given a connection, this method will open the WRITING stream.

  Warning: previous contents on the writing stream might be overwritten.
"""
function setup(connection :: Connection)

    side = joinpath(connection.location, connectionGetSide(!connection.side))

    adios = adios_init_serial()
    comm_io = declare_io(adios, side * "IOw")
    comm_engine = open(comm_io, side, mode_write)
    return (adios,comm_io,comm_engine)
end

"""
  Given a connection, inquire a variable, in case of absence, wait for it
"""
function poll_inquire(connection :: AbstractConnection, var_name :: String)

    (a,io,engine) = connect(connection)

    @show var_name, connection.timeout

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

# OTHER THINGS

"""
  Defines the control flags in the control channel

  Requires a WRITE stream IO
"""
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

"""
  Defines the pipeline serialization variables in the control channel

  Requires a WRITE stream IO
"""
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


"""
  Inquires the pipeline serialization variables by reading the control channel
"""
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



"""
 Reads a serialized pipe from the control channel

 Requires a READING ADIOS2 IO and ENGINE
"""
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


"""
  Used to get a specific variable from the control flags given a connection
"""
function _get(connection::AbstractConnection, key::Symbol)::Any

    @show connection, key
    if key in keys(metadata)

        a, io, engine, y = poll_inquire(connection, metadata[key].name)

        if isnothing(y)
            #e = ArgumentError("Invalid key $key, value is not available on the specified IO")
            #throw(e)
            return nothing
        end

        sh = shape(y)
        if length(sh) > 0
            reference = Array{type(y),length(sh)}(undef, sh...)
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


"""
  Used to set a specific variable from the control flags given a connection

  WARNING: this will overwrite the entire writing stream on the control plane
"""
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


"""
  Used to set a specific variable from the control flags given a READING ADIOS2 IO and ENGINE
"""
function _set(io, ADIOS2::AIO, engine::ADIOS2.Engine, key::Symbol, value::Any)

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

"""
  Used to set a specific variable (from metadata or pipe serialization) given a READING ADIOS2 IO and ENGINE
"""
function _set(io::ADIOS2.AIO, engine::ADIOS2.Engine, var::Var, value::Any)

    y = inquire_variable(io, var.name)

    if isnothing(y)
        e = ArgumentError("Invalid key $key, value is not available on the specified IO")
        throw(e)
    end

    put!(engine, y, value)

    perform_puts!(engine)


end


"""
  Used to declare set an unexistent specific variable (from metadata or pipe serialization) given a connection

  WARNING: this will overwrite the entire writing stream on the control plane
"""
function declare_and_set(connection::AbstractConnection, var_data::Var, value::Any)

    a, io, engine = setup(connection)

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


"""
  Used to declare set an unexistent specific variable (from metadata or pipe serialization) given a READING ADIOS2 IO and ENGINE
"""
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
