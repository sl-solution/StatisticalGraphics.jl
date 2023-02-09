using InMemoryDatasets, DLMReader, StatisticalGraphics

dubai_weather = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                                 "..", "docs", "assets", "dubai_weather.csv"),
                                 types=Dict(1 =>Date))
sgplot(dubai_weather, Line(x=:date, y=:pressure, breaks=true), xaxis=Axis(type=:date))

sgplot(dubai_weather, [Line(x=:date, y=:pressure, breaks=true), Scatter(x=:date, y=:pressure)], xaxis=Axis(type=:date))

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

