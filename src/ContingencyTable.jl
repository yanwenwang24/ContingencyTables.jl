"""
    ContingencyTable(x; skipmissing=false, weights=nothing)
    ContingencyTable(df::DataFrame, col::Symbol; skipmissing=false, weights=nothing)
    ContingencyTable(x1, x2; skipmissing=false, weights=nothing)
    ContingencyTable(df::DataFrame, col1::Symbol, col2::Symbol; skipmissing=false, weights=nothing)

Create a contingency table from input data, supporting both single and two-dimensional analyses.

# Arguments
- `x`, `x1`, `x2`: Vectors of observations (can be regular arrays or CategoricalArrays)
- `df`: DataFrame containing the columns to analyze
- `col`, `col1`, `col2`: Column symbols from the DataFrame
- `skipmissing=false`: Whether to exclude missing values from the count
- `weights=nothing`: Optional weights for observations. Can be:
    - A vector of numerical weights
    - A Symbol referring to a weights column in the DataFrame
    - Nothing for unweighted counts

# Returns
- ContingencyResults object containing:
  - counts::DataFrame: Frequency counts in table format
  - weights_used::Bool: Indicates if weights were applied
  - value_type::Type: Type of the input values
  - count_type::Type: Type used for counting (Int for unweighted, Float64 for weighted)
  - levels::Dict: Maps dimensions to their categorical levels (if any)
  - ordered::Dict: Maps dimensions to their ordering status

# Details
- Handles both regular and categorical arrays
- Preserves categorical array ordering and levels
- Supports weighted and unweighted counts
- Handles missing values according to skipmissing parameter
- For categorical data, maintains the original level ordering
- For non-categorical data, sorts non-missing values for consistent output

# Examples
```julia
# Basic usage with a single vector
x = [1, 2, 2, 3, missing]
result = ContingencyTable(x)
result.counts  # Shows frequency of each value

# Using DataFrame column
df = DataFrame(A = [1, 2, 2, 3, missing])
result = ContingencyTable(df, :A)

# Two-dimensional table with weights
x1 = [1, 2, 2, 3]
x2 = ["a", "b", "b", "a"]
weights = [1.0, 2.0, 1.0, 1.0]
result = ContingencyTable(x1, x2, weights=weights)

# Using categorical data with ordering
using CategoricalArrays
x = categorical(["A", "B", "A", "C", "B"], ordered=true)
df = DataFrame(cat=x, val=[1,2,1,3,2])
ct1 = ContingencyTable(x)                  # One-dimensional
ct2 = ContingencyTable(df, :cat)          # From DataFrame
ct3 = ContingencyTable(df, :cat, :val)    # Two-dimensional

# With missing value handling
result = ContingencyTable([1, 2, missing, 2], skipmissing=true)
```

# Notes
- Empty input vectors will raise an ArgumentError
- Negative weights will raise an ArgumentError
- Weight vector length must match input vector length
- Missing values in weights are treated as zero
"""

