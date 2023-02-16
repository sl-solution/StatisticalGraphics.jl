# ---
# title: Label Bars
# id: demo_bar_chart4
# description: Label Bars and related keyword arguments
# cover: assets/bar_chart4.svg
# ---

using InMemoryDatasets, StatisticalGraphics, DLMReader

svg("assets/bar_chart4.svg", sgplot(Dataset(x=repeat(1:5, inner=2), y=[5,6,7,8,6,3,2,4,2,1], g=repeat(1:2, 5),z=[-5,0,-7,0,-6,0,-4,0,-2,0]), Bar(y=:x, response=:y, group=:g, normalize=true, label=:height, labeld3format=".0%", labelpos=:middle, labelcolor=:auto), nominal=:g, yaxis=Axis(reverse=true, domain=false, titlecolor=:white, labelcolor=:white, tickcolor=:white), xaxis=Axis(domain=true, offset=5, titlecolor=:white, tickcolor=:white, d3format="%"), width=100, height=100, legend=false, groupcolormodel=Dict(:scheme=>:darkred))) #hide #md


# Change the location and postion of labels

cars = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                              "..", "docs", "assets", "cars.csv"))

sgplot(cars, Bar(y=:Origin, barwidth=0.7, label=:category,
                    labelpos=:start, labelloc=0, barcorner=[0,5,0,5]),
                    yaxis=Axis(show=false),
                    clip=false,
                    height=200,
                    width=200)


# Using the multiple charts to set multiple labels

sgplot(cars, [
                Bar(y=:Origin, barwidth=0.7, label=:category,
                    labelpos=:start, labelloc=0, barcorner=[0,5,0,5]),
                Bar(y=:Origin, opacity=0, label=:height, labelcolor=:white,
                    labeloffset=-10)
             ],

                    yaxis=Axis(show=false),
                    clip=false,
                    height=200,
                    width=200)


# Label bars with negative heights

ds = Dataset(x=1:5, y=[1.2,-3.1,2,4.3,-.1])

sgplot(ds, Bar(x=:x, response=:y, label=:height,
                 labelbaseline=:bottom),
                 yaxis=Axis(title="y"),
                 width=200
)

# Label grouped bar charts

population = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                              "..", "docs", "assets", "population.csv"))

sex(x) = x == 1 ? "male" : "female" # format for :sex

setformat!(population, :sex => sex)

pop2000 = filter(population, :year, by = ==(2000))

sgplot(pop2000, Bar(y=:age, response=:people,
                         group=:sex, normalize=true, label=:height,
                         labelpos=:middle, labeld3format=".1%"),
                         xaxis=Axis(title="Population", d3format="%"),
                         yaxis=Axis(reverse=true))

# Simulated data

ds = Dataset(rand(1:4, 100, 2), :auto)

sgplot(ds, Bar(x=:x1, group=:x2, label=:height), nominal=:x2)

# Passing `labelcolor=:auto` to assign label color based on the contrast of colors

sgplot(ds, Bar(x=:x1, group=:x2, label=:height, labelcolor=:auto), nominal=:x2)

# example

ds = Dataset(rand(1:4, 100, 10), :auto)

sgplot(ds, Bar(y=:x1, group=:x3, label=:height,
                labelcolor=:auto, response=:x2, space=0.1,
                labelpos=:middle, barcorner=10, normalize=true,
                labeld3format=".1%", outlinecolor=:black,
                groupspace=0.1, groupdisplay=:cluster),
                groupcolormodel=Dict(:scheme=>:darkgreen),
                xaxis=Axis(title="Normalized sum of x2", domain=false, d3format="%"),
                yaxis=Axis(domain=false, ticksize=0, order=:ascending),
                legend=false,
                clip=false)