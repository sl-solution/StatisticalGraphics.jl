using InMemoryDatasets, StatisticalGraphics, DLMReader

movies = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                                 "..", "docs", "assets", "movies.csv"),
                                 dlmstr="::")
sgplot(movies, Bar(x="Major Genre"))

sgplot(movies, Bar(y="Major Genre"))

##IMD.maximum handles missing values
sgplot(movies, Bar(y="Major Genre", response="Worldwide Gross", stat=IMD.maximum))

sgplot(movies, Bar(y="Major Genre", response="Worldwide Gross",
                     stat=IMD.maximum, orderresponse="Worldwide Gross",
                     orderstat=IMD.maximum))

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

