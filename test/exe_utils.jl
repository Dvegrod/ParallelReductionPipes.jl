

@testset "Execution UTILS" begin

    @testset "Local Domain" begin

        a = Array{Float64}(undef, 100, 100)

        big = reducer.LocalDomain(a,
                                  (100, 0), (100, 100))

        small = reducer.transform(big, (10,10), Array{Float64}(undef, 10, 10))

        @test small.start == (10, 0)
        @test small.size == (10, 10)
    end

    @testset "Chunk Selection" begin
        @testset "1D regular" begin
	          rank = 0
            dims = (5,)
            shape = (100,)

            coords = reducer.localChunkSelection(shape, shape, rank, dims)

            @test coords[1] == (0,)
            @test coords[2] == (20,)
            @test coords[3] == (20,)
        end
        @testset "1D irregular" begin
	          rank = 2
            dims = (3,)
            shape = (100,)

            coords = reducer.localChunkSelection(shape, shape, rank, dims)

            @test coords[1] == (66,)
            @test coords[2] == (34,)
            @test coords[3] == (100,)
        end
        @testset "2D regular" begin
	          rank = 0
            dims = (5, 5)
            shape = (100, 100)

            coords = reducer.localChunkSelection(shape, shape, rank, dims)

            @test coords[1] == (0, 0)
            @test coords[2] == (20, 20)
            @test coords[3] == (20, 20)
        end
        @testset "3D regular" begin
	          rank = 0
            dims = (5, 5, 2)
            shape = (100, 100, 100)

            coords = reducer.localChunkSelection(shape, shape, rank, dims)

            @test coords[1] == (0, 0, 0)
            @test coords[2] == (20, 20, 50)
            @test coords[3] == (20, 20, 50)
        end
    end
end
