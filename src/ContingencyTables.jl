module ContingencyTables

using CategoricalArrays
using DataAPI
using DataFrames
using SparseArrays

export ContingencyTable, ProportionTable
export ContingencyResults, ProportionResults
export ExpectedFrequency

include("types.jl")
include("utils.jl")
include("ContingencyTable.jl")
include("ProportionTable.jl")
include("ExpectedFrequency.jl")

export ContingencyTable, ContingencyResults, ProportionTable, ProportionResults

end # module ContingencyTables