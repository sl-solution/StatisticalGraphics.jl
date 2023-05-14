# ---
# title: Line segments
# id: demo_segment
# description: Using the `Segment` mark to produce line segments
# cover: assets/segment_1.svg
# ---

using InMemoryDatasets, StatisticalGraphics, DLMReader

svg("assets/segment_1.svg", sgplot(Dataset(y=1:1:4, low=rand(4), up=rand(4) .+ 1.3), [Segment(y=:y, lower=:low, upper=:up), Scatter(y=:y, x=:low, symbol=:stroke, angle=90), Scatter(y=:y, x=:up, symbol=:stroke, angle=90), RefLine(values=1, axis=:xaxis, dash=[2])], width=100, height=100, xaxis=Axis(offset=0, domain=true,labelcolor=:black, tickcolor=:black,titlecolor=:white, padding=10), yaxis=Axis(offset=0,domain=true,labelcolor=:black, tickcolor=:black,titlecolor=:white, tickcount=5, padding =10), legend=false, clip=false)) #hide #md

# `Segment` produces line segments. For each segment the main coordinate and the lower and the upper value must be supplied.

ds = Dataset(y=1:10, low=rand(10), up=rand(10) .+ 1.3)
sgplot(ds,
        Segment(y=:y, lower=:low, upper=:up),
        clip=false
      )



# Overlay Scatter plot

cars = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                                 "..", "docs", "assets", "cars.csv"),
                                 types=Dict(9=>Date))
cars_sum = combine(groupby(cars, :Origin), 1=>[IMD.mean, IMD.maximum, IMD.minimum])

sgplot(cars_sum,
                [
                    Segment(y=:Origin, lower=r"^min", upper=r"^max"),
                    Scatter(y=:Origin, x=r"^mean"),
                    Scatter(y=:Origin, x=r"^min", symbol=:stroke, angle=90),
                    Scatter(y=:Origin, x=r"^max", symbol=:stroke, angle=90)
                ],
                xaxis=Axis(title="Acceleration", padding=10),
                yaxis=Axis(padding=.5)
        )

# `Segment` like other plots accept `group`.

ohlc = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                                 "..", "docs", "assets", "ohlc.csv"),
                                 types = Dict(2=>Date, 8=>Symbol))

sgplot(ohlc,
        Segment(x=:date, lower=:low, upper=:high, group=:c),
        groupcolormodel=ohlc[:, :c],
        xaxis=Axis(type=:time),
        yaxis=Axis(title="")
      )

# Candlestick Chart

sgplot(ohlc,
        [
            Segment(x=:date, lower=:open, upper=:close, group=:c, thickness=5),
            Segment(x=:date, lower=:low, upper=:high, group=:c)           
        ],
        groupcolormodel=ohlc[:, :c],
        xaxis=Axis(type=:time),
        yaxis=Axis(title=""),
        legend=false
      )