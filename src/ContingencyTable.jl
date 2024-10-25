
"""
    ContingencyTable(x; skipmissing=false, weights=nothing)
    ContingencyTable(df::DataFrame, col::Symbol; skipmissing=false, weights=nothing)
    ContingencyTable(x1, x2; skipmissing=false, weights=nothing)
    ContingencyTable(df::DataFrame, col1::Symbol, col2::Symbol; skipmissing=false, weights=nothing)

 Create a contingency table from input data.

# Arguments
- `x`, `x1`, `x2`: Vectors of observations
- `df`: DataFrame containing the columns to analyze
- `col`, `col1`, `col2`: Column symbols from the DataFrame
- `skipmissing=false`: Whether to exclude missing values from the count
- `weights=nothing`: Optional weights for observations

# Returns
- ContingencyResults object containing:
  - counts::DataFrame with frequency counts
  - weights_used::Bool indicating if weights were applied
  - value_type::Type of the input values
  - count_type::Type of the count values
  - levels::Dict storing categorical levels
  - ordered::Dict storing categorical ordering information

# Examples
```julia
# Single vector
result = ContingencyTable([1, 2, 2, 3, missing])
result.counts  # Access the counts DataFrame

# From DataFrame column
df = DataFrame(A = [1, 2, 2, 3, missing])
result = ContingencyTable(df, :A)

# Two vectors with weights
x1 = [1, 2, 2, 3]
x2 = ["a", "b", "b", "a"]
weights = [1.0, 2.0, 1.0, 1.0]
result = ContingencyTable(x1, x2, weights=weights)

# With categorical data
x = categorical(["A", "B", "A", "C", "B"], ordered=true)
df = DataFrame(cat=x, val=[1,2,1,3,2])
ct1 = ContingencyTable(x)
ct2 = ContingencyTable(df, :cat)
ct3 = ContingencyTable(df, :cat, :val)
```
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

    # Initialize x_valid and weights_valid
    x_valid = x
    weights_valid = weights

    # Handle skipmissing
    if skipmissing
        valid_idx = .!ismissing.(x)
        x_valid = x[valid_idx]
        weights_valid = isnothing(weights) ? nothing : weights[valid_idx]
    end

    # Determine count type based on weights
    count_type = isnothing(weights) ? Int : Float64

    # Count frequencies
    if is_cat
        # For categorical data, use the raw values for counting
        freq_dict = Dict{Union{eltype(orig_levels),Missing},count_type}()
        # Initialize all levels with zero
        for level in orig_levels
            freq_dict[level] = zero(count_type)
        end
        if !skipmissing
            freq_dict[missing] = zero(count_type)
        end

        # Count using get() to extract raw values from CategoricalValues
        if isnothing(weights_valid)
            for val in x_valid
                raw_val = ismissing(val) ? missing : DataAPI.unwrap(val)
                freq_dict[raw_val] = get(freq_dict, raw_val, zero(count_type)) + one(count_type)
            end
        else
            for (val, w) in zip(x_valid, weights_valid)
                raw_val = ismissing(val) ? missing : DataAPI.unwrap(val)
                w_val = ismissing(w) ? zero(count_type) : w
                freq_dict[raw_val] = get(freq_dict, raw_val, zero(count_type)) + w_val
            end
        end
    else
        # For non-categorical data, use values directly
        freq_dict = Dict{Union{eltype(x_valid),Missing},count_type}()
        if isnothing(weights_valid)
            for val in x_valid
                freq_dict[val] = get(freq_dict, val, zero(count_type)) + one(count_type)
            end
        else
            for (val, w) in zip(x_valid, weights_valid)
                w_val = ismissing(w) ? zero(count_type) : w
                freq_dict[val] = get(freq_dict, val, zero(count_type)) + w_val
            end
        end
    end

    # Convert to DataFrame
    if is_cat
        values = Vector{Union{eltype(orig_levels),Missing}}(orig_levels)
        if !skipmissing && any(ismissing, x)
            push!(values, missing)
        end
        counts = [freq_dict[val] for val in values]
    else
        # For non-categorical data, sort the values
        values = collect(keys(freq_dict))
        non_missing_vals = filter(!ismissing, values)
        sort!(non_missing_vals)
        values = if any(ismissing, values)
            # Create a new vector that can handle missing
            result = Vector{Union{eltype(non_missing_vals),Missing}}(non_missing_vals)
            push!(result, missing)
            result
        else
            non_missing_vals
        end
        counts = [freq_dict[val] for val in values]
    end

    # Handle missing values in output
    display_values = [ismissing(v) ? "missing" : v for v in values]

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

    # Initialize variables
    x1_valid = x1
    x2_valid = x2
    weights_valid = weights

    # Handle skipmissing
    if skipmissing
        valid_idx = .!ismissing.(x1) .& .!ismissing.(x2)
        x1_valid = x1[valid_idx]
        x2_valid = x2[valid_idx]
        weights_valid = isnothing(weights) ? nothing : weights[valid_idx]
    end

    # Get unique values, respecting categorical levels if present
    unique_x1 = if is_cat1
        vals = Vector{Union{eltype(orig_levels1),Missing}}(orig_levels1)
        if !skipmissing && any(ismissing, x1)
            push!(vals, missing)
        end
        vals
    else
        # Sort non-categorical unique values, with single missing category
        non_missing_vals = sort!(unique(filter(!ismissing, x1_valid)))
        if !skipmissing && any(ismissing, x1_valid)
            vcat(non_missing_vals, [missing])
        else
            non_missing_vals
        end
    end

    unique_x2 = if is_cat2
        vals = Vector{Union{eltype(orig_levels2),Missing}}(orig_levels2)
        if !skipmissing && any(ismissing, x2)
            push!(vals, missing)
        end
        vals
    else
        # Sort non-categorical unique values, with single missing category
        non_missing_vals = sort!(unique(filter(!ismissing, x2_valid)))
        if !skipmissing && any(ismissing, x2_valid)
            vcat(non_missing_vals, [missing])
        else
            non_missing_vals
        end
    end

    # Determine count type
    count_type = isnothing(weights) ? Int : Float64

    # Initialize result matrix
    result = zeros(count_type, length(unique_x1), length(unique_x2))

    # Create mappings for faster lookup
    x1_map = Dict(val => i for (i, val) in enumerate(unique_x1))
    x2_map = Dict(val => j for (j, val) in enumerate(unique_x2))

    # Fill the matrix
    if isnothing(weights_valid)
        for (v1, v2) in zip(x1_valid, x2_valid)
            # Extract raw values if categorical, handling missing values
            v1_raw = is_cat1 ? (ismissing(v1) ? missing : DataAPI.unwrap(v1)) : v1
            v2_raw = is_cat2 ? (ismissing(v2) ? missing : DataAPI.unwrap(v2)) : v2
            result[x1_map[v1_raw], x2_map[v2_raw]] += one(count_type)
        end
    else
        for (v1, v2, w) in zip(x1_valid, x2_valid, weights_valid)
            # Extract raw values if categorical, handling missing values
            v1_raw = is_cat1 ? (ismissing(v1) ? missing : DataAPI.unwrap(v1)) : v1
            v2_raw = is_cat2 ? (ismissing(v2) ? missing : DataAPI.unwrap(v2)) : v2
            w_val = ismissing(w) ? zero(count_type) : w
            result[x1_map[v1_raw], x2_map[v2_raw]] += w_val
        end
    end

    # Convert missing values to "missing" string in row/column names
    row_names = [ismissing(v) ? "missing" : string(v) for v in unique_x1]
    col_names = [ismissing(v) ? "missing" : string(v) for v in unique_x2]

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