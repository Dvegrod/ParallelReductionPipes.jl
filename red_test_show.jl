
using ADIOS2
using Plots

include("src/reducer.jl")

adios = adios_init_serial()
io = declare_io(adios, "IO")

engine = open(io, "reducer-o.bp", mode_readRandomAccess)

y = inquire_variable(io, "out")

buf = Array{Float64}(undef, 100,100)

@show sum(buf)

get(engine, y, buf)

perform_gets(engine)

@show sum(buf)

spy(buf)

savefig("outred.png")

#@assert reducer.@check_for_val_w_timeout((f() = reducer._get(io, engine, :exec_ready)), 1, 10)

# Build
#@assert reducer.@check_for_val_w_timeout((f() = reducer._get(io, engine, :exec_ready)), 2, 10)

