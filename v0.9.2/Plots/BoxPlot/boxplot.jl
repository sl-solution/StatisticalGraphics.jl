using InMemoryDatasets, StatisticalGraphics, DLMReader

iris = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                                 "..", "docs", "assets", "iris.csv"))
sgplot(iris, BoxPlot(x=1:4))

sgplot(iris, BoxPlot(x=1:4, outliers=true))

sgplot(iris, BoxPlot(y=1:4, outliers=true,
                        boxwidth=0.7,
                        whiskerdash=[0],
                        whiskercolor=:white,
                        fencecolor=:white,
                        outliersymbolsize=100),
                        width=300,
                        wallcolor=:black)

diamond = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                           "..", "docs", "assets", "diamonds.csv"))
carat_fmt(x) = round((searchsortedfirst(0.19:0.2:5.02, x)-2)*.2 + 0.3, digits=2)
setformat!(diamond, :carat=>carat_fmt)

sgplot(
        diamond,
        BoxPlot(y=:price, category =:carat,
                mediancolor=:black, medianthickness = 0.5,
                fencewidth=0,
                whiskerdash=[0], whiskerthickness = 0.5,

                outliers = true,
                outlierjitter = 5,
                outliersymbolsize=10,
                outliercolor=:black,
                outlieropacity=0.1
              ),
        yaxis=Axis(domain = false, nice=false, grid=true),
        groupcolormodel=["lightgray"],
        legend=false,
        width=800
      )

sgplot(iris, BoxPlot(x=1:4, category=5, outliers=true))

ds = Dataset(randn(100, 10), :auto)

insertcols!(ds, :Category=>rand(1:3, nrow(ds)))

sgplot(ds, BoxPlot(y=1:10, category=:Category,
                      whiskerdash=[0],
                      outlinethickness=0.3,
                      whiskerthickness=0.3),
                      groupcolormodel=Dict(:scheme=>:darkgreen),
                      yaxis=Axis(show=false),
                      legend=false,
                      clip=false
                      )

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

