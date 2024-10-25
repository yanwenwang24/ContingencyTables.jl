using ContingencyTables
using Test
using DataFrames
using CategoricalArrays

@testset "ContingencyTables.jl" begin
    @testset "ContingencyTable - Single Variable" begin
        # Basic functionality
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
        
        # Categorical data
        x = categorical(["A", "B", "B", "C"], ordered=true)
        result = ContingencyTable(x)
        @test result.counts.Value == ["A", "B", "C"]
        @test result.counts.Count == [1, 2, 1]
        @test result.ordered[1] == true
        
        # With missing values
        x = [1, missing, 2, missing, 2]
        result = ContingencyTable(x)
        @test "missing" in result.counts.Value
        @test sum(result.counts.Count) == 5
        
        result_skip = ContingencyTable(x, skipmissing=true)
        @test !("missing" in result_skip.counts.Value)
        @test sum(result_skip.counts.Count) == 3
        
        # With weights
        x = [1, 2, 2, 3]
        weights = [2.0, 1.0, 2.0, 1.0]
        result = ContingencyTable(x, weights=weights)
        @test result.weights_used == true
        @test result.counts.Count == [2.0, 3.0, 1.0]
    end

    @testset "ContingencyTable - Two Variables" begin
        # Basic functionality
        x1 = [1, 2, 2, 3]
        x2 = ["A", "B", "A", "B"]
        result = ContingencyTable(x1, x2)
        @test size(result.counts) == (3, 3) 
        @test names(result.counts)[2:end] == ["A", "B"]
        
        # Mixed types with categorical
        x1 = categorical(["X", "Y", "X"], ordered=true)
        x2 = [1, 2, 1]
        result = ContingencyTable(x1, x2)
        @test result.ordered[1] == true
        
        # With missing values
        x1 = [1, missing, 2, 2]
        x2 = ["A", "B", missing, "B"]
        result = ContingencyTable(x1, x2)
        @test "missing" in result.counts.Row
        @test "missing" in names(result.counts)
        
        result_skip = ContingencyTable(x1, x2, skipmissing=true)
        @test !("missing" in result_skip.counts.Row)
        @test !("missing" in names(result_skip.counts))
        
        # With weights
        x1 = ["A", "B", "B"]
        x2 = [1, 2, 2]
        weights = [2.0, 1.0, 2.0]
        result = ContingencyTable(x1, x2, weights=weights)
        @test result.weights_used == true
    end

    @testset "ProportionTable - Single Variable" begin
        # Basic proportions
        x = [1, 2, 2, 3, 3, 3]
        result = ProportionTable(x)
        @test sum(result.proportions.Proportion) ≈ 1.0
        @test result.dimension === nothing
        @test eltype(result.proportions.Proportion) == Float64
        
        # From ContingencyResults
        ct = ContingencyTable(x)
        result = ProportionTable(ct)
        @test sum(result.proportions.Proportion) ≈ 1.0
        
        # Categorical data
        x = categorical(["A", "B", "B", "C"], ordered=true)
        result = ProportionTable(x)
        @test sum(result.proportions.Proportion) ≈ 1.0
        @test result.ordered[1] == true
        
        # With missing values
        x = [1, missing, 2, missing, 2]
        result = ProportionTable(x)
        @test sum(result.proportions.Proportion) ≈ 1.0
        @test "missing" in result.proportions.Value
        
        result_skip = ProportionTable(x, skipmissing=true)
        @test sum(result.proportions.Proportion) ≈ 1.0
        @test !("missing" in result_skip.proportions.Value)
        
        # With weights
        x = ["A", "B", "B"]
        weights = [2.0, 1.0, 2.0]
        result = ProportionTable(x, weights=weights)
        @test sum(result.proportions.Proportion) ≈ 1.0
        @test result.proportions[result.proportions.Value .== "B", :Proportion][1] ≈ 0.6
    end

    @testset "ProportionTable - Two Variables" begin
        # Basic functionality
        x1 = [1, 2, 2, 3]
        x2 = ["A", "B", "A", "B"]
        
        # Total proportions
        result = ProportionTable(x1, x2)
        @test sum(Matrix(result.proportions[:, 2:end])) ≈ 1.0
        @test result.dimension === nothing
        @test eltype(Matrix(result.proportions[:, 2:end])) == Float64
        
        # Row proportions
        result = ProportionTable(x1, x2, dims=:row)
        @test all(sum(Matrix(result.proportions[:, 2:end]), dims=2) .≈ 1.0)
        @test result.dimension === :row
        
        # Column proportions
        result = ProportionTable(x1, x2, dims=:col)
        @test all(sum(Matrix(result.proportions[:, 2:end]), dims=1) .≈ 1.0)
        @test result.dimension === :col
        
        # From ContingencyResults
        ct = ContingencyTable(x1, x2)
        for dims in [nothing, :row, :col]
            result = ProportionTable(ct, dims=dims)
            if isnothing(dims)
                @test sum(Matrix(result.proportions[:, 2:end])) ≈ 1.0
            elseif dims == :row
                @test all(sum(Matrix(result.proportions[:, 2:end]), dims=2) .≈ 1.0)
            else
                @test all(sum(Matrix(result.proportions[:, 2:end]), dims=1) .≈ 1.0)
            end
        end
        
        # Mixed types with categorical
        x1 = categorical(["X", "Y", "X"], ordered=true)
        x2 = [1, 2, 1]
        result = ProportionTable(x1, x2, dims=:row)
        @test result.ordered[1] == true
        @test all(sum(Matrix(result.proportions[:, 2:end]), dims=2) .≈ 1.0)
        
        # With missing values
        x1 = [1, missing, 2, 2]
        x2 = ["A", "B", missing, "B"]
        result = ProportionTable(x1, x2)
        @test sum(Matrix(result.proportions[:, 2:end])) ≈ 1.0
        @test "missing" in result.proportions.Row
        
        result_skip = ProportionTable(x1, x2, skipmissing=true)
        @test sum(Matrix(result_skip.proportions[:, 2:end])) ≈ 1.0
        @test !("missing" in result_skip.proportions.Row)
    end

    @testset "Error Handling" begin
        # Empty input
        @test_throws ArgumentError ContingencyTable(Int[])
        @test_throws ArgumentError ProportionTable(Int[])
        
        # Invalid dimensions
        x1 = [1, 2, 2]
        x2 = ["A", "B", "B"]
        @test_throws ArgumentError ProportionTable(x1, x2, dims=:invalid)
        
        # Mismatched weights length
        @test_throws ArgumentError ContingencyTable(x1, weights=[1.0, 2.0])
        @test_throws ArgumentError ProportionTable(x1, weights=[1.0, 2.0])
        
        # Negative weights
        @test_throws ArgumentError ContingencyTable(x1, weights=[-1.0, 1.0, 1.0])
        @test_throws ArgumentError ProportionTable(x1, weights=[-1.0, 1.0, 1.0])
        
        # Mismatched vector lengths
        @test_throws ArgumentError ContingencyTable([1,2], ["A"])
        @test_throws ArgumentError ProportionTable([1,2], ["A"])
    end
end