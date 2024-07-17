using MPI: Comm_size, COMM_WORLD
using MPI
using ADIOS2
using Test

function _set_data_2D(T, comm_rank, step)
    data = ones(T, 10, 10)

    for j in 2:4
        for i in 2:4
            data[i, j] = comm_rank + step
        end
    end

    return data
end

MPI.Init()

# Set up ADIOS
adios = adios_init_mpi(MPI.COMM_WORLD)


comm_rank = MPI.Comm_rank(MPI.COMM_WORLD)
comm_size = MPI.Comm_size(MPI.COMM_WORLD)

@test adios isa Adios

io = declare_io(adios, "io_writer")
@test io isa AIO

count = (10, 10)
start = (0, comm_rank * 10)
shape = (10, comm_size * 10)
# open engine
writer = open(io, "AAA.bp", mode_write)

# for step in 1:3
#     begin_step(writer)

#     for T in
#         Type[Float32, Float64, Complex{Float32}, Complex{Float64}, Int8,
#         Int16, Int32, Int64, UInt8, UInt16, UInt32, UInt64]

#         # define some nd array variables, 10x10 per MPI process
#         var_T = step == 1 ?
#                 define_variable(io, string(T), T, shape, start, count) :
#                 inquire_variable(io, string(T))
#         data_2D = _set_data_2D(T, comm_rank, step)
#         put!(writer, var_T, data_2D) # deferred mode
#     end

#     end_step(writer)
# end
perform_puts!(writer)

@show writer
if comm_rank >= 0
    close(writer)
    finalize(adios)
end

if comm_rank == 1
    @warn "A"
end

MPI.Barrier(MPI.COMM_WORLD)
if comm_rank == 1
    @warn "A"
end
MPI.Finalize()
