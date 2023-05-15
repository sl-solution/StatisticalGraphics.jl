# ---
# title: Combining with other plots
# id: demo_violin2
# description: Annotate `Violin` with other plots
# cover: assets/violin2.svg
# ---

using InMemoryDatasets, StatisticalGraphics, DLMReader

iris = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                                 "..", "docs", "assets", "iris.csv")) #hide #md
colors = [:steelblue, :darkorange, :darkred, :green] #hide #md
svg("assets/violin2.svg", sgplot(iris[1:5:100, :], reduce(vcat, [[Violin(x=i, category=5, color=:white, thickness=0.2), BoxPlot(x=i, category=5, boxwidth=0.1, whiskerdash=[0], outlinethickness=0.2, meansymbolsize=0, medianthickness=0.2), Scatter(x=i, y=5, jitter=[0,5], color=colors[i], outlinecolor=:white, opacity=0.5, size=10, thickness=0.2) ] for i in 1:4 ] ), wallcolor=:lightgray, xaxis=Axis(offset=0, grid=true, gridcolor=:white, values = [0,2,4,6,8], domain=false, ticksize=0), yaxis=Axis(offset=0, padding=0.1, domain=false, ticksize=0, title="", values=(["Iris-versicolor", "Iris-setosa"], ["ver", "set"])), groupcolormodel=colors, legend=false, width=100, height=100,font="Times", clip=false)) #hide #md


# Combingin with `BoxPlot` and `Scatter`

iris = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                                 "..", "docs", "assets", "iris.csv"))
colors = [:steelblue, :darkorange, :darkred, :green]
sgplot(
        iris,
        reduce(vcat,
          [
            [
              Violin(x=i, category=5, color=:white),
              BoxPlot(x=i, category=5, boxwidth=0.1, whiskerdash=[0]),
              Scatter(x=i, y=5, jitter=[0,20], color=colors[i], outlinecolor=:white, opacity=0.5)
            ]
            for i in 1:4
          ]
            ),
        wallcolor=:lightgray,
        xaxis=Axis(offset=10, grid=true, gridcolor=:white, values = -1:9, domain=false, ticksize=0),
        yaxis=Axis(offset=10, padding=0.1, domain=false, ticksize=0),
        groupcolormodel=colors,
        font="Times"
      )