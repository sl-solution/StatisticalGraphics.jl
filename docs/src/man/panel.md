# Introduction

When a grouped data set is passed as the first argument of `sgplot`, a multiple panel graph is produced for each group of observations. Four types of layout can be used to arrange the produced plots.

## Panel

Plots are put side by side. user can control how many rows or column should be produced.

### Example

```@example

using InMemoryDatasets, StatisticalGraphics

panel_example = Dataset(rand(1:4, 1000, 10), :auto)

sgplot(
        groupby(panel_example, [:x5, :x6]), 
        Pie(category=:x7,
            label=:both,
            labelsize=8,
            innerradius=0.4
          ),
        width = 100,
        height = 100,
        columns=5,
        legend=false
      )
```

```@example
using InMemoryDatasets, DLMReader, StatisticalGraphics, Chain

movies = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                              "..", "docs", "assets", "movies.csv"),
                              dlmstr="::")
@chain movies begin
    delete("Major Genre", by = contains("Concert"), missings=false)
    groupby("Major Genre")
    sgplot(
            [
                Scatter(x="Rotten Tomatoes Rating", y="IMDB Rating", size=10),
                Reg(
                      x="Rotten Tomatoes Rating", y="IMDB Rating",
                      degree=3,
                      clm=true,
                    )
            ],
            xaxis=Axis(grid=true,gridcolor=:white),
            yaxis=Axis(grid=true,gridcolor=:white),
            height=200,
            width=200,
            columns=4,
            columnspace=15,
            rowspace=15,
            headercolname=false,
            headeroffset=-20,
            headercolor=:white,
            headersize=20,
            headeritalic=true,
            wallcolor=:lightgray,
            clip=false
          )
end
```


## Lattice

This layout is supported when two columns are selected to group data. One column will be used as the row column and the other one as the column.

### Example

Passing `layout=:lattice` change the default layout to `lattice`


```@example
using InMemoryDatasets, StatisticalGraphics

panel_example = Dataset(rand(1:4, 1000, 10), :auto)
sgplot(
        gatherby(panel_example, [:x3, :x4]), 
        Bar(x=:x1, group=:x2),
        nominal = [:x2],
        layout = :lattice,
        width = 100,
        height = 100
      )
```

```@example
using InMemoryDatasets, StatisticalGraphics

fun_example = Dataset(rand(1:4, 1000, 4), :auto)
sgplot(
        gatherby(fun_example, [:x3, :x4]), 
        Bar(x=:x1, group=:x2, barcorner=15),
        nominal = :x2,
        layout = :lattice,
        rowspace=5,
        columnspace=5,
        width = 100,
        height = 100,
        wallcolor=:lightgray,
        showheaders = false,
        xaxis=Axis(show=false),
        yaxis=Axis(show=false),
        legend=false,
        clip=false
      )
```

## Row

When one column is used to group data, this option can be used to put graphs in a row layout.

To produce a row layout, user must pass `layout=:row`

### Examples

```@example
using InMemoryDatasets, DLMReader, StatisticalGraphics

cars = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                              "..", "docs", "assets", "cars.csv"),
                            types = Dict(9=>Date))
make_fmt(x) = split(x)[1]
setformat!(cars, :Name => make_fmt)
sgplot(
        groupby(cars, :Cylinders), 
        Bar(response=:Horsepower, x=:Name,
            stat=IMD.mean,
            colorresponse=:Acceleration,
            colorstat=IMD.mean,
            orderresponse=:Horsepower,
            orderstat=IMD.maximum,
            outlinethickness=0.5,
            space=0,
            colormodel=["#d53e4f", "#fc8d59", "#fee08b", "#e6f598", "#99d594"]
          ),
          
        layout = :row,
        columnspace = 5,
        linkaxis=:y,
        proportional=true,

        stepsize=15,
        xaxis=Axis(title="Make", angle=-90, baseline=:middle, align=:right, ticksize=0, domain=false, titlepadding=20),
        yaxis=Axis(title="Horsepower", domain=false),
        
        headercolname = false,
        headersize=12,
        headerfontweight=900,
        
        height=400,
      )
```

## Column

When one column is used to group data, this option can be used to put graphs in a column layout.

To produce a row layout, user must pass `layout=:column`

**[U-District Cuisine Example](https://vega.github.io/vega/examples/u-district-cuisine/)**

Reproducing an example from the [`vega`](https://vega.github.io)`s examples collection.

```@example
using InMemoryDatasets, DLMReader, StatisticalGraphics

udistrict = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                              "..", "docs", "assets", "udistrict.csv"))
# contains some information - use to customise the appearance
udistrict_info = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                              "..", "docs", "assets", "udistrict_info.csv"),
                               quotechar='"')

# order data
leftjoin!(udistrict, udistrict_info, on = :key)
sort!(udistrict, :order)

# actual graph
sgplot(
        gatherby(udistrict, :names), 

        Density(x=:lat, type=:kernel, bw=0.0005, npoints=200,
                scale=(x; samplesize, args...)->x .* samplesize, # to match the scale in the original example
        
                group=:names,
                grouporder=:data,

                fillopacity=0.7, 
                color=:white
                ),
        yaxis=Axis(show=false),
        xaxis=Axis(title="",
                    grid=true,
                    griddash=[2],
                    values=([47.6516, 47.655363, 47.6584, 47.6614, 47.664924, 47.668519], ["Boat St.", "40th St.", "42nd St.", "45th St.", "50th St.", "55th St."])
                  ),
        
        layout=:column,
        width=800,
        height=70,
        rowspace=-50, # to force overlaps
        panelborder=false,
        
        headercolname=false,
        headerangle=0,
        headerloc=:start,
        headeralign=:left,
        
        # set the font for the whole graph
        font="Times",
        italic=true,
        fontweight=100,
        
        # change default colors
        groupcolormodel=udistrict_info[:, :color],
        
        legend=false
      )
```