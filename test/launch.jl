
using MPI

out = "$dirname/out.txt"
launchcmd = `$(MPI.mpiexec()) -n 4 julia --project=".." ../src/reducer.jl`

@info "Launch command for launch test: $launchcmd"

@testset "Reducer runtime launcher" begin

    builder::PipelineBuilder = input("var_name", filename, "", [100, 100, 10], Float64)

    # Add one layer
    ker1 = reducer.kernel([10, 10, 1])
    builder = reduction(builder, ker1, :average)

    # Launch
    p = run(pipeline(launchcmd, out); wait=false)
    reducer.build(builder)

    adios = adios_init_serial()
    io = declare_io(adios, "COMM_IO")
    engine = open(io, "reducer.bp", mode_readRandomAccess)

    #    @test reducer.@check_for_val_w_timeout((f() = _get(io, engine, :exec_ready)), 1, 10)

    # Build

 #   @test reducer.@check_for_val_w_timeout((f() = _get(io, engine, :exec_ready)), 2, 10)

    success(p)
end

f = open(out)
@show read(out, String)
