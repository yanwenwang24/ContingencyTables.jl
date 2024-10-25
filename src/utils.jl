
"""
Helper function for creating ContingencyResults
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
Helper function for creating ProportionResults
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
Helper function to efficiently get unique values with missing handling
"""

function _get_unique_values(x, is_cat, orig_levels, skipmissing)
    if is_cat
        vals = Vector{Union{eltype(orig_levels), Missing}}(orig_levels)
        if !skipmissing && any(ismissing, x)
            push!(vals, missing)
        end
        return vals
    else
        # Use Set for faster unique operation
        non_missing_vals = sort!(collect(Set(filter(!ismissing, x))))
        if !skipmissing && any(ismissing, x)
            push!(non_missing_vals, missing)
        end
        return non_missing_vals
    end
end

"""
Helper function to create value mapping dictionary
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
Helper function to print ContingencyResults
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
Helper function to print ProportionResults
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