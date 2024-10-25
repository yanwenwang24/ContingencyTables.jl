"""
    ProportionTable(x; skipmissing=false, weights=nothing)
    ProportionTable(df::DataFrame, col::Symbol; skipmissing=false, weights=nothing)
    ProportionTable(x1, x2; skipmissing=false, weights=nothing, dims=nothing)
    ProportionTable(df::DataFrame, col1::Symbol, col2::Symbol; skipmissing=false, weights=nothing, dims=nothing)
    ProportionTable(ct::ContingencyResults; dims=nothing)

Create a proportion table from input data or a ContingencyResults object.

# Arguments
- `x`, `x1`, `x2`: Vectors or CategoricalArrays of observations
- `df`: DataFrame containing the columns to analyze
- `col`, `col1`, `col2`: Column symbols from the DataFrame
- `ct`: ContingencyResults object from ContingencyTable()
- `skipmissing=false`: Whether to exclude missing values
- `weights=nothing`: Optional weights for observations
- `dims=nothing`: Dimension for proportion calculation
  - `nothing`: total proportions
  - `:row`: row proportions
  - `:col`: column proportions

# Returns
- `ProportionResults` object containing the proportions and metadata

# Examples
```julia
# From raw data
x = [1, 2, 2, 3, 3, 3]
prop_table = ProportionTable(x)

# From ContingencyResults
ct = ContingencyTable(x)
prop_table = ProportionTable(ct)

# Two variables with row proportions
x1 = categorical(["A", "B", "A", "C"])
x2 = [1, 2, 1, 3]
prop_table = ProportionTable(x1, x2, dims=:row)
```
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