# Method for single vector input
function ContingencyTable(
    x::AbstractVector{T};
    skipmissing::Bool=false,
    weights::Union{Nothing,AbstractVector{S}}=nothing
) where {T,S<:Real}

    # Error checking
    isempty(x) && throw(ArgumentError("Input vector must not be empty"))

    if !isnothing(weights)
        length(weights) != length(x) && throw(ArgumentError("Length of weights ($(length(weights))) must match length of input vector ($(length(x)))"))
        any(w -> !ismissing(w) && w < 0, weights) && throw(ArgumentError("Weights must be non-negative"))
    end

    # Handle CategoricalArray
    is_cat = x isa CategoricalArray
    orig_levels = if is_cat
        lvls = levels(x)
        Vector{Union{eltype(lvls),Missing}}(lvls)
    else
        nothing
    end
    is_ordered = is_cat ? isordered(x) : false

    # Filter missing values if requested
    if skipmissing
        valid_idx = .!ismissing.(x)
        x_valid = @view x[valid_idx]
        weights_valid = isnothing(weights) ? nothing : @view weights[valid_idx]
    else
        x_valid = x
        weights_valid = weights
    end

    # Determine count type based on weights
    count_type = isnothing(weights) ? Int : Float64

    # Count frequencies using appropriate method based on data type
    if is_cat
        # Handle categorical data with preserved levels
        freq_dict = Dict{Union{eltype(orig_levels),Missing},count_type}()
        sizehint!(freq_dict, length(orig_levels) + (!skipmissing && any(ismissing, x) ? 1 : 0))
        # Initialize all levels with zero
        for level in orig_levels
            freq_dict[level] = zero(count_type)
        end
        if !skipmissing
            freq_dict[missing] = zero(count_type)
        end

        # Count using get() to extract raw values from CategoricalValues
        if isnothing(weights_valid)
            @inbounds for val in x_valid
                raw_val = ismissing(val) ? missing : DataAPI.unwrap(val)
                freq_dict[raw_val] = get(freq_dict, raw_val, zero(count_type)) + one(count_type)
            end
        else
            @inbounds for (val, w) in zip(x_valid, weights_valid)
                raw_val = ismissing(val) ? missing : DataAPI.unwrap(val)
                w_val = ismissing(w) ? zero(count_type) : w
                freq_dict[raw_val] = get(freq_dict, raw_val, zero(count_type)) + w_val
            end
        end
    else
        # For non-categorical data, use Set for unique values
        unique_set = Set{Union{eltype(x_valid),Missing}}()
        @inbounds for val in x_valid
            push!(unique_set, val)
        end

        freq_dict = Dict{Union{eltype(x_valid),Missing},count_type}()
        sizehint!(freq_dict, length(unique_set))

        if isnothing(weights_valid)
            @inbounds for val in x_valid
                freq_dict[val] = get(freq_dict, val, zero(count_type)) + one(count_type)
            end
        else
            @inbounds for (val, w) in zip(x_valid, weights_valid)
                w_val = ismissing(w) ? zero(count_type) : w
                freq_dict[val] = get(freq_dict, val, zero(count_type)) + w_val
            end
        end
    end

    # Convert to DataFrame
    if is_cat
        values = collect(orig_levels)
        if !skipmissing && any(ismissing, x)
            push!(values, missing)
        end
    else
        # Sort non-missing values for consistent output
        non_missing_vals = sort!(collect(filter(!ismissing, keys(freq_dict))))
        values = if any(ismissing, keys(freq_dict))
            vcat(non_missing_vals, missing)
        else
            non_missing_vals
        end
    end

    # Pre-allocate arrays for DataFrame construction
    n = length(values)
    display_values = Vector{Any}(undef, n)
    counts = Vector{count_type}(undef, n)

    # Fill arrays efficiently
    @inbounds for (i, val) in enumerate(values)
        display_values[i] = ismissing(val) ? "missing" : val
        counts[i] = freq_dict[val]
    end

    # Create DataFrame
    df = DataFrame(
        Value=display_values,
        Count=counts
    )

    # Create the levels dictionary with proper typing
    L = is_cat ? eltype(orig_levels) : Any
    levels_dict = Dict{Int,Union{Nothing,Vector{L}}}(1 => orig_levels)
    ordered_dict = Dict(1 => is_ordered)

    return create_contingency_results(
        df,
        !isnothing(weights),
        T,
        count_type,
        levels_dict,
        ordered_dict
    )
end

