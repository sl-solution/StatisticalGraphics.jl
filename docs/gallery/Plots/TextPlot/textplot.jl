# ---
# title: TextPlot
# id: demo_text1
# description: Put text on a graph
# cover: assets/text1.svg
# ---

using InMemoryDatasets, DLMReader, StatisticalGraphics

svg("assets/text1.svg", sgplot(Dataset(x=[1,2,3], y=[1,2,3], text='A':'C'), TextPlot(x=:x, y=:y, text=:text), width=100, height=100, xaxis=Axis(translate=0,offset=0, grid=false, griddash=[3], padding=10), yaxis=Axis(translate=0, grid=false, padding=10, offset=0, griddash=[3]), legend=false, clip=false)) #hide #md

# Example

ds = Dataset(x=rand(10), y=rand(10), text='A':'J')

sgplot(ds, TextPlot(x=:x, y=:y, text=:text))