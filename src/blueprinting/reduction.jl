

"""
  Calculates the output shape of applying a window/kernel to an input shape.
"""
function sizeTransform(input_shape :: Vector{Int}, kernel :: Kernel) :: Tuple{Vector{Int},Vector{Int}}
    if length(kernel.dims) != length(input_shape)
        throw(DimensionMismatch("The kernel and the input have different dimensions: K: $(kernel.dims) IN: $(input_shape)"))
    end
    new_dims = Int[]
    remainders = Int[]
    for (i_dim, k_dim) in zip(input_shape, kernel.dims)
        # If ALL the kernel encompasses the whole span
        if k_dim == ALL
            k_dim = i_dim
        end
        # Divide and ceil
        new = cld(i_dim, k_dim)
        remainder = rem(i_dim, k_dim)
        # If the dimension collapses,forget the dimension
        if new == 1 && length(input_shape) > 1
        else
            push!(new_dims, new)
        end
        push!(remainders, remainder)
    end

    return new_dims, remainders
end


"""
Designs a data reduction layer to be added to a pipeline builder

This layer has:
 - A operator: specifies which reduction operation to use
 - A kernel/window: specifies how many cells in each direction collapse into one

 An error will occur during the building process if the layer is incompatible either by (usually):
 - Size mismatch
 - Type mismatch

# Arguments
 - `pipeline` the pipe where the layer is going to take the input
 - `kernel` the window of the layer
 - `operator` the identifier (ID, Symbol or name) of a reduction operator of the layer (e.g. 1, :average, "average" all correspond to the same operator)
"""
function reduction(pipeline :: PipelineBuilder, kernel :: Union{Tuple{Int}, Kernel}, operator :: Union{Symbol,String,Int})
    # Get input size
    if isempty(pipeline.layers)
        output_shape = pipeline.input.var_shape
    else
        output_shape = pipeline.layers[end].output_shape
    end

    if kernel isa Tuple
        kernel = Kernel(kernel, false)
    end

    # Calculate output size
    output_size, rems = sizeTransform(output_shape, kernel)

    # Parse operator
    op = parseOperator(operator)

    new = Layer(
        kernel,
        op,
        output_size,
        rems
    )

    appended = push!(copy(pipeline.layers), new)

    return PipelineBuilder(
        pipeline.input,
        appended,
        pipeline.process_space_size
    )
end
