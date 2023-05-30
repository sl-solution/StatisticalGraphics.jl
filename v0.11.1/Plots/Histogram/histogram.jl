using InMemoryDatasets, DLMReader, StatisticalGraphics

ds = Dataset(x=randn(10000))

sgplot(ds, Histogram(x=:x))

sgplot(ds, Histogram(y=:x))

sgplot(ds, Histogram(x=:x, scale=:cdf))

iris = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                                 "..", "docs", "assets", "iris.csv"))

sgplot(iris,
        Histogram(x=:SepalLength, group=:Species, opacity=0.5)
)

sgplot(iris,
        Histogram(x=:SepalLength,
                    group=:Species,
                    opacity=0.5,
                    midpoints=3.5:.4:8
                )
)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

