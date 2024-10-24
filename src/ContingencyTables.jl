module ContingencyTables

using CategoricalArrays
using DataFrames

export ContingencyTable, ContingencyResults

include("types.jl")
include("ContingencyTable.jl")

export ContingencyTable, ContingencyResults

end # module ContingencyTables