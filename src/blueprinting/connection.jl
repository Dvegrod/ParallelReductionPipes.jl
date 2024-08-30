

"""
This function is used to obtain the reduced data from the runtime. Assuming it has one or more steps available to read. It fails otherwise.

# Arguments
 - `step_number` which step to read from the output stream
 - `connection_location` the path to the directory where the control channel is, by default "./connection"

# Returns
 An array with the reduced data.
"""
function getOutputStep(step_number :: Int, connection_location :: String = "connection") :: Array

    adios = adios_init_serial()
    io = declare_io(adios, "IO")

    engine = open(io, joinpath(connection_location, "reducer-o.bp"), mode_readRandomAccess)

    y = inquire_variable(io, "out")

    if y isa Nothing
        @error "Variable not available"
    end

    set_step_selection(y, step_number, 1)

    buf = Array{Float64}(undef, shape(y)...)

    get(engine, y, buf)

    perform_gets(engine)

    close(engine)

    return buf
end

