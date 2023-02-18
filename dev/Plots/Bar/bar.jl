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

sgplot(movies, Bar(y="Major Genre", response="Worldwide Gross",
                     stat=IMD.maximum, orderresponse="Worldwide Gross",
                     orderstat=IMD.maximum, colorresponse="Worldwide Gross",
                     colorstat=mean,
                     colormodel=Dict(:scheme=>:blues)))

sgplot(movies, Bar(y="Major Genre", response="Worldwide Gross",
                     stat=IMD.maximum, orderresponse="Worldwide Gross",
                     orderstat=IMD.maximum, colorresponse="Worldwide Gross",
                     colorstat=mean,
                     colormodel=Dict(:scheme=>:browns),
                     barcorner=[0,5,0,5],
                     space=0.4,
                     outlinecolor=:black,
                     legend=:bar_leg,
                     missingmode=1
                     ),
                     xaxis=Axis(title="Maximum Worldwide Gross",
                        domain=false, d3format="\$,f", grid=true),
                     yaxis=Axis(domain=false, grid=true),
                     legend=Legend(name=:bar_leg, d3format="\$,f",
                        title="Average Worldwide Gross", orient=:bottom,
                     direction=:horizontal, gradientlength=600),
                     clip=false)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

