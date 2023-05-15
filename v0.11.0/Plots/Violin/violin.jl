using InMemoryDatasets, StatisticalGraphics, DLMReader

iris = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                                 "..", "docs", "assets", "iris.csv"))
sgplot(iris, Violin(x=1:4))

sgplot(iris, Violin(x=1:4, side=:top))

sgplot(iris, Violin(x=1:4, category=5))

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

