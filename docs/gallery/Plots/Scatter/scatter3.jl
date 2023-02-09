# ---
# title: Using grouping variables
# id: demo_scatterplot_group1
# description: Passing extra columns to group observations
# cover: assets/scatter_plot_group1.svg
# ---

using InMemoryDatasets, StatisticalGraphics, DLMReader

svg("assets/scatter_plot_group1.svg", sgplot(Dataset(x=rand(100), y=rand(100), g=rand(1:4, 100)), Scatter(x=:x, y=:y, size=100, outlinecolor=:white, colorresponse=:y, colormodel=Dict(:scheme=>:darkgreen), legend=:s_leg), clip=false, wallcolor=:lightgray, xaxis=Axis(grid=true, gridcolor=:white, offset=0), yaxis=Axis(grid=true, gridcolor=:white, offset=0), width=100, height=100, legend=Legend(name=:s_leg, gradientlength=80, gradientthickness=10))) #hide #md

# `Scatter` like many other plot types accepts a `group` keyword argument to group observations and creat a separate plot for each group. The groups are distinguishable by `color`.

iris = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                                 "..", "docs", "assets", "iris.csv"))
sgplot(iris, Scatter(x=:PetalLength, y=:SepalLength,
                                     group=:Species, thickness=3),
                                     wallcolor=:lightgray,
                                     clip=false)

# More examples,

## generate random data
ds = Dataset(x=rand(100), y=rand(100), g=rand(1:4, 100))

sgplot(ds, Scatter(x=:x, y=:y, size=200, group=:g,
                         color=:white, clip=false))

# In the previous example column `:g` was used to group observations. Since `:g` is a numeric column, `sgplot` automatically assigns a continous color bar in the legend of the plot, however, user can pass a list of nominal columns to `sgplot` to override the default behaviour.

sgplot(ds, Scatter(x=:x, y=:y, size=200, group=:g,
                         color=:white, clip=false), nominal=:g)


# `Scatter` allows user to pass a column to control the fill color of points, i.e. the fill color of the points will be affected by the value of the passed column to the `colorresponse` keyword argument

sgplot(ds, Scatter(x=:x, y=:y, size=200, colorresponse=:g,
                         color=:white, clip=false), nominal=:g)

# Additionally, `Scatter` allows users to pass extra columns as `symbolresponse`, `angleresponse`, or  `opacityresponse`. In this case the corresponding property will be changed depending on the values of the passed column.

sgplot(ds, Scatter(x=:x, y=:y, size=200, symbolresponse=:g,
                         clip=false), nominal=:g)

# The same column can be used for multiple purposes:

sgplot(ds, Scatter(x=:x, y=:y, size=200, group=:g,
                         symbolresponse=:g, clip=false), nominal=:g)

# `colormodel` allows users to pass a customised color scheme (or a vector of colors) for `colorresponse`

sgplot(ds, Scatter(x=:x, y=:y, size=200, group=:g,
                         thickness=2,
                         symbolresponse=:g,
                         colorresponse=:g,
                         colormodel=Dict(:scheme=>:turbo),
                         clip=false), nominal=:g)