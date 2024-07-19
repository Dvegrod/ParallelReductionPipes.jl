
"""
  Validates a pipeline configuration. True is returned if valid.
"""
function validatePipelineConfiguration(builder :: PipelineBuilder) :: Bool
    # TODO
    return true
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
    put!(adios_engine, var_dict[:var_shape], builder.input.var_shape)
    # TODO TYPE SHAPE
    put!(adios_engine, var_dict[:var_type], 0)

    # Set layer info (linea, non branching)
    # LAYER ENTRY = 7 Integers (operator id, kerx, kery, kerz, outx, outy, outz)
    layers = zeros(Int, 32, 7)
    n_layers = 0
    for layer :: Layer in builder.layers
        n_layers += 1
        layers[n_layers, 1] = layer.operator.id
        layers[n_layers, 2] = layer.kernel.dims[1]
        layers[n_layers, 3] = layer.kernel.dims[2]
        layers[n_layers, 4] = layer.kernel.dims[3]
        layers[n_layers, 5] = layer.output_shape[1]
        layers[n_layers, 6] = layer.output_shape[2]
        layers[n_layers, 7] = layer.output_shape[3]
    end

    put!(adios_engine, var_dict[:n_layers], n_layers)
    put!(adios_engine, var_dict[:layer_config], layers)



    err = perform_puts!(adios_engine)
    @assert err === error_none

    return
end


function build(builder::PipelineBuilder)

    adios = adios_init_serial()
    io = declare_io(adios, "COMM_IO")
    engine = open(io, "reducer.bp", mode_write)

    defineMetadata(io)

    definePipelineConfigurationStructure(io)

    vars = inquirePipelineConfigurationStructure(io)

    exportPipelineConfiguration(engine, vars, builder)

    _set(io, engine, :ready, 1)

    close(engine)
end
