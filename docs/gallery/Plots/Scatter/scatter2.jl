# ---
# title: Customising overall appearance
# id: demo_scatter_plot3
# description: Using suitable keyword arguments to fine tune the final output
# cover: assets/scatter_plot3.svg
# ---

using InMemoryDatasets, StatisticalGraphics

## generate random data
ds = Dataset(x=rand(100), y=rand(100))

svg("assets/scatter_plot3.svg", sgplot(ds[1:20,:], Scatter(x=:x, y=:y, size=100, outlinecolor=:steelblue, color=:white), clip=false, wallcolor=:lightgray, xaxis=Axis(grid=true, gridcolor=:white, offset=0), yaxis=Axis(grid=true, gridcolor=:white, offset=0), width=100,height=100)) #hide #md

# Use the `size` keyword argument to control the symbol's size

sgplot(ds, Scatter(x=:x, y=:y, size=200))

# The `outlinecolor` and `color` arguments control the outline and fill color of symbol

sgplot(ds, Scatter(x=:x, y=:y, size=200, outlinecolor=:white,
                         color=:steelblue))

# The `gradient` function may be used for creating fancier colors

sgplot(ds, Scatter(x=:x, y=:y, size=200, outlinecolor=:white,
                         color=gradient()))

# By default, `circle` will be used to depict the symbol, however, user may pass the `symbol` argument to change the default behaviour

sgplot(ds, Scatter(x=:x, y=:y, size=200, outlinecolor=:white,
                         color=:steelblue, symbol=:square))

                         
# Pass the `clip=false` keyword argument to avoid clipping the points in the boundary of the graph. Note that the `clip=false` can be pass as a global argument. In this case all plots will be drawn with `clip=false`.

sgplot(ds, Scatter(x=:x, y=:y, size=200, outlinecolor=:steelblue,
                         color=:white, clip=false))

# User can change the wall color of the graph by passing the global `wallcolor` option.

sgplot(ds, Scatter(x=:x, y=:y, size=200, outlinecolor=:steelblue,
                         color=:white, clip=false), wallcolor=:lightgray)


# The grid for each axis can be set within the corresponding axis. This option must be pass to the `sgplot` function.

sgplot(ds, Scatter(x=:x, y=:y, size=200, outlinecolor=:steelblue,
                         color=:white, clip=false), wallcolor=:lightgray, 
                         xaxis=Axis(grid=true, gridcolor=:white),
                         yaxis=Axis(grid=true, gridcolor=:white))

