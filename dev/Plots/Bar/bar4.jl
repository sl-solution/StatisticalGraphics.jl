using InMemoryDatasets, StatisticalGraphics, DLMReader

cars = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                              "..", "docs", "assets", "cars.csv"))

sgplot(cars, Bar(y=:Origin, barwidth=0.7, label=:category,
                    labelpos=:start, labelloc=0, barcorner=[0,5,0,5]),
                    yaxis=Axis(show=false),
                    clip=false,
                    height=200,
                    width=200)

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

ds = Dataset(x=1:5, y=[1.2,-3.1,2,4.3,-.1])

sgplot(ds, Bar(x=:x, response=:y, label=:height,
                 labelbaseline=:bottom),
                 yaxis=Axis(title="y"),
                 width=200
)

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

ds = Dataset(rand(1:4, 100, 2), :auto)

sgplot(ds, Bar(x=:x1, group=:x2, label=:height), nominal=:x2)

sgplot(ds, Bar(x=:x1, group=:x2, label=:height, labelcolor=:auto), nominal=:x2)

ds = Dataset(rand(1:4, 100, 10), :auto)

sgplot(ds, Bar(y=:x1, group=:x3, label=:height,
                labelcolor=:auto, response=:x2, space=0.1,
                labelpos=:middle, barcorner=10, normalize=true,
                labeld3format=".1%", outlinecolor=:black,
                groupspace=0.1),
                groupcolormodel=Dict(:scheme=>:darkgreen),
                xaxis=Axis(title="Normalized sum of x2", domain=false, d3format="%"),
                yaxis=Axis(domain=false, ticksize=0, order=:ascending),
                legend=false,
                clip=false)

sgplot(ds, Bar(y=:x1, group=:x3, label=:height,
                labelcolor=:auto, response=:x2, space=0.1,
                labelpos=:middle, barcorner=10, normalize=true,
                labeld3format=".1%", outlinecolor=:black,
                groupspace=0.1),
                groupcolormodel=Dict(:scheme=>:darkgreen),
                xaxis=Axis(title="Normalized sum of x2", domain=false, d3format="%"),
                yaxis=Axis(domain=false, ticksize=0, order=:ascending),
                legend=false,
                clip=false)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

