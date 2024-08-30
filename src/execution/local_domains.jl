
struct LocalDomain
    data :: Array
    start :: Tuple
    size :: Tuple
end

function transform(big_domain :: LocalDomain, kernel :: Tuple, buffer :: Data.Array) :: LocalDomain

    # TODO Inexact
    new_start = div.(big_domain.start, kernel)
    new_size = div.(big_domain.size, kernel)

    return LocalDomain(buffer, new_start,  new_size)
end

"""
  This function is used to get which local partition of a domain (`shape`) corresponds to the `rank`-th process given the `dims` process cartesian grid.
"""
function localChunkSelection(sh :: Tuple, rank :: Int, dims :: Union{Tuple, Vector})

    @assert 0 < length(dims) <= 3

    pcoords = dim_coord(rank, dims)

    @debug pcoords

    dcoords = Tuple(slicer1D.(pcoords, sh, dims))

    @debug dcoords

    tdcoords = transpose(dcoords)

    return tdcoords
end

"""
  This function is used to calculate the entire local pipeline sizes for a specific process based on the global domains and the rank of the current process
"""
function calculateShape(layer_config :: Array{Int}, input_shape :: Tuple, n_layers :: Int, rank :: Int, dims ::Tuple) :: Vector{LocalLayer}

    local_layers = LocalLayer[]

    global_output_shape = Tuple(layer_config[n_layers, 5:7])
    @debug layer_config

    # Segment the final output given the processes
    local_output_start, local_output_shape, _ = localChunkSelection(global_output_shape, rank, dims)

    for i in n_layers:-1:1
        # Expand using the kernel
        global_kernel_shape = Tuple(layer_config[i, 2:4])

        # Raw shape == Actual if the layer is divisible bt the kernel
        raw_input_shape = local_output_shape .* global_kernel_shape
        local_input_start = local_output_start .* global_kernel_shape

        # Actual shape if first layer then input is the source gross input
        global_input_shape = i == 1 ? input_shape : Tuple(layer_config[i-1, 5:7])

        # Correct raw if the process takes an irregular chunk
        local_input_shape = min.(raw_input_shape, global_input_shape .- local_input_start)

        # Save layer
        pushfirst!(local_layers, LocalLayer(
            layer_config[i, 1],
            layer_config[i, 8],
            local_input_start,
            local_input_shape,
            local_output_start,
            local_output_shape,
            global_kernel_shape,
            Data.Array(undef, local_output_shape...)
        ))

        @debug local_output_start, local_output_shape
        local_output_shape = local_input_shape
        local_output_start = local_input_start
    end

    return local_layers
end


"""
  This is a very important function! It implements the slicing policy of the global domains to create the local domains
  the function works in 1D and is then vectorised to be used in 3D

 - pos : location of the process in this dimension
 - side_size : global size
 - nchunks : number of chunks in which this dimension is segmented
"""
function slicer1D(pos::Int, side_size::Int, nchunks)::Tuple{Int,Int,Int}

    @assert 0 <= pos < nchunks

    if side_size == 1
        return (0, 1, 1)
    end

    # V1 : perfect matching
    chunk_size = div(side_size, nchunks)
    last_chunk_size = chunk_size + mod(side_size, chunk_size)

    start = pos * chunk_size

    local _end
    if pos == (nchunks - 1)
        size = last_chunk_size
        _end = side_size
    else
        size = chunk_size
        _end = start + chunk_size
    end

    return (start, size, _end)

end


"""
  This function organizes ranks in a cartesian grid
"""
function dim_coord(rank :: Int,  dims :: Union{Tuple, Vector}) :: Tuple

    x = mod(rank, dims[1])
    if length(dims) == 1
        return (x,)
    end

    y = div(rank, dims[1])
    if length(dims) > 2
        y = mod(y, dims[1] * dims[2])
        z = div(rank, dims[1] * dims[2])
    else
        return x,y
    end

    return x,y,z
end

"""
  This is an utility function to transpose tuples.
"""
function transpose(tuple::NTuple{n,<:NTuple{m,<:Any}}) where {n,m}
    function getindexer(i::Int)
        coll -> coll[i]
    end
    ntuple(
        let t = tuple
            i -> map(getindexer(i), t)
        end,
        Val{m}()
    )
end


"""
  This is an utility function to calculate how the processed should be scattered across the domain, if the domain is sub-3D, some restrictions will be applied to not have several processes assigned into a collapsed dimension.
"""
function calculateDims(comm_size :: Int, input_shape)

    constraint = [dim > 1 ? 0 : 1 for dim in input_shape]

    return MPI.Dims_create(comm_size, constraint)
end
