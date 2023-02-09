# ---
# title: Line plot
# id: demo_line_plot1
# description: Using the `Line` mark to produce a simple line plot
# cover: assets/line_plot1.svg
# ---

# `Line` allows users to produce line plot. In the following example we read the `stocks` data from hard drive and then produce a simple line plot using `Line` and the `sgplot` function.

using InMemoryDatasets, DLMReader, StatisticalGraphics

svg("assets/line_plot1.svg", sgplot(Dataset(x=1:10, y=[1,-1.1,-2,0,0.5,1.5,1.78,1.9,1.5,1.8]), [Line(x=:x, y=:y, thickness=2), RefLine(values=[0], axis=:yaxis)], width=100, height=100, xaxis=Axis(translate=0,offset=0, grid=true, griddash=[3]), yaxis=Axis(translate=0, grid=true, offset=0, griddash=[3]))) #hide #md

# Creating a data set

ds = Dataset(x=range(0,6,length=100))
modify!(ds, :x=>byrow(sin)=>:y)

sgplot(ds, Line(x=:x, y=:y))

# **Dubai Weather**
# Users can pass multiple plot types to the `sgplot` function to produce an overlayed graph.

dubai_weather = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                                 "..", "docs", "assets", "dubai_weather.csv"),
                                 types=Dict(1 =>Date))

first(dubai_weather, 6)

# User must pass `type=:date` to make sure that `StatisticalGraphics` uses an suitable scale for the corresponding axis

sgplot(dubai_weather, [Line(x=:date, y=:min), Line(x=:date, y=:max)], xaxis=Axis(type=:date))

# The second axes can be used to measures with different scales on the same graph

sgplot(dubai_weather, [
                        Line(x=:date, y=:min),
                        Line(x=:date, y=:max),
                        Line(x=:date, y=:pressure, breaks=true, color=:red, y2axis=true)
                      ],
                        xaxis=Axis(type=:date))
