module MockAdios

using HDF5: h5_close
using Core: _typevar
using MPI, HDF5

struct SerializedShardedMatrix{N}
    threads :: Int
    thread  :: Int

    global_shape :: Vector{Int}
    local_shape :: Vector{Int}

    grid :: Vector{Int}
    position :: Vector{Int}


    values :: Array{N, 4,4}
end

struct SerializedSequence{N}
    steps :: Vector{SerializedShardedMatrix{N}}
end

let
    # _foldername :: String = "default.mkadios"
    # _size :: Int = 0
    # _rank :: Int = 0

    # _type :: Type = Nothing
    # _shape :: Vector{Int} = []

    # _grid::Vector{Int} = []
    # _position::Vector{Int} = []

    # global init, set_matrix_properties, set_local_properties, write_matrix, read_matrix

    # function init(foldername :: String, mpi_comm :: MPI.Comm)
    #     _foldername = foldername
    #     _rank = MPI.Comm_rank(mpi_comm)
    #     _size = MPI.Comm_size(mpi_comm)
    #     mkdir(foldername)
    # end

    # function set_matrix_properties(type :: Type, shape :: Vector{Int})
    #     _type = type
    #     _shape = shape
    # end

    # function set_local_properties(cart_grid :: Vector{Int}, position :: Vector{Int})
    #     _grid = cart_grid
    #     _position = position
    # end

    function write_matrix(matrix :: Array)
        new = SerializedShardedMatrix{_type}(
            _size,
            _rank,
            _shape,
            [i for i in size(matrix)],
            _grid,
            _position,
            matrix
        )
        f = h5open(_foldername * "/" * "$_rank.view", "w")
        f["SSM"] = new
        close(f)
    end


    function read_matrix(rank :: Int)
        f = h5open(_foldername * "/" * "$rank.view", "r")
        g = f["SSM"]
        close(f)
        return g
    end
end

end
