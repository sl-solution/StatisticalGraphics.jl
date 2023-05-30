using InMemoryDatasets, StatisticalGraphics, DLMReader

sgplot(Dataset(x=[1,2,3,3,4,4,4]),
             Pie(category=:x)
       )

cars = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                                 "..", "docs", "assets", "cars.csv"),
                                 types=Dict(9=>Date))


sgplot(cars,
            Pie(category=:Origin, response=:Acceleration, stat=IMD.mean)
        )

sgplot(cars,

            Pie(category=:Cylinders,
                group=:Origin,
                groupspace=0.05,
                )
    )

sgplot(cars,
            Pie(category=:Origin, innerradius=0.4)
        )

sgplot(cars,
            Pie(category=:Origin, label=:both)
        )

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

