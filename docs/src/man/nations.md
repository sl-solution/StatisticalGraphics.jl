# Wealth and Health of nations

```@example
using InMemoryDatasets, DLMReader, StatisticalGraphics, Chain

nations = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                              "..", "docs", "assets", "nations.csv"),
                              emptycolname=true, quotechar='"')

@chain nations begin
  sort([:population, :continent], rev=[true, false]);
  groupby(:year); 
  sgmanipulate(
        Bubble(x=:gdpPercap,
                y=:lifeExp,
                colorresponse=:region,
                colormodel=:category,
                size=:population,
                outlinecolor=:white,
                labelresponse=:country,
                labelsize=8,
                labelcolor=:colorresponse,
                maxsize=70,
                tooltip=true
                ),
                showheaders=true,
                headercolor="#aaaaaa33",
                headersize=150,
                headeroffset=-400,
                xaxis=Axis(type=:log, nice=false, grid=true, gridthickness=0.1),
                yaxis=Axis(grid=true, gridthickness=0.1),
                width=600,
                height=600,
                clip=false,
                wallcolor=:black
            )
end
```