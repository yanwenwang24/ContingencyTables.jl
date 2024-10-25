using ContingencyTables
using Test
using DataFrames
using CategoricalArrays

@testset "ContingencyTables.jl" begin
    @testset "ContingencyTable" begin
        @testset "Single Vector" begin
            # Basic functionality
            x = [1, 2, 2, 3, 3, 3]
            ct = ContingencyTable(x)
            @test size(ct.counts) == (3, 2)
            @test sum(ct.counts.Count) == 6
            @test ct.counts.Count == [1, 2, 3]

            # Categorical array
            cat_x = categorical([1, 2, 2, 3, 3, 3], ordered=true)
            ct_cat = ContingencyTable(cat_x)
            @test isordered(cat_x)
            @test ct_cat.ordered[1] == true
            @test ct_cat.levels[1] == levels(cat_x)

            # Missing values
            x_missing = [1, 2, missing, 2, 3, missing]
            ct_missing = ContingencyTable(x_missing)
            @test size(ct_missing.counts) == (4, 2)
            @test "missing" in ct_missing.counts.Value

            ct_skipmissing = ContingencyTable(x_missing, skipmissing=true)
            @test size(ct_skipmissing.counts) == (3, 2)
            @test !("missing" in ct_skipmissing.counts.Value)

            # Weights
            weights = [1.0, 2.0, 1.5, 0.5, 1.0, 2.0]
            ct_weighted = ContingencyTable(x, weights=weights)
            @test ct_weighted.weights_used == true
            @test ct_weighted.count_type == Float64
            @test sum(ct_weighted.counts.Count) ≈ sum(weights)

            # Error cases
            @test_throws ArgumentError ContingencyTable(Int[])  # Empty vector
            @test_throws ArgumentError ContingencyTable(x, weights=weights[1:end-1])  # Mismatched weights length
            @test_throws ArgumentError ContingencyTable(x, weights=[-1.0, 1.0, 1.0, 1.0, 1.0, 1.0])  # Negative weights
        end

        @testset "Two Vectors" begin
            x1 = [1, 2, 2, 3]
            x2 = ["a", "b", "b", "a"]

            # Basic functionality
            ct = ContingencyTable(x1, x2)
            @test size(ct.counts) == (3, 3)  # 3 rows (including Row names) × 3 columns
            @test names(ct.counts)[2:end] == ["a", "b"]  # Column names

            # Categorical arrays
            cat_x1 = categorical(x1, ordered=true)
            cat_x2 = categorical(x2)
            ct_cat = ContingencyTable(cat_x1, cat_x2)
            @test ct_cat.ordered[1] == true
            @test ct_cat.ordered[2] == false
            @test ct_cat.levels[1] == levels(cat_x1)
            @test ct_cat.levels[2] == levels(cat_x2)

            # Missing values
            x1_missing = [1, 2, missing, 2]
            x2_missing = ["a", missing, "b", "b"]
            ct_missing = ContingencyTable(x1_missing, x2_missing)
            @test size(ct_missing.counts) == (3, 4)  # Including "missing" row and column

            ct_skipmissing = ContingencyTable(x1_missing, x2_missing, skipmissing=true)
            @test size(ct_skipmissing.counts) == (2, 3)

            # Weights
            weights = [1.0, 2.0, 1.5, 0.5]
            ct_weighted = ContingencyTable(x1, x2, weights=weights)
            @test ct_weighted.weights_used == true
            @test sum(Matrix(ct_weighted.counts[:, 2:end])) ≈ sum(weights)

            # Error cases
            @test_throws ArgumentError ContingencyTable(x1, x2[1:end-1])  # Mismatched lengths
            @test_throws ArgumentError ContingencyTable(Int[], String[])  # Empty vectors
        end
    end

    @testset "ProportionTble" begin
        @testset "Single Vector" begin
            x = [1, 2, 2, 3, 3, 3]

            # Basic functionality
            pt = ProportionTable(x)
            @test sum(pt.proportions.Proportion) ≈ 1.0
            @test pt.proportions.Proportion ≈ [1 / 6, 2 / 6, 3 / 6]

            # From ContingencyTable
            ct = ContingencyTable(x)
            pt_from_ct = ProportionTable(ct)
            @test pt_from_ct.proportions ≈ pt.proportions

            # Missing values
            x_missing = [1, 2, missing, 2, 3, missing]
            pt_missing = ProportionTable(x_missing)
            @test sum(pt_missing.proportions.Proportion) ≈ 1.0

            # Weights
            weights = [1.0, 2.0, 1.5, 0.5, 1.0, 2.0]
            pt_weighted = ProportionTable(x, weights=weights)
            @test sum(pt_weighted.proportions.Proportion) ≈ 1.0
        end

        @testset "Two Vectors" begin
            x1 = [1, 2, 2, 3]
            x2 = ["a", "b", "b", "a"]

            # Total proportions
            pt = ProportionTable(x1, x2)
            @test sum(Matrix(pt.proportions[:, 2:end])) ≈ 1.0

            # Row proportions
            pt_row = ProportionTable(x1, x2, dims=:row)
            @test all(sum(Matrix(pt_row.proportions[:, 2:end]), dims=2) .≈ 1.0)

            # Column proportions
            pt_col = ProportionTable(x1, x2, dims=:col)
            @test all(sum(Matrix(pt_col.proportions[:, 2:end]), dims=1) .≈ 1.0)

            # From ContingencyTable
            ct = ContingencyTable(x1, x2)
            pt_from_ct = ProportionTable(ct, dims=:row)
            @test pt_from_ct.proportions == pt_row.proportions

            # Error cases
            @test_throws ArgumentError ProportionTable(x1, x2, dims=:invalid)
        end

        @testset "DataFrame Interface" begin
            df = DataFrame(
                A=[1, 2, 2, 3, 3, 3],
                B=["a", "b", "b", "a", "c", "c"],
                W=[1.0, 2.0, 1.5, 0.5, 1.0, 2.0]
            )

            # Single column
            ct_single = ContingencyTable(df, :A)
            @test size(ct_single.counts) == (3, 2)

            pt_single = ProportionTable(df, :A)
            @test sum(pt_single.proportions.Proportion) ≈ 1.0

            # Two columns
            ct_two = ContingencyTable(df, :A, :B)
            @test size(ct_two.counts) == (3, 4)

            # With weights column
            ct_weighted = ContingencyTable(df, :A, :B, weights=:W)
            @test ct_weighted.weights_used == true

            pt_weighted = ProportionTable(df, :A, :B, weights=:W, dims=:row)
            @test all(sum(Matrix(pt_weighted.proportions[:, 2:end]), dims=2) .≈ 1.0)
        end
    end

    @testset "ExpectedFrequency" begin
        @testset "Basic 2×2 Table" begin
            # Simple 2×2 table with equal frequencies
            x1 = repeat(["A", "B"], outer=4)
            x2 = repeat([1, 2], inner=4)
            ct = ContingencyTable(x1, x2)
            expected = ExpectedFrequency(ct)

            # Test dimensions and structure
            @test size(expected) == size(ct.counts)
            @test names(expected) == names(ct.counts)
            @test expected.Row == ct.counts.Row

            # Test expected values for balanced design
            exp_mat = Matrix(expected[:, 2:end])
            @test all(isapprox.(exp_mat, 2.0))  # All cells should have expected frequency of 4
        end

        @testset "Unbalanced Table" begin
            # Unbalanced frequencies
            x1 = ["A", "A", "A", "B"]
            x2 = [1, 1, 2, 2]
            ct = ContingencyTable(x1, x2)
            expected = ExpectedFrequency(ct)

            # Test row and column totals
            obs_mat = Matrix(ct.counts[:, 2:end])
            exp_mat = Matrix(expected[:, 2:end])

            @test sum(obs_mat) ≈ sum(exp_mat)  # Same total
            @test all(sum(obs_mat, dims=1) .≈ sum(exp_mat, dims=1))  # Same column totals
            @test all(sum(obs_mat, dims=2) .≈ sum(exp_mat, dims=2))  # Same row totals
        end

        @testset "Categorical Data" begin
            # Test with categorical vectors
            x1 = categorical(["A", "A", "B", "B"], ordered=true)
            x2 = categorical([1, 2, 1, 2], ordered=true)
            ct = ContingencyTable(x1, x2)
            expected = ExpectedFrequency(ct)

            # Test that categorical ordering is preserved
            @test expected.Row == ct.counts.Row
            @test names(expected) == names(ct.counts)

            # Test expected frequency properties
            exp_mat = Matrix(expected[:, 2:end])
            @test all(exp_mat .≈ 1.0)  # Should be uniform for this balanced design
        end

        @testset "Missing Values" begin
            # Test with missing values
            x1 = ["A", missing, "B", "B", missing]
            x2 = ["X", "Y", missing, "Y", "X"]
            ct = ContingencyTable(x1, x2)
            expected = ExpectedFrequency(ct)

            # Check structure
            @test size(expected) == size(ct.counts)
            @test "missing" in expected.Row

            # Test totals including missing category
            obs_mat = Matrix(ct.counts[:, 2:end])
            exp_mat = Matrix(expected[:, 2:end])
            @test sum(obs_mat) ≈ sum(exp_mat)
        end

        @testset "Larger Tables" begin
            # Test with 3×3 table
            x1 = repeat(["A", "B", "C"], outer=3)
            x2 = repeat([1, 2, 3], inner=3)
            ct = ContingencyTable(x1, x2)
            expected = ExpectedFrequency(ct)

            # Test dimensions
            @test size(expected) == size(ct.counts)

            # Test expected frequency properties
            exp_mat = Matrix(expected[:, 2:end])
            @test all(isapprox.(exp_mat, 1.0))  # Should be uniform for this balanced design
        end

        @testset "Zero Frequencies" begin
            # Test with some zero frequencies
            x1 = ["A", "A", "B"]
            x2 = [1, 1, 2]
            ct = ContingencyTable(x1, x2)
            expected = ExpectedFrequency(ct)

            # Check that expected frequencies are computed correctly
            exp_mat = Matrix(expected[:, 2:end])
            @test all(exp_mat .>= 0)  # Expected frequencies should be non-negative
            @test !any(isnan.(exp_mat))  # Should not produce NaN values
        end




    end

    @testset "Edge Cases" begin
        # Single observation
        x1 = ["A"]
        x2 = [1]
        ct = ContingencyTable(x1, x2)
        expected = ExpectedFrequency(ct)
        @test size(expected) == size(ct.counts)

        # All same category
        x1 = fill("A", 5)
        x2 = fill(1, 5)
        ct = ContingencyTable(x1, x2)
        expected = ExpectedFrequency(ct)
        @test Matrix(expected[:, 2:end])[1, 1] ≈ 5.0

        # Degenerate case with single category in one variable
        x1 = ["A", "A", "A"]
        x2 = [1, 2, 3]
        ct = ContingencyTable(x1, x2)
        expected = ExpectedFrequency(ct)
        @test size(expected) == size(ct.counts)
    end

    @testset "Properties of Expected Frequencies" begin
        # Create an arbitrary table
        x1 = repeat(["A", "B"], outer=3)
        x2 = repeat([1, 2, 3], inner=2)
        ct = ContingencyTable(x1, x2)
        expected = ExpectedFrequency(ct)

        obs_mat = Matrix(ct.counts[:, 2:end])
        exp_mat = Matrix(expected[:, 2:end])

        # Test fundamental properties of expected frequencies
        @test sum(obs_mat) ≈ sum(exp_mat)  # Total sum preserved
        @test all(sum(obs_mat, dims=1) .≈ sum(exp_mat, dims=1))  # Column sums preserved
        @test all(sum(obs_mat, dims=2) .≈ sum(exp_mat, dims=2))  # Row sums preserved
        @test all(exp_mat .>= 0)  # Non-negative values
    end
end