# Method for two vectors input
function ContingencyTable(
    x1::AbstractVector{T1}, x2::AbstractVector{T2};
    skipmissing::Bool=false,
    weights::Union{Nothing,AbstractVector{S}}=nothing
) where {T1,T2,S<:Real}
    # Error checking
    isempty(x1) && throw(ArgumentError("First input vector must not be empty"))
    isempty(x2) && throw(ArgumentError("Second input vector must not be empty"))
    length(x1) != length(x2) && throw(ArgumentError("Input vectors must have the same length"))

    if !isnothing(weights)
        length(weights) != length(x1) && throw(ArgumentError("Length of weights ($(length(weights))) must match length of input vectors ($(length(x1)))"))
        any(w -> !ismissing(w) && w < 0, weights) && throw(ArgumentError("Weights must be non-negative"))
    end

    # Handle categorical arrays
    is_cat1 = x1 isa CategoricalArray
    is_cat2 = x2 isa CategoricalArray

    orig_levels1 = if is_cat1
        lvls = levels(x1)
        Vector{eltype(lvls)}(lvls)
    else
        nothing
    end

    orig_levels2 = if is_cat2
        lvls = levels(x2)
        Vector{eltype(lvls)}(lvls)
    else
        nothing
    end

    is_ordered1 = is_cat1 ? isordered(x1) : false
    is_ordered2 = is_cat2 ? isordered(x2) : false

    # Prepare data
    if skipmissing
        valid_idx = .!ismissing.(x1) .& .!ismissing.(x2)
        x1_valid = @view x1[valid_idx]
        x2_valid = @view x2[valid_idx]
        weights_valid = isnothing(weights) ? nothing : @view weights[valid_idx]
    else
        x1_valid = x1
        x2_valid = x2
        weights_valid = weights
    end

    # Get unique values, respecting categorical levels if present
    unique_x1 = _get_unique_values(x1_valid, is_cat1, orig_levels1, skipmissing)
    unique_x2 = _get_unique_values(x2_valid, is_cat2, orig_levels2, skipmissing)

    # Determine count type
    count_type = isnothing(weights) ? Int : Float64

    # Initialize result matrix
    result = zeros(count_type, length(unique_x1), length(unique_x2))

    # Create mappings for faster lookup
    x1_map = _create_value_map(unique_x1)
    x2_map = _create_value_map(unique_x2)

    # Pre-allocate result matrix
    count_type = isnothing(weights) ? Int : Float64
    result = zeros(count_type, length(unique_x1), length(unique_x2))

    # Fill the matrix
    if isnothing(weights_valid)
        @inbounds for i in eachindex(x1_valid, x2_valid)
            v1 = x1_valid[i]
            v2 = x2_valid[i]
            v1_raw = is_cat1 ? (ismissing(v1) ? missing : DataAPI.unwrap(v1)) : v1
            v2_raw = is_cat2 ? (ismissing(v2) ? missing : DataAPI.unwrap(v2)) : v2
            result[x1_map[v1_raw], x2_map[v2_raw]] += one(count_type)
        end
    else
        @inbounds for i in eachindex(x1_valid, x2_valid, weights_valid)
            v1 = x1_valid[i]
            v2 = x2_valid[i]
            w = weights_valid[i]
            v1_raw = is_cat1 ? (ismissing(v1) ? missing : DataAPI.unwrap(v1)) : v1
            v2_raw = is_cat2 ? (ismissing(v2) ? missing : DataAPI.unwrap(v2)) : v2
            w_val = ismissing(w) ? zero(count_type) : w
            result[x1_map[v1_raw], x2_map[v2_raw]] += w_val
        end
    end

    # Convert missing values to "missing" string in row/column names
    row_names = map(unique_x1) do v
        ismissing(v) ? "missing" : string(v)
    end
    col_names = map(unique_x2) do v
        ismissing(v) ? "missing" : string(v)
    end

    # Create DataFrame
    df = DataFrame(result, Symbol.(col_names))
    insertcols!(df, 1, :Row => row_names)

    # Create the levels dictionary with proper typing
    L = promote_type(
        is_cat1 ? eltype(orig_levels1) : Any,
        is_cat2 ? eltype(orig_levels2) : Any
    )
    levels_dict = Dict{Int,Union{Nothing,Vector{L}}}(
        1 => orig_levels1,
        2 => orig_levels2
    )
    ordered_dict = Dict(
        1 => is_ordered1,
        2 => is_ordered2
    )

    return create_contingency_results(
        df,
        !isnothing(weights),
        Tuple{T1,T2},
        count_type,
        levels_dict,
        ordered_dict
    )
end

# Method for DataFrame column input
function ContingencyTable(
    df::DataFrame, col::Symbol;
    skipmissing::Bool=false,
    weights::Union{Nothing,Symbol,AbstractVector}=nothing
)
    weights_vec = weights isa Symbol ? df[!, weights] : weights
    return ContingencyTable(df[!, col], skipmissing=skipmissing, weights=weights_vec)
end

# Method for DataFrame two columns input
function ContingencyTable(
    df::DataFrame, col1::Symbol, col2::Symbol;
    skipmissing::Bool=false,
    weights::Union{Nothing,Symbol,AbstractVector}=nothing
)
    weights_vec = weights isa Symbol ? df[!, weights] : weights
    return ContingencyTable(df[!, col1], df[!, col2], skipmissing=skipmissing, weights=weights_vec)
end