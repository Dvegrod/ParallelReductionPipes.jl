
using ADIOS2
using Plots

adios = adios_init_serial("mandel/adios-config.xml")
io = declare_io(adios, "IO")

engine = open(io, "$(ENV["SCRATCH"])/sst-file", mode_read)

begin_step(engine)
@show inquire_all_variables(io)
y = inquire_variable(io, "mandel")

buf = Array{Float64}(undef, 1000,1000)

step = Ref{Csize_t}()
err = ccall((:adios2_current_step, ADIOS2.libadios2_c), Cint,
            (Ptr{Csize_t}, Ptr{Cvoid}), step, engine.ptr)
Error(err) ≠ error_none && return nothing
@show step.x

get(engine, y, buf)

perform_gets(engine)

@show sum(buf)

spy(buf)

savefig("out.png")
