using Documenter, LForaging

makedocs(;
    modules=[LForaging],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/DarioSarra/LForaging.jl/blob/{commit}{path}#L{line}",
    sitename="LForaging.jl",
    authors="DarioSarra",
    assets=String[],
)

deploydocs(;
    repo="github.com/DarioSarra/LForaging.jl",
)
