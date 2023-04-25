using InMemoryDatasets, StatisticalGraphics

# generate random data
ds = Dataset(x=rand(100), y=rand(100))

sgplot(ds, Scatter(x=:x, y=:y, size=200))

sgplot(ds, Scatter(x=:x, y=:y, size=200, outlinecolor=:white,
                         color=:steelblue))

sgplot(ds, Scatter(x=:x, y=:y, size=200, outlinecolor=:white,
                         color=gradient()))

sgplot(ds, Scatter(x=:x, y=:y, size=200, outlinecolor=:white,
                         color=:steelblue, symbol=:square))

sgplot(ds, Scatter(x=:x, y=:y, size=200, outlinecolor=:steelblue,
                         color=:white, clip=false))

sgplot(ds, Scatter(x=:x, y=:y, size=200, outlinecolor=:steelblue,
                         color=:white, clip=false), wallcolor=:lightgray)

sgplot(ds, Scatter(x=:x, y=:y, size=200, outlinecolor=:steelblue,
                         color=:white, clip=false), wallcolor=:lightgray,
                         xaxis=Axis(grid=true, gridcolor=:white),
                         yaxis=Axis(grid=true, gridcolor=:white))

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

