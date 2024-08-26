
"""
  Validates a pipeline configuration. True is returned if valid.
"""
function validatePipelineConfiguration(builder :: PipelineBuilder) :: Bool
    # TODO
    return true
end

function serializeShape(shape :: Vector{Int}, buffer_view)

    i = 0
    for e in shape
        i += 1
        buffer_view[i] = e
    end

    return buffer_view
end

"""
  Sets the configuration into the communication channel with the reducer process for it to receive it
"""
function exportPipelineConfiguration(adios_engine :: ADIOS2.Engine,
                                     var_dict :: Dict{Symbol, ADIOS2.Variable},
                                     builder :: PipelineBuilder)

    # Set input parameters
    put!(adios_engine, var_dict[:engine], builder.input.engine_name)
    put!(adios_engine, var_dict[:var_name], builder.input.var_name)
    put!(adios_engine, var_dict[:uses_config], Int(builder.input.config_file != ""))
    put!(adios_engine, var_dict[:config], builder.input.config_file)

    var_shape = serializeShape(builder.input.var_shape, ones(Int, 3))
    put!(adios_engine, var_dict[:var_shape], var_shape)
    # TODO TYPE SHAPE
    put!(adios_engine, var_dict[:var_type], 0)

    # Set layer info (linea, non branching)
    # LAYER ENTRY = 7 Integers (operator id, kerx, kery, kerz, outx, outy, outz)
    layers = ones(Int, 32, 7)
    n_layers = 0
    for layer :: Layer in builder.layers
        n_layers += 1
        layers[n_layers, 1] = layer.operator.id

        serializeShape(layer.kernel.dims, view(layers, n_layers, 2:4))
        serializeShape(layer.output_shape, view(layers, n_layers, 5:7))
    end

    put!(adios_engine, var_dict[:n_layers], n_layers)
    put!(adios_engine, var_dict[:layer_config], layers)


    err = perform_puts!(adios_engine)
    @assert err === error_none

    return
end

# TODO CAN BE MERGED WITH LISTEN
# function checkReady(io::ADIOS2.AIO, engine::ADIOS2.Engine)::Bool
#     bool = false
#     for _ in 1:100
#         config_ready = _get(io, engine, :exec_ready)

#         @show config_ready

#         if config_ready !== nothing && config_ready > 0
#             bool = true
#             break
#         end
#     end
#     return bool
# end



function build(builder::PipelineBuilder, custom)

    path = "."

    c = Connection(path, false, 30)

    ready = _get(c, :exec_ready)
    @info "runtime detected ready = $ready"

    aw,iw,ew = setup(c)
    defineMetadata(iw)
    definePipelineConfigurationStructure(iw)
    vars = inquirePipelineConfigurationStructure(iw)
    exportPipelineConfiguration(ew, vars, builder)

    if custom !== nothing
        _set(iw, ew, metadata[:custom], custom)
    end

    _set(iw, ew, metadata[:ready], 1)

    close(ew)
end
