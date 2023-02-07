using Documenter
using StatisticalGraphics

# DocMeta.setdocmeta!(InMemoryDatasets, :DocTestSetup, :(using InMemoryDatasets); recursive=true)

# Build documentation.
# ====================

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
       
        "Gallery" => "man/gallery.md"
        
        # "API" => Any[
        #     "Functions" => "lib/functions.md"
        # ]
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
