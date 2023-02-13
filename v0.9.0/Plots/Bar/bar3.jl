using InMemoryDatasets, StatisticalGraphics, DLMReader


population = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                              "..", "docs", "assets", "population.csv"))

sex(x) = x == 1 ? "male" : "female" # format for :sex

setformat!(population, :sex => sex)

pop2000 = filter(population, :year, by = ==(2000))

first(pop2000, 6)

tpop = transpose(groupby(pop2000, :age), :people, id = :sex)

setformat!(tpop, :female => -)

sgplot(tpop, [Bar(y=:age, response=:female),
                  Bar(y=:age, response=:male, color=:darkorange)],
                  yaxis=Axis(reverse=true),
                  xaxis=Axis(title="Population", values=((-12:3:12).*10^6, string.(abs.(-12:3:12), "M"))))

base_stat(f, x) = -last(x) # use the negative value of female pop as baseline

sgplot(pop2000, Bar(y=:age, response=:people, group=:sex,
                            baselineresponse = :people,
                            baselinestat=base_stat),
                            yaxis=Axis(reverse=true),
                            xaxis=Axis(title="Population", values=((-12:3:12).*10^6, string.(abs.(-12:3:12), "M"))))

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
              baselinestat=IMD.sum,
              orderresponse=:baseline,
              orderstat=IMD.sum,
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

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

