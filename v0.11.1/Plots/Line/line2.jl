using InMemoryDatasets, DLMReader, StatisticalGraphics


stocks = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                                 "..", "docs", "assets", "stocks.csv"),
                                 types=Dict(2=>Date))

first(stocks, 6)

sgplot(stocks, Line(x=:date, y=:price, group=:symbol), xaxis=Axis(type=:date))

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

