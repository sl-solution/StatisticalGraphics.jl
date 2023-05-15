# ---
# title: Histogram
# id: demo_histogram1
# description: Drawing Histogram
# cover: assets/hist1.svg
# ---

using InMemoryDatasets, DLMReader, StatisticalGraphics

svg("assets/hist1.svg", sgplot(Dataset(x=randn(1000)), Histogram(x=:x, space=0), width=100, height=100, xaxis=Axis(translate=0,offset=0, grid=true, griddash=[3]), yaxis=Axis(translate=0, grid=true, offset=0, griddash=[3]))) #hide #md


# `Histogram` draw histogram for given column.

ds = Dataset(x=randn(10000))

sgplot(ds, Histogram(x=:x))

# Assigning the `y` keyword argument, produce horizontal plot

sgplot(ds, Histogram(y=:x))

# By default `Histogram` compute pdf, however, user may pass `:cdf`, `:count`, ... or anyother for scaling the bars

sgplot(ds, Histogram(x=:x, scale=:cdf))

# Like other plots, `Histogram` support `group`,

iris = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                                 "..", "docs", "assets", "iris.csv"))
    
sgplot(iris, 
        Histogram(x=:SepalLength, group=:Species, opacity=0.5)
)

# Passing `midpoints` allows more control on bin selection

sgplot(iris, 
        Histogram(x=:SepalLength,
                    group=:Species,
                    opacity=0.5,
                    midpoints=3.5:.4:8
                )
)