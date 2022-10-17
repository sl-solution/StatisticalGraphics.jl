module StatisticalGraphics
    using InMemoryDatasets
    using DLMReader
    using JSON

    const SG = StatisticalGraphics
    export
        SG,
        SGMarks, 
        Bar,
        Band,
        Scatter,
        Line,
        Histogram,
        Bar,
        BoxPlot,
        RefLine,
        Axis,
        Legend,
        sgplot,
        freq # freq is a function used in Bar plot
    
    abstract type SGMarks end

    include("util.jl")
    include("charts/axes.jl")
    include("charts/legend.jl")
    include("charts/scatter.jl")
    include("charts/line.jl")
    include("charts/band.jl")
    include("charts/histogram.jl")
    include("charts/bar.jl")
    include("charts/boxplot.jl")
    include("charts/refline.jl")
    include("sgplot.jl")
    include("sgpanel.jl")
end
