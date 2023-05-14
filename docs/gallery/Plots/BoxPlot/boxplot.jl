# ---
# title: Box-Whisker chart
# id: demo_boxplot1
# description: Using the `BoxPlot` mark to produce Box-Whisker charts
# cover: assets/box_plot1.svg
# ---

using InMemoryDatasets, StatisticalGraphics, DLMReader

svg("assets/box_plot1.svg", sgplot(Dataset(randn(100, 4), :auto), BoxPlot(y=1:4, whiskerdash=[0], outliers=true), width=100, height=100, xaxis=Axis(offset=0, domain=false,labelcolor=:black, tickcolor=:white,titlecolor=:white), yaxis=Axis(offset=0,domain=false,labelcolor=:white, tickcolor=:white,titlecolor=:white), legend=false, clip=false)) #hide #md

# `BoxPlot` produces box-whisker chart

iris = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                                 "..", "docs", "assets", "iris.csv"))
sgplot(iris, BoxPlot(x=1:4))

# Setting `outliers=true` add outlier points to the plot. The `outliersfactor` keyword controls the factor of outlierness. 

sgplot(iris, BoxPlot(x=1:4, outliers=true))

# The following examples show how the properties of box plots can be customised
sgplot(iris, BoxPlot(y=1:4, outliers=true,
                        boxwidth=0.7,
                        whiskerdash=[0],
                        whiskercolor=:white,
                        fencecolor=:white,
                        outliersymbolsize=100),
                        width=300,
                        wallcolor=:black)


# **[Box Plot](https://observablehq.com/@d3/box-plot)**

# Reproducing an example from the [`D3`](http://d3js.org)`s examples collection.

# Using the `format` feature of `InMemoryDataset` to manually bin data before plotting a box plot.

diamond = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                           "..", "docs", "assets", "diamonds.csv"))
carat_fmt(x) = round((searchsortedfirst(0.19:0.2:5.02, x)-2)*.2 + 0.3, digits=2)
setformat!(diamond, :carat=>carat_fmt)

sgplot(
        diamond, 
        BoxPlot(y=:price, category =:carat,
                mediancolor=:black, medianthickness = 0.5,
                fencewidth=0,
                whiskerdash=[0], whiskerthickness = 0.5,

                outliers = true,
                outlierjitter = 5,
                outliersymbolsize=10,
                outliercolor=:black,
                outlieropacity=0.1
              ),
        yaxis=Axis(domain = false, nice=false, grid=true),
        groupcolormodel=["lightgray"],
        legend=false,
        width=800
      )

# Users can pass name of a column as `category` to produce separate `BoxPlot` for each level the passed column,

sgplot(iris, BoxPlot(x=1:4, category=5, outliers=true))

# As another example

ds = Dataset(randn(100, 10), :auto)

insertcols!(ds, :Category=>rand(1:3, nrow(ds)))

sgplot(ds, BoxPlot(y=1:10, category=:Category,
                      whiskerdash=[0],
                      outlinethickness=0.3,
                      whiskerthickness=0.3),
                      groupcolormodel=Dict(:scheme=>:darkgreen),
                      yaxis=Axis(show=false),
                      legend=false,
                      clip=false
                      )

# Application - Dubai weather
dubai_weather = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                                 "..", "docs", "assets", "dubai_weather.csv"),
                                 types=Dict(1 =>Date))

modify!(dubai_weather, :date=>byrow(week)=>:Week)
setformat!(dubai_weather, :date=>month)

sgplot(
        dubai_weather,
        [
          BoxPlot(y=[:min, :max], category=:date, outliers=true),
          BoxPlot(y=:pressure, category=:Week, opacity=0.5, y2axis=true, outliers=true, x2axis=true)
        ],
        xaxis=Axis(title="Month"),
        yaxis=Axis(title="Temperature"),
        y2axis=Axis(title="Pressure", d3format="f"),
        x2axis=Axis(values=3:4:53),
        height=600
      )