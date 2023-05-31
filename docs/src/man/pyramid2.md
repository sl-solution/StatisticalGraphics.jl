# Example

Using `sgmanipulate` and `sggrid` to produce an interactive graph.
In the following example, we pass `rangetype = :year` to make sure that the input type for `:year` is of range type.

```@example
using InMemoryDatasets, DLMReader, StatisticalGraphics, Chain

population = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                              "..", "docs", "assets", "population.csv"))

function f_plot(gds)
    if gds[1,:sex] == 1
        r=false
        cl=:darkred
        title="Male population"
        yax=Axis(
                titlepos=[-20,0], titleangle=0,
                align=:center, labelpadding=20,
                ticks=false,
                domain=false
                )
    else
        r=true
        cl=:darkblue
        title="Female population"
        yax=Axis(show=false)
    end
    pl=@chain gds begin
        groupby(:year)
        sgmanipulate(
                        Bar(
                            y=:age, response=:people,
                            color=cl,
                            barcorner=5
                        ),
                        width=300,
                        xaxis=Axis(title=title, d3format="s", reverse=r),
                        yaxis=yax,
                        rangetype=:year,
                        panelborder=false
        )
    end
    pl
end

@chain population begin
    groupby(:sex, rev=true)
    eachgroup
    sggrid([f_plot(gds) for gds in _]...)
end

```