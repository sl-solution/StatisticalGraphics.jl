# ---
# title: Multiple lines
# id: demo_line_plot2
# description: Using extra columns to produce multiple lines
# cover: assets/line_plot2.svg
# ---

# Like other types, `Line` accepts `group` to produce lines with different color for each group of observations

using InMemoryDatasets, DLMReader, StatisticalGraphics

svg("assets/line_plot2.svg", sgplot(Dataset(x=repeat(1:4,inner=3), y=rand(12),g=repeat(1:4,outer=3)), Line(x=:x, y=:y, group=:g, thickness=3), nominal=:g, width=100, height=100, legend=false, xaxis=Axis(offset=0), yaxis=Axis(offset=0))) #hide #md

stocks = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                                 "..", "docs", "assets", "stocks.csv"),
                                 types=Dict(2=>Date))

first(stocks, 6)

sgplot(stocks, Line(x=:date, y=:price, group=:symbol), xaxis=Axis(type=:date))