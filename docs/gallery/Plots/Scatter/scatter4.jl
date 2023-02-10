# ---
# title: Label points
# id: demo_scatterplot_label1
# description: Label observations on a scatter plot
# cover: assets/scatter_plot_label1.svg
# ---

using InMemoryDatasets, StatisticalGraphics, DLMReader, Chain

svg("assets/scatter_plot_label1.svg", sgplot(filter(filereader(joinpath(dirname(pathof(StatisticalGraphics)),"..", "docs", "assets", "nations.csv"), emptycolname=true, quotechar='"'), :year, by = ==(2010))[1:5:100, :], Scatter(x=:gdpPercap,y=:lifeExp, size=40, group=:region, labelresponse=:country, labelfont="Times", labelsize=8, labelcolor=:group), clip=false, xaxis=Axis(grid=true, domain=false, labelcolor=:white, titlecolor=:white, tickcolor=:white, gridcolor=:lightgray, gridthickness=0.4, offset=0, tickcount=10), yaxis=Axis(grid=true, gridcolor=:lightgray,gridthickness=0.4, offset=0, tickcount=10,domain=false, labelcolor=:white, titlecolor=:white, tickcolor=:white), width=100, height=100, legend=false)) #hide #md

# `Scatter` automatically put labels of data points around them when a column is passed as `labelresponse`.

# In the following example we use the country name to label data points. `Scatter` uses clever algorithms to avoid any overlaps between labels and points.

nations = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                                 "..", "docs", "assets", "nations.csv"),
                                 emptycolname=true, quotechar='"')
@chain nations begin
    filter(:year, by = ==(2010))
    sgplot(Scatter(x=:gdpPercap, y=:lifeExp, group=:region,
                                 labelresponse=:country))
end

# Users can control the appearance of labels by passing suitable keyword arguments. However, if users desire to match the color of labels and the points, they can pass `labelcolor=:group` or `labelcolor=:colorresponse` accordingly.

@chain nations begin
    filter(:year, by = ==(2010))
    sgplot(Scatter(x=:gdpPercap, y=:lifeExp, group=:region,
                                 labelresponse=:country, labelsize=8, 
                                 labelcolor=:group))
end