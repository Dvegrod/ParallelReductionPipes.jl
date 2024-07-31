
@testset "Pipeline configuration tests" begin

    builder::reducer.PipelineBuilder = reducer.input("var_name", filename, "", [100, 100, 10], Float64)

    @testset "Builder tests" begin


        @testset "Input" begin

            @test builder.input.var_name == "var_name"
            @test builder.input.config_file == ""
            @test builder.input.var_shape == [100,100,10]

            @test_throws ErrorException reducer.input("a","b", "", [], String)
        end

        # Check shapes get calculated correctly
        @testset "Layers" begin

            @test builder.layers == reducer.Layer[]

            ker1 = reducer.kernel([10, 10, 1])

            builder_a = reducer.reduction(builder, ker1, :average)

            ker2 = reducer.kernel([12, 12, 10])

            builder_b = reducer.reduction(builder, ker2, 1)

            @test builder_a.layers[1].kernel.dims  == [10, 10, 1]
            @test builder_a.layers[1].output_shape == [10, 10, 10]

            @test builder_b.layers[1].output_shape == [9, 9]
            @test builder_b.layers[1].operator.name == "average"

        end
    end

    # Add one layer
    ker1 = reducer.kernel([10, 10, 1])
    builder = reducer.reduction(builder, ker1, :average)

    @testset "Serialization tests" begin

        @testset "WRITE" begin

            # Setup serial ADIOS2
            adios   = adios_init_serial()
            testIO  = declare_io(adios, "testIO")
            testENG = open(testIO, builder.input.engine_name, mode_write)

            reducer.definePipelineConfigurationStructure(testIO)

            vars = reducer.inquirePipelineConfigurationStructure(testIO)

            for (key, var) in vars
                @test reducer.var_repository[key].name == name(var)
            end

            # Write configuration
            reducer.exportPipelineConfiguration(testENG, vars, builder)

            close(testENG)
            finalize(adios)
        end

        #run(`bpls -d $filename`)

        @testset "READ" begin

            # Setup serial ADIOS2
            adios = adios_init_serial()
            testIO = declare_io(adios, "testIO")
            testENG = open(testIO, filename, mode_readRandomAccess)

            vars = reducer.inquirePipelineConfigurationStructure(testIO)

            for (key, var) in vars
                @test reducer.var_repository[key].name == name(var)
            end

            vals = reducer.getPipelineConfigurationStructure(testENG, vars)


            @test vals[:var_name] == "var_name"
            @test vals[:uses_config] == 0
            @test vals[:var_type] == 0
            @test vals[:n_layers] == 1
            @test vals[:layer_config][1,:] == [1, 10, 10, 1, 10, 10, 10]

            close(testENG)
            finalize(adios)
        end
    end

end

