using InMemoryDatasets, DLMReader, StatisticalGraphics

dubai_weather = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                                 "..", "docs", "assets", "dubai_weather.csv"),
                                 types=Dict(1 =>Date))
sgplot(dubai_weather, Line(x=:date, y=:pressure, breaks=true), xaxis=Axis(type=:date))

sgplot(dubai_weather, [Line(x=:date, y=:pressure, breaks=true), Scatter(x=:date, y=:pressure)], xaxis=Axis(type=:date))

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

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

