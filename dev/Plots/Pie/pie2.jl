using InMemoryDatasets, StatisticalGraphics, DLMReader

ds = Dataset(x=[0.6, 0.4], done=["60%", missing])
sgplot(ds,
    [
        Pie(category=:x, response=:x,
            innerradius=0.7,
            startangle=-110,
            endangle=110,
            outlinecolor=:black,
            colormodel=[:steelblue, :transparent]
        ),
        Pie(category=:done,
            opacity=0,
            label=:category,
            labelpos=0,
            labelangle=0,
            labelsize=100,
            labelcolor=:gray
        )
    ],
    legend=false

)

ds = Dataset(x=1:39, y=[rand(1:39, 30) for _ in 1:39])
flatten!(ds, :y)
insertcols!(ds, :z=>rand(nrow(ds)))

sgplot(ds,
        Pie(category=:x, group=:y,
            response=:z,
            groupspace=0,
            innerradius=0.1,
            piecorner=10,
            colormodel=[:black, :white]),
        legend=false,
    )

cars = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                                 "..", "docs", "assets", "cars.csv"),
                                 types=Dict(9=>Date))

sgplot(cars,
           [
            Pie(category=:Cylinders,
                group=:Origin,
                groupspace=0.05,
                innerradius=0.1,
                label=:category,
                labelangle=0,
                piecorner=5
            ),
            Pie(category=:Origin,
                group=:Origin,
                innerradius=0.1,
                opacity=0,
                endangle=0.1,
                groupspace=0.05,
                label=:category,
                labelpos=1,
                labelbaseline=:bottom,
                labelsize=8
            )
           ],
    legend=false,
    clip=false
)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

