# Abstract type definition
abstract type AbstractContingencyTable end

# Main results struct
struct ContingencyResults{T, S<:Real, L} <: AbstractContingencyTable
    counts::DataFrame
    weights_used::Bool
    value_type::Type{T}
    count_type::Type{S}
    levels::Dict{Int, Union{Nothing, Vector{L}}}
    ordered::Dict{Int, Bool}
end

# Constructor helper
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

# Pretty printing
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