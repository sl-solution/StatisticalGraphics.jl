using InMemoryDatasets, DLMReader, StatisticalGraphics

ds = Dataset(x=randn(10000), y=randn(10000))

sgplot(ds, Heatmap(x=:x, y=:y))

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

