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
