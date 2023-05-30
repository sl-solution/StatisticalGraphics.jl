using InMemoryDatasets, StatisticalGraphics, DLMReader, Chain

nations = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                                 "..", "docs", "assets", "nations.csv"),
                                 emptycolname=true, quotechar='"')
@chain nations begin
    filter(:year, by = ==(2010))
    sgplot(Scatter(x=:gdpPercap, y=:lifeExp, group=:region,
                                 labelresponse=:country))
end

@chain nations begin
    filter(:year, by = ==(2010))
    sgplot(Scatter(x=:gdpPercap, y=:lifeExp, group=:region,
                                 labelresponse=:country, labelsize=8,
                                 labelcolor=:group))
end

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

