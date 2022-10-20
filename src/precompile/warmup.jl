function warmup()
    ds = Dataset(x=rand(1:4, 1000), y=randn(1000), y2=randn(1000), group=rand(1:2, 1000))
    sgplot(ds, Scatter(x=:x, y=:y))
    sgplot(ds, Scatter(x=:x, y=:y, group=:group))
    sgplot(ds, [Line(x=:x, y=:y, group=:group), Scatter(x=:x, y=:y)], xaxis=Axis(show=false), font="Times")
    sgplot(ds, Bar(x = :x, response=:y2, stat=IMD.mean))
    sgplot(ds, Bar(x=:x, response=:y2, stat=IMD.mean, group=:group, groupdisplay=:cluster))
    sgplot(ds, Histogram(y=:y))
    sgplot(groupby(ds, 1), BoxPlot(y=r"y", category=:group, outliers = true), groupcolormodel = Dict(:scheme => "category20b"))
    nothing
end