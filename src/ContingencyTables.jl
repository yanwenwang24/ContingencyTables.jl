module ContingencyTables

using CategoricalArrays
using DataAPI
using DataFrames

export ContingencyTable, ContingencyResults

include("types.jl")
include("ContingencyTable.jl")
include("ProportionTable.jl")

export ContingencyTable, ContingencyResults, ProportionTable, ProportionResults

end # module ContingencyTables