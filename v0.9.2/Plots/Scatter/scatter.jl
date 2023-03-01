using InMemoryDatasets, StatisticalGraphics

# generate random data
ds = Dataset(x=rand(100), y=rand(100))


sgplot(ds, Scatter(x=:x, y=:y))

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

