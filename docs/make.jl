using Documenter
using StatisticalGraphics
using DemoCards


function Base.show(io::IO, ::MIME"text/html", v::SG.SGManipulate)
    divid="vg"*string(rand(UInt128), base=16)
    print(io, """
    <div id='$divid' style="width:100%;height:100%;"></div>
    <script type='text/javascript'>
    requirejs.config({
        paths: {
            'vg-embed': 'https://cdn.jsdelivr.net/npm/vega-embed@6?noext',
            'vega-lib': 'https://cdn.jsdelivr.net/npm/vega-lib?noext',
            'vega-lite': 'https://cdn.jsdelivr.net/npm/vega-lite@5?noext',
            'vega': 'https://cdn.jsdelivr.net/npm/vega@5?noext'
        }
    });
    require(['vg-embed'], function(vegaEmbed) {
        vegaEmbed('#$divid', 
    """
    )
    print(io, SG.JSON.json(v.json_spec))
    print(io, """
    , {
        mode: 'vega'
        }).catch(console.warn);
        })
        </script>
    """)
end

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
        "Interactive" => "man/interactive.md"
        
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
