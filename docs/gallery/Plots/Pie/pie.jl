# ---
# title: Pie chart
# id: demo_pie
# description: Using the `Pie` mark to produce Pie charts
# cover: assets/pie_1.svg
# ---

using InMemoryDatasets, StatisticalGraphics, DLMReader

svg("assets/pie_1.svg", sgplot(Dataset(x=1:4, y=[1,1,1.5,2]), Pie(category=:x, response=:y), width=150, height=100, legend=false)) #hide #md

# Pie chart shows the frequency of `category` in a data set as proportional slices of a whole circle

sgplot(Dataset(x=[1,2,3,3,4,4,4]),
             Pie(category=:x)
       )

# Users can pass a column as response for computing the slices based on the aggregated values of the passed column. The `stat` keyword argument is used to aggregate the values.

cars = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                                 "..", "docs", "assets", "cars.csv"),
                                 types=Dict(9=>Date))


sgplot(cars,
            Pie(category=:Origin, response=:Acceleration, stat=IMD.mean)
        )

# A column can be passed as `group` to produce a nested pie chart

sgplot(cars,
            
            Pie(category=:Cylinders,
                group=:Origin,
                groupspace=0.05,
                )
    )

# The donut chart is produced by passing `innerradius`

sgplot(cars,
            Pie(category=:Origin, innerradius=0.4)
        )

# Slices can be labeled based on their frequency and/or category


sgplot(cars,
            Pie(category=:Origin, label=:both)
        )