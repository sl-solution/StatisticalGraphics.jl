# Example

Using `sgmanipulate` to produce an interactive graph.
In the following example, we pass `rangetype = :year` to make sure that the input type for `:year` is of range type.

```@example
using InMemoryDatasets, DLMReader, StatisticalGraphics, Chain

population = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                              "..", "docs", "assets", "population.csv"))

sex(x) = x == 1 ? "male" : "female" # format for :sex

setformat!(population, :sex => sex)

base_stat(f, x) = -last(x) # use the negative value of female pop as baseline

@chain population begin
    groupby(:year)
    sgmanipulate(
                    Bar(
                        y=:age, response=:people, group=:sex,
                        baselineresponse = :people,
                        baselinestat=base_stat
                        ),
                        rangetype=:year,
                        xaxis=Axis(title="Population", values=((-12:3:12).*10^6, string.(abs.(-12:3:12), "M")))
                )
end
```