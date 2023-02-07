# Gallery

```@example
using InMemoryDatasets, DLMReader, StatisticalGraphics

iris = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                                 "..", "assets", "iris.csv"))
sgplot(iris, Scatter(x=:PetalLength, y=:SepalLength, group=:Species))
```