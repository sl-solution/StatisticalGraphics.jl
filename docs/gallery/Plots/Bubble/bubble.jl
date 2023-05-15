# ---
# title: Bubble plot
# id: demo_bubble1
# description: Scatter plot with varying size
# cover: assets/bubble1.svg
# ---

using InMemoryDatasets, StatisticalGraphics, DLMReader, Chain

svg("assets/bubble1.svg", sgplot(filter(filereader(joinpath(dirname(pathof(StatisticalGraphics)),"..", "docs", "assets", "nations.csv"), emptycolname=true, quotechar='"'), :year, by = ==(2010))[1:3:150, :], Bubble(x=:gdpPercap,y=:lifeExp, size=:population, colorresponse=:region, labelfont="Times", labelsize=8, labelcolor=:group, thickness=0.1, maxsize=20, outlinecolor=:white), clip=false, xaxis=Axis(grid=true, domain=false, labelcolor=:white, titlecolor=:white, tickcolor=:white, gridcolor=:lightgray, gridthickness=0.2, offset=0, tickcount=10, type=:log), yaxis=Axis(grid=true, gridcolor=:lightgray,gridthickness=0.2, offset=0, tickcount=10,domain=false, labelcolor=:white, titlecolor=:white, tickcolor=:white), width=100, height=100, legend=false)) #hide #md


# `Bubble` is similar to `Scatter`, however, user can pass a `size` column to `Buble`

ds = Dataset(rand(20, 3), :auto)

sgplot(ds, Bubble(x=:x1, y=:x2, size=:x3), clip=false)


# `Bubble` support most of the keywords available to `Scatter`

nations = filereader(joinpath(dirname(pathof(StatisticalGraphics)),
                                 "..", "docs", "assets", "nations.csv"),
                                 emptycolname=true, quotechar='"')
                                 
@chain nations begin
  sort([:population, :continent], rev=[true, false]);
  filter(:year, by = ==(2010)); 
  sgplot(
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
          clip=false,
          xaxis=Axis(type=:log, nice=false),
      )
end