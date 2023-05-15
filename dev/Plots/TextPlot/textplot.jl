using InMemoryDatasets, DLMReader, StatisticalGraphics

ds = Dataset(x=rand(10), y=rand(10), text='A':'J')

sgplot(ds, TextPlot(x=:x, y=:y, text=:text))

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

