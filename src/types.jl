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

struct ProportionResults{T, S<:Real, L} <: AbstractContingencyTable
    proportions::DataFrame
    dimension::Union{Nothing,Symbol}
    value_type::Type{T}
    count_type::Type{S}
    levels::Dict{Int, Union{Nothing, Vector{L}}}
    ordered::Dict{Int, Bool}
end
