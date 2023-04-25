using InMemoryDatasets, DLMReader, StatisticalGraphics

ds = Dataset(x=range(0,6,length=100))
modify!(ds, :x=>byrow(sin)=>:y)

sgplot(ds, Line(x=:x, y=:y))

dubai_weather = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                                 "..", "docs", "assets", "dubai_weather.csv"),
                                 types=Dict(1 =>Date))

first(dubai_weather, 6)

sgplot(dubai_weather, [Line(x=:date, y=:min), Line(x=:date, y=:max)], xaxis=Axis(type=:date))

sgplot(dubai_weather, [
                        Line(x=:date, y=:min),
                        Line(x=:date, y=:max),
                        Line(x=:date, y=:pressure, breaks=true, color=:red, y2axis=true)
                      ],
                        xaxis=Axis(type=:date))

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

