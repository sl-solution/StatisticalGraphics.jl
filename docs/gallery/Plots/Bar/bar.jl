# ---
# title: Simple Bar chart
# id: demo_bar_chart1
# description: Using the `Bar` mark to produce Bar charts
# cover: assets/bar_chart1.svg
# ---

using InMemoryDatasets, StatisticalGraphics, DLMReader

svg("assets/bar_chart1.svg", sgplot(Dataset(x=1:5), Bar(x=:x, response=:x, colorresponse=:x, colorstat=sum, colormodel=Dict(:scheme=>:blues)), width=100, height=100, xaxis=Axis(offset=0, domain=false,labelcolor=:black, tickcolor=:white,titlecolor=:white), yaxis=Axis(offset=0,domain=false,labelcolor=:white, tickcolor=:white,titlecolor=:white), legend=false)) #hide #md

# `Bar` produces bar chart, by default it assigns the frequency of each value to the height of the corresponding bar

movies = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                                 "..", "docs", "assets", "movies.csv"),
                                 dlmstr="::")
sgplot(movies, Bar(x="Major Genre"))

# To produce horizontal bar chart, pass the analysis variable to `y`

sgplot(movies, Bar(y="Major Genre"))

# A `response` column can be pass to `Bar` when the analysis variable is different from categories. By default the sum of the `response` column will be used as the height of each bar. User can pass any function in the form of `(f, x)->...` to `stat` to customise the aggregation of `response`

##IMD.maximum handles missing values
sgplot(movies, Bar(y="Major Genre", response="Worldwide Gross", stat=IMD.maximum))


# User can control the order of bars by passing `orderresponse`. `Bar` automatically aggregate the values of `orderresponse` in each category and arrange the category in the final output accordingly.

sgplot(movies, Bar(y="Major Genre", response="Worldwide Gross",
                     stat=IMD.maximum, orderresponse="Worldwide Gross",
                     orderstat=IMD.maximum))
