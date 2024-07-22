
struct LocalDomain
    data :: Array
    start :: Tuple
    size :: Tuple
end

function transform(big_domain :: LocalDomain, kernel :: Tuple, buffer :: Array) :: LocalDomain

    new_start = div.(big_domain.start, kernel)
    new_size = div.(big_domain.size, kernel)

    return LocalDomain(buffer, new_start,  new_size)
end


function localChunkSelection(sh :: Tuple, ker:: Tuple, rank :: Int, dims :: Union{Tuple, Vector})

    @assert 0 < length(dims) <= 3

    pcoords = dim_coord(rank, dims)

    dcoords = Tuple(slicer1D.(pcoords, sh, ker, dims))

    @show dcoords

    tdcoords = transpose(dcoords)

    return tdcoords
end

"""
  pos : location of the process in this dimension
  side_size : global size
  nchunks : number of chunks in which this dimension is segmented
"""
function slicer1D(pos::Int, side_size::Int, ker :: Int, nchunks)::Tuple{Int,Int,Int}

    @assert 0 <= pos < nchunks

    @static slice_mode == :v1 ? begin
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
    end : begin end

    @static slice_mode == :v2 ? begin
        # V2 : domain might not be divisible by kernel
        # EXAMPLE:
        # Size: 9
        # Ker : 2
        # Nchunks: 3
        #
        # O = element K = kernel number = chunk#
        #
        # OO OO OO OO O
        # K  K  K  K  K
        # 1  1  2  2  3

        out_size = div(side_size, ker, RoundUp)
        chunk_size = div(out_size, nchunks, RoundUp) * ker

        start = pos * chunk_size

        local _end
        if pos == (nchunks - 1)
            last_ker_size = mod1(side_size, ker)
            last_chunk_size = mod1(out_size, nchunks) * ker - ker + last_ker_size

            size = last_chunk_size
            _end = side_size
        else
            size = chunk_size
            _end = start + chunk_size
        end

        return (start, size, _end)
    end : begin end
end


"""
  Organizes ranks in a cartesian grid
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
