using InMemoryDatasets, StatisticalGraphics, DLMReader

iris = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                                 "..", "docs", "assets", "iris.csv"))



sgplot(iris, Reg(x=:SepalLength, y=:SepalWidth))

sgplot(iris, [
    Reg(x=:SepalLength, y=:SepalWidth),
    Scatter(x=:SepalLength, y=:SepalWidth)
    ],
    clip=false
)

sgplot(iris, [
    Reg(x=:SepalLength, y=:SepalWidth, degree=3),
    Scatter(x=:SepalLength, y=:SepalWidth)
    ],
    clip=false
)

sgplot(iris, [
    Reg(
        x=:SepalLength, y=:SepalWidth,
        degree=3,
        clm=true,
        cli=true
        ),
    Scatter(x=:SepalLength, y=:SepalWidth)
    ],
    clip=false
)

sgplot(iris, [
    Reg(
        x=:SepalLength, y=:SepalWidth,
        degree=3,
        clm=true,
        cli=true,
        group=:Species
        ),
    Scatter(x=:SepalLength, y=:SepalWidth)
    ],
    clip=false
)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

