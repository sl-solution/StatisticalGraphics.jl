"""
    gradient(colors...; direction = [0,1,0,0])

A linear gradient interpolates colors along a line, from a starting point to an ending point. By default a linear gradient runs horizontally, from left to right. Use the direction to configure the gradient direction, e.g. [0,0,0,1] runs the gradient vertically. All coordinates are defined in a normalized [0, 1] coordinate space, relative to the bounding box of the item being colored.

## Examples
```julia
gradient()
gradient(:red, :white, :blue)
```
"""
function gradient(args...; direction = [0,1,0,0])
    res = Dict{Symbol, Any}()
    res[:gradient] = :linear
    res[:x1] = direction[1]
    res[:x2] = direction[2]
    res[:y1] = direction[3]
    res[:y2] = direction[4]
    if length(args) == 1
        stops = [0.0]
    else
        stops = range(0.0, 1.0, length = length(args))
    end
    res[:stops] = Dict{Symbol, Any}[]
    for (s, c) in zip(stops, args)
        push!(res[:stops], Dict(:offset=>s, :color=>c))
    end
    res
end

gradient(;direction=[0,1,0,0]) = gradient(:steelblue, :darkred; direction = direction)
