
@testset "Pipeline configuration tests" begin

    builder::ParallelReductionPipes.PipelineBuilder = ParallelReductionPipes.input("var_name", filename, "", [100, 100, 10], Float64)

    @testset "Builder tests" begin


        @testset "Input" begin

            @test builder.input.var_name == "var_name"
            @test builder.input.config_file == ""
            @test builder.input.var_shape == [100,100,10]

            @test_throws ErrorException ParallelReductionPipes.input("a","b", "", [], String)
        end

        # Check shapes get calculated correctly
        @testset "Layers" begin

            @test builder.layers == ParallelReductionPipes.Layer[]

            ker1 = ParallelReductionPipes.kernel([10, 10, 1])

            builder_a = ParallelReductionPipes.reduction(builder, ker1, :average)

            ker2 = ParallelReductionPipes.kernel([12, 12, 10])

            builder_b = ParallelReductionPipes.reduction(builder, ker2, 1)

            @test builder_a.layers[1].kernel.dims  == [10, 10, 1]
            @test builder_a.layers[1].output_shape == [10, 10, 10]

            @test builder_b.layers[1].output_shape == [9, 9]
            @test builder_b.layers[1].operator.name == "average"

        end
    end

    # Add one layer
    ker1 = ParallelReductionPipes.kernel([10, 10, 1])
    builder = ParallelReductionPipes.reduction(builder, ker1, :average)

    @testset "Serialization tests" begin

        @testset "WRITE" begin

            # Setup serial ADIOS2
            connection = ParallelReductionPipes.Connection(".", false, 30)

            a,i,e = ParallelReductionPipes.setup(connection)

            ParallelReductionPipes.definePipelineConfigurationStructure(i)

            vars = ParallelReductionPipes.inquirePipelineConfigurationStructure(i)

            for (key, var) in vars
                @test ParallelReductionPipes.var_repository[key].name == name(var)
            end

            # Write configuration
            ParallelReductionPipes.exportPipelineConfiguration(e, vars, builder)

            close(e)
            finalize(a)
        end

        #run(`bpls -d $filename`)

        @testset "READ" begin

            # Setup serial ADIOS2
            connection = ParallelReductionPipes.Connection(".", true, 30)
            a,i,e = ParallelReductionPipes.connect(connection)

            vars = ParallelReductionPipes.inquirePipelineConfigurationStructure(i)

            for (key, var) in vars
                @test ParallelReductionPipes.var_repository[key].name == name(var)
            end

            vals = ParallelReductionPipes.getPipelineConfigurationStructure(e, vars)


            @test vals[:var_name] == "var_name"
            @test vals[:uses_config] == 0
            @test vals[:var_type] == 0
            @test vals[:n_layers] == 1
            @test vals[:layer_config][1,:] == [1, 10, 10, 1, 10, 10, 10, 0]

            close(e)
            finalize(a)
        end
    end

end

