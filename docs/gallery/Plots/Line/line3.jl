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

# multiple axes

sgplot(
        dubai_weather,
        [
          Band(x=:date, lower=:min, upper=:max),
          Line(x=:date, y=:min, color="#4682b4", thickness=1),
          Line(x=:date, y=:max, color="#ff7f0e", thickness=0.5),
          Line(x=:date, y=:pressure, color="#2ca02c", y2axis=true, breaks=true),
          Scatter(x=:date, y=:pressure, outlinecolor="#2ca02c", size=10, y2axis=true)
        ],
        xaxis=Axis(offset=10, type=:date, grid=true, griddash=[1, 1], title="Date"),
        yaxis=Axis(offset=10, grid=true, griddash=[1, 1], title="Temperature(°C)"),
        y2axis=Axis(offset=10, title="Pressure")
)

# The `interpolate` keyword argument can be used to intepolate line,

ds = Dataset(x=1:10, y=rand(10))

color=Dict( :linear=>:blue,
            :basis=>:red,
            :step=>:green,
            :natural=>:darkorange
            )

sgplot(ds, [
            [
              Line(x=:x, y=:y, interpolate=v, thickness=2, color=color[v])
              for v in keys(color)
            ]; Scatter(x=:x, y=:y, color=:steelblue, size=100)
            ],
            clip=false
        )
