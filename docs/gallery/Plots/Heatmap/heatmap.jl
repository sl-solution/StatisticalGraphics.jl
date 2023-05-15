# ---
# title: Heatmap
# id: demo_heatmap1
# description: Drawing Heatmap (2D Histogram)
# cover: assets/heat1.svg
# ---

using InMemoryDatasets, DLMReader, StatisticalGraphics

svg("assets/heat1.svg", sgplot(Dataset(x=randn(1000),y=randn(1000)), Heatmap(x=:x, y=:y, xbincount=5, ybincount=5), width=100, height=100, xaxis=Axis(translate=0,offset=0, grid=true, griddash=[3]), yaxis=Axis(translate=0, grid=true, offset=0, griddash=[3]), legend=false)) #hide #md

# Example

ds = Dataset(x=randn(10000), y=randn(10000))

sgplot(ds, Heatmap(x=:x, y=:y))

