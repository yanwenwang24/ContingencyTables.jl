# Abstract type definition
abstract type AbstractContingencyTable end

"""
    ContingencyResults{T, S<:Real, L}

A struct containing the results of a proportion table computation.

# Fields
- `counts::DataFrame`: The computed proportions
- `weights_used::Bool`: Whether weights were used in the computation
- `value_type::Type{T}`: Type of the input values
- `count_type::Type{S}`: Type of the count values
- `levels::Dict{Int, Union{Nothing, Vector{L}}}`: Categorical levels for each dimension
- `ordered::Dict{Int, Bool}`: Whether each dimension is ordered
"""

struct ContingencyResults{T, S<:Real, L} <: AbstractContingencyTable
    counts::DataFrame
    weights_used::Bool
    value_type::Type{T}
    count_type::Type{S}
    levels::Dict{Int, Union{Nothing, Vector{L}}}
    ordered::Dict{Int, Bool}
end

"""
    ProportionResults{T, S<:Real, L}

A struct containing the results of a proportion table computation.

# Fields
- `proportions::DataFrame`: The computed proportions
- `dimension::Union{Nothing,Symbol}`: Dimension used for proportion calculation (:row, :col, or nothing for total)
- `value_type::Type{T}`: Type of the input values
- `count_type::Type{S}`: Type of the count values
- `levels::Dict{Int, Union{Nothing, Vector{L}}}`: Categorical levels for each dimension
- `ordered::Dict{Int, Bool}`: Whether each dimension is ordered
"""

# Proportion table struct
struct ProportionResults{T, S<:Real, L} <: AbstractContingencyTable
    proportions::DataFrame
    dimension::Union{Nothing,Symbol}
    value_type::Type{T}
    count_type::Type{S}
    levels::Dict{Int, Union{Nothing, Vector{L}}}
    ordered::Dict{Int, Bool}
end

"""
    create_contingency_results(counts, weights_used, value_type, count_type, levels, ordered)

Constructor helper for ContingencyResults to ensure proper type inference.

# Arguments
- `count::DataFrame`: The computed proportions
- `weights_used::Bool`: Whether weights were used in the computation
- `value_type::Type`: Type of input values
- `count_type::Type`: Type of count values
- `levels::Dict`: Categorical levels for each dimension
- `ordered::Dict`: Whether each dimension is ordered

# Returns
- `ProportionResults` object with properly inferred types

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

Constructor helper for ProportionResults to ensure proper type inference.

# Arguments
- `proportions::DataFrame`: The computed proportions
- `dimension::Union{Nothing,Symbol}`: Dimension used for calculation
- `value_type::Type`: Type of input values
- `count_type::Type`: Type of count values
- `levels::Dict`: Categorical levels for each dimension
- `ordered::Dict`: Whether each dimension is ordered

# Returns
- `ProportionResults` object with properly inferred types
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

# Pretty printing for ContingencyResults
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

# Pretty printing for ProportionResults
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