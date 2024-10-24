using ContingencyTables
using Test
using DataFrames
using CategoricalArrays

@testset "ContingencyTables.jl" begin
    @testset "Single Vector - Basic Functionality" begin
        # Basic counting
        x = [1, 2, 2, 3, 3, 3]
        result = ContingencyTable(x)
        @test result.counts.Value == [1, 2, 3]
        @test result.counts.Count == [1, 2, 3]
        @test result.weights_used == false

        # Test sorting
        x = [3, 1, 2, 1, 3]
        result = ContingencyTable(x)
        @test result.counts.Value == [1, 2, 3]
        @test result.counts.Count == [2, 1, 2]
    end

    @testset "Single Vector - Categorical Data" begin
        # Ordered categorical
        x = categorical([1, 3, 3, 2], ordered=true)
        result = ContingencyTable(x)
        @test result.counts.Value == [1, 2, 3]
        @test result.counts.Count == [1, 1, 2]
        @test result.ordered[1] == true

        # Unordered categorical with strings
        x = categorical(["B", "A", "C", "A"], ordered=false)
        result = ContingencyTable(x)
        @test result.counts.Value == ["A", "B", "C"]
        @test result.counts.Count == [2, 1, 1]
        @test result.ordered[1] == false

        # Custom levels order
        x = categorical(["B", "A", "C", "A"], levels=["C", "A", "B"])
        result = ContingencyTable(x)
        @test result.counts.Value == ["C", "A", "B"]
        @test result.counts.Count == [1, 2, 1]
    end

    @testset "Single Vector - Missing Values" begin
        # Basic with missing
        x = [1, 2, missing, 2, missing]
        result = ContingencyTable(x)
        @test result.counts.Value == [1, 2, "missing"]
        @test result.counts.Count == [1, 2, 2]

        # Categorical with missing
        x = categorical([1, missing, 2, missing, 2], ordered=true)
        result = ContingencyTable(x)
        @test "missing" in result.counts.Value
        @test sum(result.counts.Count) == 5

        # Skip missing
        result = ContingencyTable(x, skipmissing=true)
        @test !("missing" in result.counts.Value)
        @test sum(result.counts.Count) == 3
    end

    @testset "Single Vector - Weights" begin
        x = [1, 2, 2, 3]
        weights = [2.0, 1.0, 2.0, 1.0]
        result = ContingencyTable(x, weights=weights)
        @test result.weights_used == true
        @test result.counts.Count == [2.0, 3.0, 1.0]

        # Categorical with weights
        x = categorical(["A", "B", "B"], ordered=true)
        weights = [2.0, 1.0, 2.0]
        result = ContingencyTable(x, weights=weights)
        @test result.weights_used == true
        @test result.counts.Count == [2.0, 3.0]
    end

    @testset "Two Vectors - Basic Functionality" begin
        x1 = [1, 2, 2, 3]
        x2 = ["A", "B", "A", "B"]
        result = ContingencyTable(x1, x2)
        @test size(result.counts) == (3, 3)  # 3 rows (including Row column) × 3 columns
        @test names(result.counts)[2:end] == ["A", "B"]  # Column names

        # Test sorting in both dimensions
        x1 = [3, 1, 2, 1]
        x2 = ["C", "A", "B", "A"]
        result = ContingencyTable(x1, x2)
        @test result.counts.Row == [1, 2, 3]
        @test names(result.counts)[2:end] == ["A", "B", "C"]
    end

    @testset "Two Vectors - Categorical Data" begin
        # Both categorical
        x1 = categorical([1, 2, 2, 3], ordered=true)
        x2 = categorical(["A", "B", "A", "B"], ordered=false)
        result = ContingencyTable(x1, x2)
        @test result.ordered[1] == true
        @test result.ordered[2] == false

        # Mixed categorical and regular
        x1 = categorical(["X", "Y", "X"], ordered=true)
        x2 = [1, 2, 1]
        result = ContingencyTable(x1, x2)
        @test result.ordered[1] == true
    end

    @testset "Two Vectors - Missing Values" begin
        x1 = [1, 2, missing, 2]
        x2 = ["A", missing, "B", "B"]
        result = ContingencyTable(x1, x2)
        @test "missing_1" in result.counts.Row
        @test "missing_2" in names(result.counts)

        # Skip missing
        result = ContingencyTable(x1, x2, skipmissing=true)
        @test !("missing" in result.counts.Row)
        @test !("missing" in names(result.counts))
    end

    @testset "DataFrame Interface" begin
        df = DataFrame(
            A=[1, 2, 2, 3],
            B=["X", "Y", "X", "Y"],
            W=[1.0, 2.0, 1.0, 1.0]
        )

        # Single column
        result = ContingencyTable(df, :A)
        @test result.counts.Value == [1, 2, 3]

        # Two columns
        result = ContingencyTable(df, :A, :B)
        @test size(result.counts) == (3, 3)

        # With weights column
        result = ContingencyTable(df, :A, weights=:W)
        @test result.weights_used == true
    end

    @testset "Error Handling" begin
        # Empty input
        @test_throws ArgumentError ContingencyTable(Int[])

        # Mismatched weights length
        @test_throws ArgumentError ContingencyTable([1, 2, 3], weights=[1, 2])

        # Negative weights
        @test_throws ArgumentError ContingencyTable([1, 2, 3], weights=[-1, 1, 1])

        # Mismatched vector lengths
        @test_throws ArgumentError ContingencyTable([1, 2], ["A"])
    end
end