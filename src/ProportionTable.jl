"""
    ProportionTable(x; skipmissing=false, weights=nothing)
    ProportionTable(df::DataFrame, col::Symbol; skipmissing=false, weights=nothing)
    ProportionTable(x1, x2; skipmissing=false, weights=nothing, dims=nothing)
    ProportionTable(df::DataFrame, col1::Symbol, col2::Symbol; skipmissing=false, weights=nothing, dims=nothing)
    ProportionTable(ct::ContingencyResults; dims=nothing)

Create a proportion table from input data or a ContingencyResults object, calculating relative frequencies 
or conditional probabilities.

# Arguments
- `x`, `x1`, `x2`: Vectors or CategoricalArrays of observations to analyze
- `df`: DataFrame containing the columns to analyze
- `col`, `col1`, `col2`: Column symbols from the DataFrame
- `ct`: ContingencyResults object from ContingencyTable()
- `skipmissing=false`: Whether to exclude missing values from calculations
- `weights=nothing`: Optional weights for observations. Can be:
    - A vector of numerical weights
    - A Symbol referring to a weights column in the DataFrame
- `dims=nothing`: Dimension for proportion calculation:
    - `nothing`: total proportions (each cell divided by grand total)
    - `:row`: row proportions (each cell divided by row total)
    - `:col`: column proportions (each cell divided by column total)

# Returns
- `ProportionResults` object containing:
    - proportions::DataFrame: Calculated proportions in table format
    - dimension::Union{Nothing,Symbol}: Dimension used for calculations
    - value_type::Type: Type of the input values
    - count_type::Type: Always Float64 for proportions
    - levels::Dict: Maps dimensions to their categorical levels (if any)
    - ordered::Dict: Maps dimensions to their ordering status

# Details
- For single variables:
    - Calculates simple proportions (frequency / total)
    - dims parameter is ignored as only total proportions make sense
- For two variables:
    - Can calculate joint probabilities (dims=nothing)
    - Can calculate conditional probabilities (dims=:row or :col)
    - Maintains original categorical levels and ordering if present

# [Examples](@id examples)
```julia
# Simple proportions for a single vector
x = [1, 2, 2, 3, 3, 3]
prop_table = ProportionTable(x)
println(prop_table.proportions)  # Shows proportion for each value

# From existing contingency table
ct = ContingencyTable(x)
prop_table = ProportionTable(ct)

# Two categorical variables with different proportion types
using CategoricalArrays
x1 = categorical(["A", "B", "A", "C"])
x2 = [1, 2, 1, 3]

# Joint probabilities (total proportions)
prop_joint = ProportionTable(x1, x2)

# Conditional probabilities (row proportions)
prop_row = ProportionTable(x1, x2, dims=:row)  # P(x2|x1)

# Conditional probabilities (column proportions)
prop_col = ProportionTable(x1, x2, dims=:col)  # P(x1|x2)

# With weights
weights = [1.0, 2.0, 0.5, 1.5]
prop_weighted = ProportionTable(x1, x2, weights=weights, dims=:row)

# From DataFrame
df = DataFrame(cat=x1, val=x2)
prop_df = ProportionTable(df, :cat, :val, dims=:col)
```

# Notes
- All proportions are returned as Float64 values
- Row, column, and total proportions will sum to 1.0 (within rounding error)
- Missing values are handled according to the skipmissing parameter
- The dims parameter is ignored for single-variable tables
"""

function ProportionTable(ct::ContingencyResults; dims::Union{Nothing,Symbol}=nothing)
    if dims ∉ [nothing, :row, :col]
        throw(ArgumentError("dims must be nothing, :row, or :col"))
    end
    
    df = ct.counts
    
    # Single variable case
    if size(df, 2) == 2  # Value and Count columns
        total = sum(df.Count)
        props = DataFrame(
            Value = df.Value,
            Proportion = Float64.(df.Count ./ total)
        )
        dim_result = nothing
    else  # Two-variable case
        count_matrix = Matrix{Float64}(df[:, 2:end])  # Convert to Float64 matrix
        row_names = df[:, 1]
        col_names = names(df)[2:end]
        
        if isnothing(dims)
            # Total proportions
            total = sum(count_matrix)
            proportions = count_matrix ./ total
        elseif dims == :row
            # Row proportions
            row_sums = sum(count_matrix, dims=2)
            proportions = count_matrix ./ row_sums
        else  # dims == :col
            # Column proportions
            col_sums = sum(count_matrix, dims=1)
            proportions = count_matrix ./ col_sums
        end
        
        # Create new DataFrame with Float64 columns
        props = DataFrame(proportions, Symbol.(col_names))
        insertcols!(props, 1, :Row => row_names)
        dim_result = dims
    end
    
    return create_proportion_results(
        props,
        dim_result,
        ct.value_type,
        Float64,
        ct.levels,
        ct.ordered
    )
end

# Direct computation from raw data
function ProportionTable(args...;
    skipmissing::Bool=false,
    weights=nothing,
    dims::Union{Nothing,Symbol}=nothing
)
    # First compute contingency table
    ct = ContingencyTable(args...; skipmissing=skipmissing, weights=weights)

    # Then compute proportions
    return ProportionTable(ct; dims=dims)
end