# ---
# title: Violin plot
# id: demo_violin1
# description: Using the `Violin` mark to produce Violin plot
# cover: assets/violin1.svg
# ---

using InMemoryDatasets, StatisticalGraphics, DLMReader

svg("assets/violin1.svg", sgplot(Dataset(randn(100, 4), :auto), Violin(y=1:4, whiskerdash=[0], outliers=true), width=100, height=100, xaxis=Axis(offset=0, domain=false,labelcolor=:black, tickcolor=:white,titlecolor=:white), yaxis=Axis(offset=0,domain=false,labelcolor=:white, tickcolor=:white,titlecolor=:white), legend=false, clip=false)) #hide #md

# `Violin` produces Violin plot

iris = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                                 "..", "docs", "assets", "iris.csv"))
sgplot(iris, Violin(x=1:4))


# Passing `side` allows to draw only half of the density curve

sgplot(iris, Violin(x=1:4, side=:top))


# `Violin` also support the `category` keyword argument

sgplot(iris, Violin(x=1:4, category=5))