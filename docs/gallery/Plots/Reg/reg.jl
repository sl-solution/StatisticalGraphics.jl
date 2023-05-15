# ---
# title: Regression line
# id: demo_reg
# description: Fitting regression lines to data
# cover: assets/reg1.svg
# ---

using InMemoryDatasets, StatisticalGraphics, DLMReader

# User can use `Reg` to draw regression lines fitted to data

iris = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                                 "..", "docs", "assets", "iris.csv"))

svg("assets/reg1.svg", sgplot(iris, Reg(x=2,y=1,group=5, clm=true, degree=3), clip=false, wallcolor=:lightgray, xaxis=Axis(grid=true, gridcolor=:white, offset=0), yaxis=Axis(grid=true, gridcolor=:white, offset=0), width=100, height=100, legend=false)) #hide #md


sgplot(iris, Reg(x=:SepalLength, y=:SepalWidth))

# Use `Scatter` to add the scatter plot of data

sgplot(iris, [
    Reg(x=:SepalLength, y=:SepalWidth),
    Scatter(x=:SepalLength, y=:SepalWidth)
    ],
    clip=false
)

# Passing `degree` allows to control the degree of polynomial fitted to data

sgplot(iris, [
    Reg(x=:SepalLength, y=:SepalWidth, degree=3),
    Scatter(x=:SepalLength, y=:SepalWidth)
    ],
    clip=false
)

# `clm` and `cli` produce the confidence band (by default 95%) for mean and prediction, respectively

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


# `group` is supported

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