


function inflateConfiguration(io :: ADIOS2.AIO, engine :: ADIOS2.Engine) :: PipelineBuilder

    vars = reducer.inquirePipelineConfigurationStructure(io)
    vals = reducer.getPipelineConfigurationStructure(engine, vars)

end
