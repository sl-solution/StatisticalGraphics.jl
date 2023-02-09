# ---
# title: Simple Scatter plot
# id: demo_scatter_plot1
# description: Using the `Scatter` mark to produce a simple scatter plot
# cover: assets/scatter_plot1.svg
# ---

using InMemoryDatasets, StatisticalGraphics

## generate random data
ds = Dataset(x=rand(100), y=rand(100))

svg("assets/scatter_plot1.svg", sgplot(ds, Scatter(x=:x, y=:y), width=100, height=100, xaxis=Axis(offset=0), yaxis=Axis(offset=0))) #hide #md

sgplot(ds, Scatter(x=:x, y=:y))