# Scatter

## Basic

```@example
using InMemoryDatasets, StatisticalGraphics

ds = Dataset(x=[1.1, 1.5, 2.7, 3.1], y=[1.1, -3.4, 2.1, 2.55], g=['A', 'B', 'A', 'B'])

sgplot(ds, Scatter(x=:x, y=:y))
```

By passing `group=:g` a different outline color will be assigned to each point.

```@example
using InMemoryDatasets, StatisticalGraphics

ds = Dataset(x=[1.1, 1.5, 2.7, 3.1], y=[1.1, -3.4, 2.1, 2.55], g=['A', 'B', 'A', 'B'])

sgplot(ds, Scatter(x=:x, y=:y, group=:g))
```

## Customising the points

```@example
using InMemoryDatasets, StatisticalGraphics

ds = Dataset(x=[1.1, 1.5, 2.7, 3.1], y=[1.1, -3.4, 2.1, 2.55], g=['A', 'B', 'A', 'B'])

sgplot(ds, Scatter(x=:x, y=:y, group=:g, size=500, thickness=3))
```

Using different symbol for each group

```@example
using InMemoryDatasets, StatisticalGraphics

ds = Dataset(x=[1.1, 1.5, 2.7, 3.1], y=[1.1, -3.4, 2.1, 2.55], g=['A', 'B', 'A', 'B'])

sgplot(ds, Scatter(x=:x, y=:y, group=:g, size=500, thickness=3, symbolresponse=:g))
```

Removing the oultine and fill the symbols with solid color

```@example
using InMemoryDatasets, StatisticalGraphics

ds = Dataset(x=[1.1, 1.5, 2.7, 3.1], y=[1.1, -3.4, 2.1, 2.55], g=['A', 'B', 'A', 'B'])

sgplot(ds, Scatter(x=:x, y=:y, size=500, thickness=0, color=:steelblue, symbolresponse=:g))
```

Scatter plot of `iris` data

```@example
using InMemoryDatasets, DLMReader, StatisticalGraphics

iris = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                                 "..", "docs", "assets", "iris.csv"))
sgplot(iris, Scatter(x=:PetalLength, y=:SepalLength, group=:Species, thickness=3), wallcolor=:lightgray)
```