# Introduction

The `sggrid` function positions a collection of Plots within a grid.

## Example

```@example
using InMemoryDatasets, StatisticalGraphics

ds = Dataset(x=randn(100), y=randn(100));
h_x = sgplot(ds, Histogram(x=:x, space=0), xaxis=Axis(show=false), yaxis=Axis(show=false), height=200);
h_y = sgplot(ds, Histogram(y=:y, space=0), xaxis=Axis(show=false), yaxis=Axis(show=false), width=200);
xy = sgplot(ds, Scatter(x=:x, y=:y), xaxis=Axis(domain=false), yaxis=Axis(domain=false));

sggrid(h_x, sggrid(xy, h_y), columns=1)
```