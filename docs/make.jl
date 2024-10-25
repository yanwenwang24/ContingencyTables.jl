using ContingencyTables
using Documenter
using CategoricalArrays
using DataFrames
using DataAPI


DocMeta.setdocmeta!(ContingencyTables, :DocTestSetup, :(using ContingencyTables); recursive=true)

makedocs(;
    modules=[ContingencyTables],
    authors="Yanwen Wang <yanwenwang@u.nus.edu>",
    repo="https://github.com/yanwenwang24/ContingencyTables.jl/blob/{commit}{path}#{line}",
    sitename="ContingencyTables.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://yanwenwang24.github.io/ContingencyTables.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "API" => "api.md"
    ],
)

deploydocs(;
    repo="github.com/yanwenwang24/ContingencyTables.jl",
    devbranch="main",
)