


function getOutputStep(step_number :: Int, connection_location :: String = "connection") :: Array

    y = inquire_variable(joinpath(connection_location, "reducer-o.bp"), "out")

    set_step_selection(y, step_number, 1)

    buf = Array{Float64}(undef, shape(y)...)

    @show shape(y), sum(buf)

    get(connection.engine_read, y, buf)

    perform_gets(connection.engine_read)

    return buf
end
