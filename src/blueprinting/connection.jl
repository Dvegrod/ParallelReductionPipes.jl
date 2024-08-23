
connection :: Union{Nothing, Connection} = nothing

function getStep(connection :: Connection, step_number :: Int) :: Array
    y = inquire_variable(connection.io_read, "out")

    set_step_selection(y, step_number, 1)

    buf = Array{Float64}(undef, shape(y)...)

    @show shape(y), sum(buf)

    get(connection.engine_read, y, buf)

    perform_gets(connection.engine_read)

    return buf
end

function getStep(connection :: Connection, step_start :: Int, step_count :: Int) :: Vector{Array}
    @assert step_count > 0

    y = inquire_variable(connection.io_read, "out")

    set_step_selection(y, step_number, step_count)

    buf = Array{Float64}(undef, shape(y)...)

    @show shape(y), sum(buf)

    get(connection.engine_read, y, buf)

    perform_gets(connection.engine_read)

    return buf
end
