using InMemoryDatasets, DLMReader, StatisticalGraphics

ds = Dataset(x=rand(100))

sgplot(ds, Density(x=:x))

sgplot(ds, Density(x=:x, type=:kernel))

iris = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                                 "..", "docs", "assets", "iris.csv"))

sgplot(iris,
        Density(x=:SepalLength, type=:kernel, group=:Species)
)

ds = Dataset(x=randn(100));
sgplot(
        ds,
        [
          Histogram(x=:x, color=:steelblue, outlinethickness=0.5, space=0.5),
          Density(x=:x, type=:kernel, color=:red, fillopacity=0.3),
          Density(x=:x, color=:green, fillopacity=0.3)
        ],
        xaxis = Axis(offset=10, domain=false),
        yaxis = Axis(offset=10, domain=false, grid=true)
      )

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

