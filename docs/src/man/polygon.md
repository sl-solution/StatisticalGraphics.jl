# Example

```@example
using InMemoryDatasets, StatisticalGraphics

function npolygon(n, sangle, radius)
    stepsize = 360 / n
    res = Vector{Tuple{Float64,Float64}}(undef, n)
    for i in 1:n
        degree = (i - 1) * stepsize + sangle
        res[i] = (cosd(degree) * radius, sind(degree) * radius)
    end
    res
end


ds = Dataset(sangle=range(0, 500, step=10))
insertcols!(ds, :radius => [0.95^i for i in 0:nrow(ds)-1])
insertcols!(ds, :n => (3:8...,))
flatten!(ds, :n)
modify!(ds, (3, 1, 2) => byrow(npolygon) => :polygon)
modify!(ds, :polygon => byrow(x -> 1:length(x)) => :vert)
flatten!(ds, [:polygon, :vert])
modify!(ds, :polygon => splitter => [:x, :y])
modify!(ds, :radius => byrow(x -> 1.1 - x) => :opacity)

sgmanipulate(groupby(ds, :n),
             Polygon(x=:x, y=:y, id=:sangle,
                        opacityresponse=:opacity,
                        colorresponse=:opacity,
                        outlinecolor=:white,
                        outlinethickness=0.5
                    ),
                    nominal=:opacity,
                    width=400,
                    xaxis=Axis(show=false),
                    yaxis=Axis(show=false),
                    legend=false,
                    wallcolor=:lightgray
            )
```