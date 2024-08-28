


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

    @show shape(y), sum(buf)

    get(engine, y, buf)

    perform_gets(engine)

    close(engine)

    return buf
end

