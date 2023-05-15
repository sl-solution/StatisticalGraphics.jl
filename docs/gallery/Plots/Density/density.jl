# ---
# title: Density
# id: demo_density1
# description: Drawing Density
# cover: assets/density1.svg
# ---

using InMemoryDatasets, DLMReader, StatisticalGraphics

y = rand([0, 2, 6], 100) #hide #md
svg("assets/density1.svg", sgplot(Dataset(x=randn(100) .+ y, y=y), Density(x=:x, type=:kernel, group=:y), nominal=:y, legend=false, width=100, height=100, xaxis=Axis(translate=0,offset=0, grid=true, griddash=[3]), yaxis=Axis(translate=0, grid=true, offset=0, griddash=[3]))) #hide #md


# `Density` can be used to fit a normal pdf or a kernel density to data. By default it used normal density.

ds = Dataset(x=rand(100))

sgplot(ds, Density(x=:x))

# Passing `type=:kernel` allows fitting a kernel Distributions

sgplot(ds, Density(x=:x, type=:kernel))

# `Density` like other plots allow `group`

iris = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                                 "..", "docs", "assets", "iris.csv"))
    
sgplot(iris, 
        Density(x=:SepalLength, type=:kernel, group=:Species)
)

# Users allow to combine `Density` and `Histogram`

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