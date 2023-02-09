# ---
# title: Missing values and other features
# id: demo_line_plot3
# description: Breaking lines when data are missing
# cover: assets/line_plot3.svg
# ---

# Like other types, `Line` accepts `group` to produce lines with different color for each group of observations

using InMemoryDatasets, DLMReader, StatisticalGraphics

svg("assets/line_plot3.svg", sgplot(Dataset(x=range(-pi,pi,length=10), y=sin.(range(-pi,pi,length=10)), y2=cos.(range(-pi,pi,length=10)) ), [Line(x=:x, y=:y, thickness=1, interpolate=:natural), Scatter(x=:x,y=:y, size=30), Line(x=:x, y=:y2, thickness=1, interpolate=:natural, color=:darkorange), Scatter(x=:x,y=:y2, size=30, outlinecolor=:darkorange)], width=100, height=100, legend=false, xaxis=Axis(offset=0, grid=true, gridcolor=:white), yaxis=Axis(offset=0, padding=10, grid=true, gridcolor=:white), wallcolor=:lightgray, clip=false)) #hide #md

# By default `Line` ignores the missing values, however, passing `breaks=true` overrides this behaviour by making break when missing values encountered.

dubai_weather = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                                 "..", "docs", "assets", "dubai_weather.csv"),
                                 types=Dict(1 =>Date))
sgplot(dubai_weather, Line(x=:date, y=:pressure, breaks=true), xaxis=Axis(type=:date))


# Users can overlay a `Scatter` on top of a line plot to include marks at each combination of x and y.

sgplot(dubai_weather, [Line(x=:date, y=:pressure, breaks=true), Scatter(x=:date, y=:pressure)], xaxis=Axis(type=:date))

