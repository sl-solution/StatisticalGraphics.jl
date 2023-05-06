# Fitting Regression Line

## Movies data

```@example
using InMemoryDatasets, DLMReader, StatisticalGraphics, Chain

movies = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                              "..", "docs", "assets", "movies.csv"),
                              dlmstr="::")

rename!(movies, "Major Genre"=>"Genre")

@chain movies begin
    delete("Genre", by=contains("Concert"), missings=false)
    groupby("Genre")
    sgmanipulate(
        [
            Scatter(x="Rotten Tomatoes Rating", y="IMDB Rating",
                        size=10,
                        labelresponse=:Title,
                        labelsize=5,
                        tooltip=true
            ),
            Reg(
                x="Rotten Tomatoes Rating", y="IMDB Rating",
                degree=3,
                clm=true,
            )
        ],
        xaxis=Axis(grid=true, gridcolor=:white),
        yaxis=Axis(grid=true, gridcolor=:white),
        width=400,
        wallcolor=:lightgray,
        clip=false
    )
end
```