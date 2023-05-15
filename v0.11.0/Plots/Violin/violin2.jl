using InMemoryDatasets, StatisticalGraphics, DLMReader

iris = filereader(joinpath(dirname(pathof(StatisticalGraphics)),

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

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

