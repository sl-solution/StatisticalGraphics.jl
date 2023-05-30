using InMemoryDatasets, StatisticalGraphics, DLMReader

iris = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                                 "..", "docs", "assets", "iris.csv"))
sgplot(iris, Scatter(x=:PetalLength, y=:SepalLength,
                                     group=:Species, thickness=3),
                                     wallcolor=:lightgray,
                                     clip=false)

# generate random data
ds = Dataset(x=rand(100), y=rand(100), g=rand(1:4, 100))

sgplot(ds, Scatter(x=:x, y=:y, size=200, group=:g,
                         color=:white, clip=false))

sgplot(ds, Scatter(x=:x, y=:y, size=200, group=:g,
                         color=:white, clip=false), nominal=:g)

sgplot(ds, Scatter(x=:x, y=:y, size=200, colorresponse=:g,
                         color=:white, clip=false), nominal=:g)

sgplot(ds, Scatter(x=:x, y=:y, size=200, symbolresponse=:g,
                         clip=false), nominal=:g)

sgplot(ds, Scatter(x=:x, y=:y, size=200, group=:g,
                         symbolresponse=:g, clip=false), nominal=:g)

sgplot(ds, Scatter(x=:x, y=:y, size=200, group=:g,
                         thickness=2,
                         symbolresponse=:g,
                         colorresponse=:g,
                         colormodel=Dict(:scheme=>:turbo),
                         clip=false), nominal=:g)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

