
"""
    create_contingency_results(counts, weights_used, value_type, count_type, levels, ordered)

Create a ContingencyResults object that stores the results of contingency table analysis.

# Arguments
- `counts::DataFrame`: DataFrame containing the contingency counts
- `weights_used::Bool`: Indicates if weights were used in the calculation
- `value_type::Type{T}`: Type of the values in the contingency table
- `count_type::Type{S}`: Type used for counting (must be a subtype of Real)
- `levels::Dict{Int, Union{Nothing, Vector{L}}}`: Dictionary mapping dimensions to their levels
- `ordered::Dict{Int, Bool}`: Dictionary indicating if dimensions are ordered

# Returns
- `ContingencyResults{T, S, L}`: A new ContingencyResults object

# Note
This is a helper function primarily used internally for constructing ContingencyResults objects.
"""

function create_contingency_results(
    counts::DataFrame,
    weights_used::Bool,
    value_type::Type{T},
    count_type::Type{S},
    levels::Dict{Int, Union{Nothing, Vector{L}}},
    ordered::Dict{Int, Bool}
) where {T, S<:Real, L}
    ContingencyResults{T, S, L}(counts, weights_used, value_type, count_type, levels, ordered)
end

"""
    create_proportion_results(proportions, dimension, value_type, count_type, levels, ordered)

Create a ProportionResults object that stores the results of proportion calculations.

# Arguments
- `proportions::DataFrame`: DataFrame containing the calculated proportions
- `dimension::Union{Nothing,Symbol}`: Dimension along which proportions were calculated
- `value_type::Type{T}`: Type of the values in the proportion table
- `count_type::Type{S}`: Type used for counting (must be a subtype of Real)
- `levels::Dict{Int, Union{Nothing, Vector{L}}}`: Dictionary mapping dimensions to their levels
- `ordered::Dict{Int, Bool}`: Dictionary indicating if dimensions are ordered

# Returns
- `ProportionResults{T, S, L}`: A new ProportionResults object

# Note
This is a helper function primarily used internally for constructing ProportionResults objects.
"""

function create_proportion_results(
    proportions::DataFrame,
    dimension::Union{Nothing,Symbol},
    value_type::Type{T},
    count_type::Type{S},
    levels::Dict{Int, Union{Nothing, Vector{L}}},
    ordered::Dict{Int, Bool}
) where {T, S<:Real, L}
    ProportionResults{T, S, L}(proportions, dimension, value_type, count_type, levels, ordered)
end

"""
    _get_unique_values(x, is_cat, orig_levels, skipmissing)

Efficiently compute unique values from an array, handling categorical and missing values.

# Arguments
- `x`: Input array to extract unique values from
- `is_cat::Bool`: Whether the input is categorical
- `orig_levels`: Original levels for categorical data
- `skipmissing::Bool`: Whether to exclude missing values

# Returns
- Vector of unique values, sorted if non-categorical

# Note
Uses Set for efficient unique value computation for non-categorical data.
Handles missing values based on the skipmissing parameter.
"""

function _get_unique_values(x, is_cat, orig_levels, skipmissing)
    if is_cat
        # For categorical data, use original levels
        vals = Vector{Union{eltype(orig_levels), Missing}}(orig_levels)
        if !skipmissing && any(ismissing, x)
            push!(vals, missing)
        end
        return vals
    else
        # For non-categorical data, use Set for efficiency
        non_missing_vals = sort!(collect(Set(filter(!ismissing, x))))
        if !skipmissing && any(ismissing, x)
            push!(non_missing_vals, missing)
        end
        return non_missing_vals
    end
end

"""
    _create_value_map(unique_vals)

Create a dictionary mapping unique values to their integer indices.

# Arguments
- `unique_vals`: Vector of unique values to be mapped

# Returns
- Dictionary mapping each value to its index position

# Note
Pre-allocates dictionary size for better performance.
Handles missing values appropriately.
"""

function _create_value_map(unique_vals)
    # Pre-size the dictionary for better performance
    d = Dict{Union{eltype(unique_vals), Missing}, Int}()
    sizehint!(d, length(unique_vals))
    for (i, v) in enumerate(unique_vals)
        d[v] = i
    end
    return d
end

"""
    Base.show(io::IO, ct::ContingencyResults)

Custom display method for ContingencyResults objects.

Prints a formatted summary of the contingency table results, including:
- Value and count types
- Whether weights were used
- Dimension information (categorical/ordered status and levels)
- The actual counts in table format
"""

function Base.show(io::IO, ct::ContingencyResults)
    println(io, "ContingencyTable Results:")
    println(io, "  Value type: ", ct.value_type)
    println(io, "  Count type: ", ct.count_type)
    println(io, "  Weighted: ", ct.weights_used)
    for (dim, levels) in ct.levels
        if !isnothing(levels)
            println(io, "  Dimension $dim: Categorical ($(ct.ordered[dim] ? "ordered" : "unordered"))")
            println(io, "    Levels: ", levels)
        end
    end
    println(io, "\nCounts:")
    show(io, ct.counts)
end

"""
    Base.show(io::IO, pr::ProportionResults)

Custom display method for ProportionResults objects.

Prints a formatted summary of the proportion results, including:
- Value and count types
- Dimension used for proportion calculation
- Dimension information (categorical/ordered status and levels)
- The actual proportions in table format
"""

function Base.show(io::IO, pr::ProportionResults)
    println(io, "Proportion Table Results:")
    println(io, "  Value type: ", pr.value_type)
    println(io, "  Count type: ", pr.count_type)
    if !isnothing(pr.dimension)
        println(io, "  Dimension: ", pr.dimension)
    end
    for (dim, levels) in pr.levels
        if !isnothing(levels)
            println(io, "  Dimension $dim: Categorical ($(pr.ordered[dim] ? "ordered" : "unordered"))")
            println(io, "    Levels: ", levels)
        end
    end
    println(io, "\nProportions:")
    show(io, pr.proportions)
end