# ---
# title: Diverging stacked bar chart
# id: demo_bar_chart3
# description: Producing Diverging stacked  bar chart using baseline keyword and overlaid bar charts
# cover: assets/bar_chart3.svg
# ---

using InMemoryDatasets, StatisticalGraphics, DLMReader

svg("assets/bar_chart3.svg", sgplot(Dataset(x=repeat(1:5, inner=2), y=[5,6,7,8,6,7,4,4,2,1], g=repeat(1:2, 5),z=[-5,0,-7,0,-6,0,-4,0,-2,0]), Bar(y=:x, response=:y, group=:g, baselineresponse=:z, baselinestat=sum, space=0), nominal=:g, yaxis=Axis(reverse=true, domain=false, titlecolor=:white, labelcolor=:white, tickcolor=:white), xaxis=Axis(domain=false, titlecolor=:white, values=([-4,4], ["Male", "Female"]), tickcolor=:white), width=100, height=100, legend=false, )) #hide #md

population = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                              "..", "docs", "assets", "population.csv"))

sex(x) = x == 1 ? "male" : "female" # format for :sex

setformat!(population, :sex => sex)

pop2000 = filter(population, :year, by = ==(2000))

first(pop2000, 6)
# Creating population pyramid using overlaid bar charts

tpop = transpose(groupby(pop2000, :age), :people, id = :sex)

setformat!(tpop, :female => -)

sgplot(tpop, [Bar(y=:age, response=:female),
                  Bar(y=:age, response=:male, color=:darkorange)],
                  yaxis=Axis(reverse=true),
                  xaxis=Axis(title="Population", values=((-12:3:12).*10^6, string.(abs.(-12:3:12), "M"))))

# For this example we can also use the `baselineresponse` keyword argument to create the pyramid.

# We pass `values` to xaxis to make sure the labels are shown properly

base_stat(f, x) = -last(x) # use the negative value of female pop as baseline

sgplot(pop2000, Bar(y=:age, response=:people, group=:sex,
                            baselineresponse = :people,
                            baselinestat=base_stat),
                            yaxis=Axis(reverse=true),
                            xaxis=Axis(title="Population", values=((-12:3:12).*10^6, string.(abs.(-12:3:12), "M"))))

# **[Stacked Bar Chart, Diverging](https://observablehq.com/@d3/diverging-stacked-bar-chart)**

# Reproducing an example from the [`D3`](http://d3js.org)`s examples collection.

# Using the `baselineresponse` keyword argument to control the baseline of bars in each category.

ds = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                              "..", "docs", "assets", "politifact.csv"))
ds_order = Dataset(ruling = ["true", "mostly-true", "half-true","barely-true", "false", "full-flop", "pants-fire"], 
                  Ruling = ["True", "Mostly true", "Half true", "Mostly false", "False", "False", "Pants on fire!"],
                  order = 1:7,
                  weight = [0,0,0,-1,-1,-1,-1])
leftjoin!(ds, ds_order, on = :ruling)
sort!(ds, [:order], rev=true) # order Ruling
modify!(
        groupby(ds, :speaker), 
        :count=> x->x ./ IMD.sum(x), # normalise counts
        [:count, :weight]=> byrow(prod) =>:baseline
        )

sgplot(
        ds,
        [
          Bar(y=:speaker, response=:count,
              group=:Ruling,
              grouporder=:data,
              baselineresponse=:baseline,
              orderresponse=:baseline,
              outlinethickness=0.1,
              legend = :bar_leg,
              x2axis=true
            ),
          RefLine(values = 0.0, axis=:x2axis)
        ],
        x2axis=Axis(title = "← more lies · Truthiness · more truths →", domain = false, d3format="%", nice=false, grid=true),
        yaxis=Axis(title = "", domain = false, ticks = false),
        legend = Legend(name = :bar_leg, title = "", orient=:top, columns=0, size=200, columnspace = 10 ),
        width=800,
        height=200,
        groupcolormodel=["#d53e4f", "#fc8d59", "#fee08b", "#e6f598", "#99d594", "#3288bd"]
    )