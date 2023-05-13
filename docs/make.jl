using Documenter
using StatisticalGraphics
using DemoCards



# DocMeta.setdocmeta!(InMemoryDatasets, :DocTestSetup, :(using InMemoryDatasets); recursive=true)

# Build documentation.
# ====================
scatter, scatter_cb, scatter_assets = makedemos(joinpath("gallery", "Plots"))
# line, line_cb, line_assets = makedemos(joinpath("gallery", "Line"))



makedocs(
    # options
    # modules = [InMemoryDatasets],
    doctest = false,
    clean = false,
    sitename = "StatisticalGraphics",
    # format = Documenter.HTML(
    #     canonical = "https://sl-solution.github.io/InMemoryDataset.jl/stable/",
    #     edit_link = "main"
    # ),
    pages = Any[
        "Introduction" => "index.md",
       
        "Usage" => [
            scatter
        ],
        "Interactive" => [
            "Pyramid" => "man/pyramid.md",
            "Nations" => "man/nations.md",
            "Movies" => "man/movies.md"
        ],
        "API" => Any[
            "Functions" => "lib/functions.md",
            "Plots" => "lib/Plots.md",
            "Axis & Legend" => "lib/Axis_Legend.md"
        ]
    ],
    strict = true
)

# Deploy built documentation from Travis.
# =======================================

deploydocs(
    # options
    repo = "github.com/sl-solution/StatisticalGraphics.jl",
    target = "build",
    deps = nothing,
    make = nothing,
    devbranch = "main"
)
