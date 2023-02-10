using InMemoryDatasets, DLMReader, StatisticalGraphics

dubai_weather = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                                 "..", "docs", "assets", "dubai_weather.csv"),
                                 types=Dict(1 =>Date))
sgplot(dubai_weather, Line(x=:date, y=:pressure, breaks=true), xaxis=Axis(type=:date))

sgplot(dubai_weather, [Line(x=:date, y=:pressure, breaks=true), Scatter(x=:date, y=:pressure)], xaxis=Axis(type=:date))

ds = Dataset(x=1:10, y=rand(10))

color=Dict( :linear=>:blue,
            :basis=>:red,
            :step=>:green,
            :natural=>:darkorange
            )

sgplot(ds, [
            [
              Line(x=:x, y=:y, interpolate=v, thickness=2, color=color[v])
              for v in [:linear, :basis, :step, :natural]
            ]; Scatter(x=:x, y=:y, color=:steelblue, size=100)
            ],
            clip=false
        )

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

