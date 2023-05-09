const SG_current_theme = Ref{Symbol}(:default)

function set_theme!(th::Symbol)
    th in (:__ord, :__cat, :__doc) && throw(ArgumentError("The theme name is incorrect."))
    SG_current_theme[] = th
    @info "The default theme for StatisticalGraphics is changed to $(repr(th))."
end

__dic = Dict{Symbol, Any}

# SGKwds will be used to specify the mark properties.
# Every property must have the following keys: :default, :__ord, :__cat, :__doc
# :default provides the instructions for default behaviour
# :__ord provides the order of the property in the docstring
# :__cat provides the information about the category that the property belongs to in docstring
# :__doc is the actual text that will be used for the property's docstring
# for other themes, we can add the default value of the property by passing it to the name of the theme, e.g. :dark=>:white,
# which means mark should use `:white` as the default value if the theme is set to `:dark`
struct SGKwds 
    opts::__dic
    function SGKwds(args...)
        new(__dic(args...))
    end
end

function Base.getindex(d::SGKwds, k)
    get(d.opts[:k], SG_current_theme[], :default)
end

function Base.deepcopy(d::SGKwds)
    res=__dic()
    for (k, v) in d.opts
        push!(res, k => deepcopy(get(v, SG_current_theme[], v[:default])))
    end
    res
end

getdoc(d::SGKwds, k) = get(d.opts[:k], :__doc, nothing)
getcat(d::SGKwds, k) = get(d.opts[:k], :__cat, nothing)


function print_doc(sgkwds::SGKwds)
    sgk=sgkwds.opts
    # ords are float because we sometime like to squeeze categories in specific place
    ds = Dataset(allk=Symbol[], dfs=Any[], ords=Float64[], cat=String[], docs=String[])
    
    # first we collect every thing into a dataset
    for (k, v) in sgk
        push!(ds, [k, v[:default], v[:__ord], v[:__cat], v[:__doc]])
    end
    # we use ords to find the order of categories, and
    # within each category we sort the values of keys
    sort!(ds, [:ords, :allk])
    gds = gatherby(ds, :ords)
    res="""# Keyword arguments
    """
    for vds in eachgroup(gds)
        res *= "## $(vds[1,:cat])\n"
        for r in eachrow(vds)
            if !isempty(r[:docs])
                res *= " * `$(r[:allk])`: $(r[:docs]) "
                if r[:dfs] !== nothing
                    res *= "default: `$(repr(r[:dfs]))`\n\n"
                else
                    res *= "\n\n"
                end
            end
        end
    end
    res
end


    

Kwds_docs = Dict{Symbol, String}(
        :x2axis=>"When set to `true`, the top x-axis will be used for the current plot.",
        :y2axis=>"When set to `true`, the right y-axis will be used for the current plot.",
        :opacity=>"The mark opacity from 0 (transparent) to 1 (opaque).",
        :outlinethickness=>"The mark outline thickness.",
        :color=>"The default color for the mark. User can pass color's name as symbol (e.g. `:red`), as string (e.g. `\"red\"`), as HTML color value (e.g. `\"#4682b4\"`).",
        :color_grad=>"The default color for the mark. User can pass color's name as symbol (e.g. `:red`), as string (e.g. `\"red\"`), as HTML color value (e.g. `\"#4682b4\"`), or pass a gradient color using the `gradient()` function.",
        :colormodel => "It specifies the color scheme to use for the marks.",
        :outlinecolor=>"The mark's outline color.",
        :font=>"The font name for displaying text.",
        :fontsize=>"The font size for displaying text.",
        :italic=>"If `true` the italic style will be used for displaying text.",
        :fontweight=>"The font weight for displaying text, use 100 for thin font and 900 for the bold one.",
        :fontcolor=>"The text color.",
        :fontangle=>"The text angle.",
        :fontbaseline=>"The text baseline.",
        :fontalign=>"The text alignment.",
        :fontlimit=>"The maximum length of the text mark in pixels. The text value will be automatically truncated if the rendered size exceeds the limit.",
        :fontdir=>"The direction of the text, i.e. `:ltr` or `:rtl`.",
        :fontopacity=>"The text opacity.",
        :tooltip=>"A tooltip will be shown upon mouse hover.",
        :legend=>"User can pass a symbol to this keyword argument to indicate that more customisation will be passed for the legened of corresponding mark. User needs to provide the extra customisation via the `Legend` global keyword.",
        :clip=>"Indicates if the marks should be clipped.",
        :interpolate=>"The interplate function to use for drawing lines, e.g. `:linear`, `:basis`, `:natural`, `:step`, ...",
        :breaks=>"It causes a break in the line when a missing value is encountered."



)

bar_normalizer(x) = x ./ sum(x)

AXES_DEFAULT = SGKwds(
    :type => __dic(:default=> :linear, :__ord=>0, :__cat => "Scale information", :__doc=>"The scale to be used for the axis, e.g. `:linear`, `:point`, `:band`, `:time`, `:date`, `:log`, `:symlog`, `:sqrt`, `:power`,..."),   
    :exponent => __dic(:default=> nothing, :__ord=>0, :__cat => "Scale information", :__doc=>"When `type=:power`, this will be used to pass the exponent."),
    :show => __dic(:default=> true, :__ord=>1, :__cat => "Axis options", :__doc=>"When it is `false`, `domain`, `title`, `ticks`, `labels` are set to `false`."),
    :values => __dic(:default=> nothing, :__ord=>1, :__cat => "Axis options", :__doc=>"User can use the keyword argument to manually put ticks. When a tuple of vector is passed, the first element will be used for the location and the second one will be used as displayed values."),
    :color => __dic(:default=> :black, :__ord=>2, :__cat => "Axis appearance", :__doc=>Kwds_docs[:color]),
    :range => __dic(:default=> nothing, :__ord=>1, :__cat => "Axis options", :__doc=>"Allow to manually set the domain of the axis."),
    :reverse => __dic(:default=> false, :__ord=>1, :__cat => "Axis options", :__doc=>"Reverse the order of ticks."),
    :order => __dic(:default=> :data, :__ord=>1, :__cat => "Axis options", :__doc=>"Determine how to order ticks for discrete types axis, e.g. `:data`, `:ascending`, `:descending`."),
    :dropmissing => __dic(:default=> false, :__ord=>1, :__cat => "Axis options", :__doc=>"When `true` drops missings from discrete type axis domain."),
    :offset => __dic(:default=> 1, :__ord=>1, :__cat => "Axis options", :__doc=>"The value to offset the axis."),
    :padding => __dic(:default=> nothing, :__ord=>1, :__cat => "Axis options", :__doc=>"Padding to extend axis. For discrete type axis it should be between 0 and 1, and for other type it indicates the amount in pixel."),

    :domaincolor => __dic(:default=> nothing, :__ord=>3, :__cat => "Domain properties", :__doc=>Kwds_docs[:color]),
    :domain => __dic(:default=> true, :__ord=>3, :__cat => "Domain properties", :__doc=>"If `false` the domain line would not be shown."),
    :domainthickness => __dic(:default=> 1.01, :__ord=>3, :__cat => "Domain properties", :__doc=>"The domain line thickness."),
    :domaindash => __dic(:default=> [0], :__ord=>3, :__cat => "Domain properties", :__doc=>"The domain line dash."),

    :title => __dic(:default=> nothing, :__ord=>5, :__cat => "Title properties", :__doc=>"Axis title."),
    :titlecolor => __dic(:default=> nothing, :__ord=>5, :__cat => "Title properties", :__doc=>Kwds_docs[:fontcolor]),
    :titleloc => __dic(:default=> :middle, :__ord=>5, :__cat => "Title properties", :__doc=>"Title location, i.e. `:middle`, `:end`, `:start`."),
    :titlealign => __dic(:default=> nothing, :__ord=>5, :__cat => "Title properties", :__doc=>Kwds_docs[:fontalign]),
    :titleangle => __dic(:default=> nothing, :__ord=>5, :__cat => "Title properties", :__doc=>Kwds_docs[:fontangle]),
    :titlebaseline => __dic(:default=> nothing, :__ord=>5, :__cat => "Title properties", :__doc=>Kwds_docs[:fontbaseline]),
    :titlepos => __dic(:default=> nothing, :__ord=>5, :__cat => "Title properties", :__doc=>"Title position in the form of [x,y]."),
    :titlesize => __dic(:default=> nothing, :__ord=>5, :__cat => "Title properties", :__doc=>Kwds_docs[:fontsize]),
    :titlepadding => __dic(:default=> nothing, :__ord=>5, :__cat => "Title properties", :__doc=>"Title padding."),
    :titlefont => __dic(:default=> nothing, :__ord=>5, :__cat => "Title properties", :__doc=>Kwds_docs[:font]),
    :titleitalic => __dic(:default=> nothing, :__ord=>5, :__cat => "Title properties", :__doc=>Kwds_docs[:italic]),
    :titlefontweight => __dic(:default=> nothing, :__ord=>5, :__cat => "Title properties", :__doc=>Kwds_docs[:fontweight]),


    :tickcount => __dic(:default=> nothing, :__ord=>4, :__cat => "Ticks properties", :__doc=>"Number of ticks."),
    :ticks => __dic(:default=> true, :__ord=>4, :__cat => "Ticks properties", :__doc=>"If `false` the ticks will not be shown."),
    :ticksize => __dic(:default=> 5, :__ord=>4, :__cat => "Ticks properties", :__doc=>"Ticks size in pixel."),
    :tickcolor => __dic(:default=> nothing, :__ord=>4, :__cat => "Ticks properties", :__doc=>Kwds_docs[:color]),
    :tickthickness => __dic(:default=> 1.01, :__ord=>4, :__cat => "Ticks properties", :__doc=>"Tickness of ticks in pixel."),
    :tickdash => __dic(:default=> [0], :__ord=>4, :__cat => "Ticks properties", :__doc=>"Ticks dash style."),

    :grid => __dic(:default=> false, :__ord=>1.5, :__cat => "Grids", :__doc=>"Determine if the grids are shown."),
    :griddash => __dic(:default=> [0], :__ord=>1.5, :__cat => "Grids", :__doc=>"Grids dash style."),
    :gridthickness => __dic(:default=> 0.5, :__ord=>1.5, :__cat => "Grids", :__doc=>"Grids tickness."),
    :gridcolor => __dic(:default=> :lightgray, :__ord=>1.5, :__cat => "Grids", :__doc=>Kwds_docs[:color]),


    :nice => __dic(:default=> true, :__ord=>1, :__cat => "Axis options", :__doc=>"Automatically round axis domain to make it nice."),
    :d3format => __dic(:default=> nothing, :__ord=>1, :__cat => "Axis options", :__doc=>"Allow users to directly pass an axis format. It must follow the rules described in `d3.format()`."),
    :d3formattype => __dic(:default=> nothing, :__ord=>1, :__cat => "Axis options", :__doc=>"If values are time or date, this option can be used to control their format."),
    :labeloverlap => __dic(:default=> true, :__ord=>6, :__cat => "Labels properties", :__doc=>"If `true`, avoids overlapping of labels."),
    :angle => __dic(:default=> 0, :__ord=>6, :__cat => "Labels properties", :__doc=>Kwds_docs[:fontangle]),
    :baseline => __dic(:default=> nothing, :__ord=>6, :__cat => "Labels properties", :__doc=>Kwds_docs[:fontbaseline]),
    :align => __dic(:default=> nothing, :__ord=>6, :__cat => "Labels properties", :__doc=>Kwds_docs[:fontalign]),
    :showlabels => __dic(:default=> true, :__ord=>6, :__cat => "Labels properties", :__doc=>"If `false` the axis labels will not be shown."),
    :labelcolor => __dic(:default=> nothing, :__ord=>6, :__cat => "Labels properties", :__doc=>Kwds_docs[:fontcolor]),
    :labelpadding => __dic(:default=> nothing, :__ord=>6, :__cat => "Labels properties", :__doc=>"The extra padding between labels and ticks."),
    :labelsize => __dic(:default=> nothing, :__ord=>6, :__cat => "Labels properties", :__doc=>Kwds_docs[:fontsize]),
    :labelfont => __dic(:default=> nothing, :__ord=>6, :__cat => "Labels properties", :__doc=>Kwds_docs[:font]),
    :labelitalic => __dic(:default=> nothing, :__ord=>6, :__cat => "Labels properties", :__doc=>Kwds_docs[:italic]),
    :labelfontweight => __dic(:default=> nothing, :__ord=>6, :__cat => "Labels properties", :__doc=>Kwds_docs[:fontweight]),


    :font => __dic(:default=> nothing, :__ord=>2, :__cat => "Axis appearance", :__doc=>"The default font that will be used for all elements of the axis."),
    :italic => __dic(:default=> nothing, :__ord=>2, :__cat => "Axis appearance", :__doc=>"The default font style that will be used for all elements of the axis."),
    :fontweight => __dic(:default=> nothing, :__ord=>2, :__cat => "Axis appearance", :__doc=>"The default font weight that will be used for all elements of the axis."),

    :zindex => __dic(:default=> 0, :__ord=>7, :__cat=>"Miscellaneous", :__doc=>"If `1` puts the axis elements on top of other marks in the graph."),
    :translate => __dic(:default=> nothing, :__ord=>7, :__cat=>"Miscellaneous", :__doc=>"The translate amount of the axis, see `vega` documentations for more information."),
    # for internal use
    :label_scale => __dic(:default=> nothing, :__ord=>7, :__cat=>"Miscellaneous", :__doc=>""),

)

LEGEND_DEFAULT = SGKwds(
    :name => __dic(:default=> nothing, :__ord=>0, :__cat => "Legend identity", :__doc=>"The legend id which refers to a legend id of a plot."), 
    :title => __dic(:default=> nothing, :__ord=>5, :__cat => "Title properties", :__doc=>"Legend title."),
    :titlefont => __dic(:default=> nothing, :__ord=>5, :__cat => "Title properties", :__doc=>Kwds_docs[:font]),
    :titleitalic => __dic(:default=> nothing, :__ord=>5, :__cat => "Title properties", :__doc=>Kwds_docs[:italic]),
    :titlefontweight => __dic(:default=> nothing, :__ord=>5, :__cat => "Title properties", :__doc=>Kwds_docs[:fontweight]),
    :titlesize => __dic(:default=> nothing, :__ord=>5, :__cat => "Title properties", :__doc=>Kwds_docs[:fontsize]),
    :labelfont => __dic(:default=> nothing, :__ord=>6, :__cat => "Labels properties", :__doc=>Kwds_docs[:font]),
    :labelitalic => __dic(:default=> nothing, :__ord=>6, :__cat => "Labels properties", :__doc=>Kwds_docs[:italic]),
    :labelfontweight => __dic(:default=> nothing, :__ord=>6, :__cat => "Labels properties", :__doc=>Kwds_docs[:fontweight]),
    :labelsize => __dic(:default=> nothing, :__ord=>6, :__cat => "Labels properties", :__doc=>Kwds_docs[:fontsize]),
    :font => __dic(:default=> nothing, :__ord=>2, :__cat => "Legend appearance", :__doc=>"The default font that will be used for all elements of the legend."),
    :italic => __dic(:default=> nothing, :__ord=>2, :__cat => "Legend appearance", :__doc=>"The default font style that will be used for all elements of the legend."),
    :fontweight => __dic(:default=> nothing, :__ord=>2, :__cat => "Legend appearance", :__doc=>"The default font weight that will be used for all elements of the legend."),
    :d3format => __dic(:default=> nothing, :__ord=>1, :__cat => "Legend options", :__doc=>"Allow users to directly pass a legend format. It must follow the rules described in `d3.format()`."),
    :d3formattype => __dic(:default=> nothing, :__ord=>1, :__cat => "Legend options", :__doc=>"If values are time or date, this option can be used to control their format."),
    :limit => __dic(:default=> nothing, :__ord=>1, :__cat => "Legend options", :__doc=>"The number of elements to be shown in the legend."),
    :orient => __dic(:default=> :right, :__ord=>2, :__cat => "Legend appearance", :__doc=>"The location of the legend. User can pass `[legendX, legendY]` for a precise location."),
    :symbol => __dic(:default=> nothing, :__ord=>2, :__cat => "Legend appearance", :__doc=>"Indicate the symbol for discrete type legends."),
    :columns => __dic(:default=> 1, :__ord=>2, :__cat => "Legend appearance", :__doc=>"The number of columns to be used to show the legend elements."),
    :direction => __dic(:default=> :vertical, :__ord=>2, :__cat => "Legend appearance", :__doc=>"The direction of the legend."),
    :size => __dic(:default=> 100, :__ord=>2, :__cat => "Legend appearance", :__doc=>"The legend element size."),
    :gradientlength => __dic(:default=> nothing, :__ord=>2, :__cat => "Legend appearance", :__doc=>"Control the size of a gradient type legend."),
    :gradientthickness => __dic(:default=> nothing, :__ord=>2, :__cat => "Legend appearance", :__doc=>"Control the size of a gradient type legend (width)."),
    :gridalign => __dic(:default=> :each, :__ord=>2, :__cat => "Legend appearance", :__doc=>"Control how to align multiple legends."),
    :rowspace => __dic(:default=> 1, :__ord=>2, :__cat => "Legend appearance", :__doc=>"The space between rows."),
    :columnspace => __dic(:default=> 1, :__ord=>2, :__cat => "Legend appearance", :__doc=>"The space between columns."),
    :values => __dic(:default=> nothing, :__ord=>1, :__cat => "Legend options", :__doc=>"Allow user manually provide the values for the legend."),
)

BAR_DEFAULT = SGKwds(
    :x => __dic(:default=> 0, :__ord=>0, :__cat => "Required", :__doc=>"User should pass a single column for plotting the bar chart. User must pass either this or the `y` argument."),
    :y => __dic(:default=> 0, :__ord=>0, :__cat=> "Required", :__doc=>"User should pass a single column for plotting the bar chart. User must pass either this or the `x` argument."),
    :group => __dic(:default=> nothing, :__ord=>2, :__cat=>"Grouping", :__doc=>"A grouped bar chart will be created by passing a single column to this argument."),
    :response => __dic(:default=> nothing, :__ord=>1, :__cat=>"Bar options", :__doc=>"A numeric column which its aggregated values based on the `stat` keyword argument will be used to determine the height of each bar."),
    :stat => __dic(:default=> nothing, :__ord=>1, :__cat=>"Bar options", :__doc=>"A function for aggregating the `response` keyword argument. When `response` is passed the default value of the keword change to `IMD.sum`, however, user can pass any function to this argument. The function must accept two arguments `f`(format), and `x` the input values and return the aggregated values."),
    :normalize =>__dic(:default=> false, :__ord=>1, :__cat=>"Bar options", :__doc=>"If `true` the bars will be normalized in each group. By default the total bar heights will be `1` in each group, however, user can pass customised function via `normalizer` to change this behaviour."),
    :normalizer => __dic(:default=> bar_normalizer, :__ord=>1, :__cat=>"Bar options", :__doc=>"This function will be used to normalize bar height within each group."),
    :x2axis => __dic(:default=> false, :__ord=>5, :__cat=>"Axes options", :__doc=>Kwds_docs[:x2axis]),
    :y2axis => __dic(:default=> false, :__ord=>5, :__cat=>"Axes options", :__doc=>Kwds_docs[:y2axis]),
    :opacity => __dic(:default=> 1, :__ord=>3, :__cat=>"Bar appearance", :__doc=>Kwds_docs[:opacity]),
    :outlinethickness => __dic(:default=> 1, :__ord=>3, :__cat=>"Bar appearance", :__doc=>Kwds_docs[:outlinethickness]),
    :barwidth => __dic(:default=> 1, :__ord=>3, :__cat=>"Bar appearance", :__doc=>"The bar width proportion with respect to the available space. It can be any number between 0 and 1. User can pass `:nest` too, which in this case the bar width will be automatically calculated for each group in such a way that the bar widths in each group will be smaller than the previous group. Users can pass `nestfactor` to control how fast they would like the bar width change for each group."),
    :nestfactor => __dic(:default=> nothing, :__ord=>3, :__cat=>"Bar appearance", :__doc=>"When the `barwidth` keyword is set to `:nest` this will control how much change should be applied to the current group barwidth compared to the previous one. By default this will be controlled automatically."),
    :color => __dic(:default=> "#4682b4", :__ord=>3, :__cat=>"Bar appearance", :__doc=>Kwds_docs[:color_grad]),
    :colorresponse =>__dic(:default=> nothing, :__ord=>1, :__cat=>"Bar options", :__doc=>"Name/index of a numeric column which will be used to change the fill color of each bar based on its values. The function passed to `colorstat` will be used to aggregate the values if there are more than one observation for a specific bar."),
    :colorstat => __dic(:default=> nothing, :__ord=>1, :__cat=>"Bar options", :__doc=>"The function that will be used to aggregate values in column passed as `colorresponse`."),
    :colormodel => __dic(:default=> :diverging, :__ord=>1, :__cat=>"Bar options", :__doc=>Kwds_docs[:colormodel]), # we use linear scale to produce colors
    :space => __dic(:default=> 0.1, :__ord=>3, :__cat=>"Bar appearance", :__doc=>"The space between bars. It can be any number between 0 and 1. "),  # the space between bars - the space is calculated as space * total_bandwidth
    :groupspace => __dic(:default=> 0.05, :__ord=>2, :__cat=>"Grouping", :__doc=>"The space between bars inside each group when `groupdisplay` is in (`:cluster`, `:step`)."), # the space between bars inside each group - for groupdisplay = :cluster
    :outlinecolor => __dic(:default=> :white, :__ord=>3, :__cat=>"Bar appearance", :__doc=>Kwds_docs[:outlinecolor]),
    :groupdisplay =>  __dic(:default=> :stack, :__ord=>2, :__cat=>"Grouping", :__doc=>"Indicate how to display bars in each group. It can be `:stack`, `:cluster`, `:step`, or `:none`."), #:stack, :cluster, :step (i.e. stacked and cluster), or :none
    :grouporder => __dic(:default=> :ascending, :__ord=>2, :__cat=>"Grouping", :__doc=>"How to order values in each group. It can be `:data`, `:ascending`, or `:descending`. User may also pass a vector of group levels to dictate the orders."), # :data, :ascending, :descending, userdefined order (by giving a vector of group level) - having a group column in panelby can cause some issues
    :orderresponse => __dic(:default=> nothing, :__ord=>1, :__cat=>"Bar options", :__doc=>"Name of a numeric column which will be used to change the order of bars. The function passed to `orderstat` will be used to aggregate the values if there are more than one observation for a specific bar. Note that the axis' order will override this."), # by default axis order control it, but it can be controlled by a column
    :orderstat => __dic(:default=> nothing, :__ord=>1, :__cat=>"Bar options", :__doc=>"The function that will be used to aggregate values in column passed as `orderresponse`."), # freq is default aggregator, however, it can be any other function 
    :baseline => __dic(:default=> 0, :__ord=>1, :__cat=>"Bar options", :__doc=>"The start value for drawing bars."),
    :baselineresponse => __dic(:default=> nothing, :__ord=>1, :__cat=>"Bar options", :__doc=>"Name/index of a numeric column which will be used to change the baseline of bars within each group. The function passed to `baselinestat` will be used to aggregate the values if there are more than one observation for a specific bar."),  # each bar (or each group when groupped) can have its own baseline 
    :baselinestat => __dic(:default=> nothing, :__ord=>1, :__cat=>"Bar options", :__doc=>"The function that will be used to aggregate values in column passed as `baselineresponse`."), # same rule as :stat

    #data label
    :label=>__dic(:default=> :none, :__ord=>4, :__cat=>"Bar labels", :__doc=>"What information should be used for bar labels. It can be `:none`, `:height`, or `:category`."), # :height or :category
    :labelfont=>__dic(:default=> nothing, :__ord=>4, :__cat=>"Bar labels", :__doc=>Kwds_docs[:font]),
    :labelbaseline=>__dic(:default=> nothing, :__ord=>4, :__cat=>"Bar labels", :__doc=>Kwds_docs[:fontbaseline]),
    :labelfontweight=>__dic(:default=> nothing, :__ord=>4, :__cat=>"Bar labels", :__doc=>Kwds_docs[:fontweight]),
    :labelitalic=>__dic(:default=> nothing, :__ord=>4, :__cat=>"Bar labels", :__doc=>Kwds_docs[:italic]),
    :labelsize=>__dic(:default=> nothing, :__ord=>4, :__cat=>"Bar labels", :__doc=>Kwds_docs[:fontsize]),
    :labelcolor=>__dic(:default=> :black, :__ord=>4, :__cat=>"Bar labels", :__doc=>"The text color. User can also pass `:group` or `:colorresponse` to use the corresponding scale for coloring the text."),# allow :group, :colorresponse to use their color if available 
    :labelangle=>__dic(:default=> nothing, :__ord=>4, :__cat=>"Bar labels", :__doc=>Kwds_docs[:fontangle]),
    :labeldir=>__dic(:default=> :ltr, :__ord=>4, :__cat=>"Bar labels", :__doc=>Kwds_docs[:fontdir]),
    :labellimit=>__dic(:default=> nothing, :__ord=>4, :__cat=>"Bar labels", :__doc=>Kwds_docs[:fontlimit]),
    :labeloffset=>__dic(:default=> 0, :__ord=>4, :__cat=>"Bar labels", :__doc=>"The amount in pixel to offset the labels."),
    :labelpos => __dic(:default=> :end, :__ord=>4, :__cat=>"Bar labels", :__doc=>"The position of labels within each bar. It can be `:end`, `:start`, or `:middle`."), # :end, :start, :middle
    :labelloc=>__dic(:default=> 0.5, :__ord=>4, :__cat=>"Bar labels", :__doc=>"relative location of the label within each bar. It can be any number between 0 and 1, where 0.5 means middle of the bar."), # between 0 and 1
    :labeld3format=>__dic(:default=> "", :__ord=>4, :__cat=>"Bar labels", :__doc=>"d3 format for labels."),
    :labelopacity=>__dic(:default=> 1, :__ord=>4, :__cat=>"Bar labels", :__doc=>Kwds_docs[:fontopacity]),
    :labelalign=>__dic(:default=> nothing, :__ord=>4, :__cat=>"Bar labels", :__doc=>Kwds_docs[:fontalign]),
    :labelalternate=>__dic(:default=> true, :__ord=>4, :__cat=>"Bar labels", :__doc=>"Use automatic alogirhtms to adjust the labels for bar with negative heights."), # if true, it automatically change the baseline, align and offset of the label text
    :tooltip => __dic(:default=> false, :__ord=>4, :__cat=>"Bar labels", :__doc=>Kwds_docs[:tooltip]), # it can be true, only if labelresponse is provided


    :legend => __dic(:default=> nothing, :__ord=>6, :__cat=>"Legend", :__doc=>Kwds_docs[:legend]),
    
    :barcorner => __dic(:default=> 0, :__ord=>3, :__cat=>"Bar appearance", :__doc=>"Corner radius for bars. (`cornerRadiusTopLeft`, `cornerRadiusTopRight`, `cornerRadiusBottomLeft`, `cornerRadiusBottomRight`)."), #corner radius (cornerRadiusTopLeft, cornerRadiusTopRight, cornerRadiusBottomLeft, cornerRadiusBottomRight)

    :missingmode => __dic(:default=> 0, :__ord=>1, :__cat=>"Bar options", :__doc=>"Indicate how to handle missing values in category or group.  `0` = nothing, `1` = no missing in category, `2` = no missing in group, `3` = no missing in category or group, `4` = no missing in category and group."),


    :clip => __dic(:default=> nothing, :__ord=>7, :__cat=>"Miscellaneous", :__doc=>Kwds_docs[:clip]),
)


BAND_DEFAULT = SGKwds(
    :x => __dic(:default=> 0, :__ord=>0, :__cat => "Required", :__doc=>"The column to be used as x coordinate. User must pass either this or the `y` argument."),
    :y => __dic(:default=> 0, :__ord=>0, :__cat=> "Required", :__doc=>"The column to be used as y coordinate. User must pass either this or the `x` argument."),
    :lower => __dic(:default=> 0, :__ord=>0, :__cat=> "Required", :__doc=>"The lower values for the band plot. User can pass a column or a Float value."),
    :upper => __dic(:default=> 0, :__ord=>0, :__cat=> "Required", :__doc=>"The upper values for the band plot. User can pass a column or a Float value."),
    :group => __dic(:default=> nothing, :__ord=>2, :__cat=>"Grouping", :__doc=>"The name of column for grouping observation. Each group of observations will create seperate band plot."),

    :x2axis => __dic(:default=> false, :__ord=>5, :__cat=>"Axes options", :__doc=>Kwds_docs[:x2axis]),
    :y2axis => __dic(:default=> false, :__ord=>5, :__cat=>"Axes options", :__doc=>Kwds_docs[:y2axis]),

    :opacity => __dic(:default=> 0.5, :__ord=>3, :__cat=>"Band appearance", :__doc=>Kwds_docs[:opacity]),
    :color => __dic(:default=>  "#4682b4", :__ord=>3, :__cat=>"Band appearance", :__doc=>Kwds_docs[:color_grad]),

    :interpolate => __dic(:default=>  :linear, :__ord=>1, :__cat=>"Band Options", :__doc=>Kwds_docs[:interpolate]),
    :breaks => __dic(:default=>  false, :__ord=>1, :__cat=>"Band Options", :__doc=>Kwds_docs[:breaks]),

    :legend => __dic(:default=> nothing, :__ord=>6, :__cat=>"Legend", :__doc=>Kwds_docs[:legend]),

    :clip => __dic(:default=> nothing, :__ord=>7, :__cat=>"Miscellaneous", :__doc=>Kwds_docs[:clip]),
)

SEGMENT_DEFAULT = SGKwds(
    :x => __dic(:default=> 0, :__ord=>0, :__cat => "Required", :__doc=>"The column to be used as x coordinate. User must pass either this or the `y` argument."),
    :y => __dic(:default=> 0, :__ord=>0, :__cat=> "Required", :__doc=>"The column to be used as y coordinate. User must pass either this or the `x` argument."),
    :lower => __dic(:default=> 0, :__ord=>0, :__cat=> "Required", :__doc=>"The lower values for segments. User can pass a column or a Float value."),
    :upper => __dic(:default=> 0, :__ord=>0, :__cat=> "Required", :__doc=>"The upper values for segments. User can pass a column or a Float value."),
    :group => __dic(:default=> nothing, :__ord=>2, :__cat=>"Grouping", :__doc=>"The name of column for grouping observation. Each group of observations will create seperate segment lines."),

    :x2axis => __dic(:default=> false, :__ord=>5, :__cat=>"Axes options", :__doc=>Kwds_docs[:x2axis]),
    :y2axis => __dic(:default=> false, :__ord=>5, :__cat=>"Axes options", :__doc=>Kwds_docs[:y2axis]),

    :opacity => __dic(:default=> 1, :__ord=>3, :__cat=>"Segment appearance", :__doc=>Kwds_docs[:opacity]),
    :color => __dic(:default=>  "#4682b4", :__ord=>3, :__cat=>"Segment appearance", :__doc=>Kwds_docs[:color_grad]),

    :thickness => __dic(:default=>  1, :__ord=>3, :__cat=>"Segment appearance", :__doc=>"The thickness of the mark"),

    :legend => __dic(:default=> nothing, :__ord=>6, :__cat=>"Legend", :__doc=>Kwds_docs[:legend]),

    :clip => __dic(:default=> nothing, :__ord=>7, :__cat=>"Miscellaneous", :__doc=>Kwds_docs[:clip]),
)

DENSITY_DEFAULT = SGKwds(
    :x => __dic(:default=> 0, :__ord=>0, :__cat => "Required", :__doc=>"The column to be used as x coordinate. User must pass either this or the `y` argument."),
    :y => __dic(:default=> 0, :__ord=>0, :__cat=> "Required", :__doc=>"The column to be used as y coordinate. User must pass either this or the `x` argument."),    
    :group => __dic(:default=> nothing, :__ord=>2, :__cat=>"Grouping", :__doc=>"The name of column for grouping observation. Each group of observations will create seperate density plot."),

    :x2axis => __dic(:default=> false, :__ord=>5, :__cat=>"Axes options", :__doc=>Kwds_docs[:x2axis]),
    :y2axis => __dic(:default=> false, :__ord=>5, :__cat=>"Axes options", :__doc=>Kwds_docs[:y2axis]),

    :interpolate => __dic(:default=>  :linear, :__ord=>1, :__cat=>"Density Options", :__doc=>Kwds_docs[:interpolate]),
    :type => __dic(:default=>  :normal, :__ord=>1, :__cat=>"Density Options", :__doc=>"Type of density fit, i.e. `:normal` or `:kernel`. "),
    :weights => __dic(:default=> :gaussian, :__ord=>1, :__cat=>"Density Options", :__doc=>"The weighting function to be used when `:kernel` type is selected."),
    :bw => __dic(:default=> nothing, :__ord=>1, :__cat=>"Density Options", :__doc=>"Band width to be used in the kernel density estimation."),
    :scale => __dic(:default=> :pdf, :__ord=>1, :__cat=>"Density Options", :__doc=>"user can pass any function to this option, the function must be in the form of `fun(density; midpoints, npoints, samplesize, binwidth)` , for `:pdf` the function is defined as `f(x; args...) = x`, for `:count` we compute the expected counts, `f(x; args...) = x .* binwidth .* npoints` , and for `:cdf` the function is `(x; binwidth, args...) -> cumsum(x .* binwidth)`."),
    :baseline => __dic(:default=> 0.0, :__ord=>1, :__cat=>"Density Options", :__doc=>"The baseline for filling the curve."),

    :opacity => __dic(:default=> 1, :__ord=>3, :__cat=>"Density appearance", :__doc=>"The opacity value for the outline."),

    :fillopacity => __dic(:default=> 0.5, :__ord=>3, :__cat=>"Density appearance", :__doc=>"The opacity value for the fill color."),
    :filled => __dic(:default=> true, :__ord=>3, :__cat=>"Density appearance", :__doc=>"Indicate if the curve should be filled."),
    :fillcolor => __dic(:default=> nothing, :__ord=>3, :__cat=>"Density appearance", :__doc=>Kwds_docs[:color_grad]),

    :color => __dic(:default=> nothing, :__ord=>3, :__cat=>"Density appearance", :__doc=>Kwds_docs[:color_grad]),
    :thickness => __dic(:default=> 1, :__ord=>3, :__cat=>"Density appearance", :__doc=>Kwds_docs[:outlinethickness]),
    
    :npoints => __dic(:default=> 100, :__ord=>1, :__cat=>"Density Options", :__doc=>"The number of points for the grid calculation."), 

   
    :legend => __dic(:default=> nothing, :__ord=>6, :__cat=>"Legend", :__doc=>Kwds_docs[:legend]),

    :clip => __dic(:default=> nothing, :__ord=>7, :__cat=>"Miscellaneous", :__doc=>Kwds_docs[:clip]),
)

REFLINE_DEFAULT = SGKwds(
    :values => __dic(:default=> 0, :__ord=>0, :__cat => "Required", :__doc=>"The position of reflines, it can be a vector of values."),
    :axis => __dic(:default=> nothing, :__ord=>0, :__cat => "Required", :__doc=>"WHich axis should be used to draw the reflines, i.e. `:xaxis`, `:x2axis`, `:yaxis`, `:y2axis`."),
    
    :opacity => __dic(:default=> 1, :__ord=>3, :__cat=>"Refline appearance", :__doc=>Kwds_docs[:opacity]),
    :thickness => __dic(:default=> 1, :__ord=>3, :__cat=>"Refline appearance", :__doc=>"The line thickness."),
    :color => __dic(:default=> :grey, :__ord=>3, :__cat=>"Refline appearance", :__doc=>Kwds_docs[:color_grad]),
    :dash => __dic(:default=> [0], :__ord=>3, :__cat=>"Refline appearance", :__doc=>"The line dash style."),
    :clip => __dic(:default=> nothing, :__ord=>7, :__cat=>"Miscellaneous", :__doc=>Kwds_docs[:clip]),
)

POLYGON_DEFAULT = SGKwds(
    :x => __dic(:default=> nothing, :__ord=>0, :__cat => "Required", :__doc=>"The x coordinate of the polygon."),
    :y => __dic(:default=> nothing, :__ord=>0, :__cat => "Required", :__doc=>"The y coordinate of the polygon."),
    :id => __dic(:default=> nothing, :__ord=>0, :__cat => "Required", :__doc=>"The function draw a seperate polygon for each unique value of `id`."),
    
    :opacity => __dic(:default=> 1, :__ord=>3, :__cat=>"Polygon appearance", :__doc=>Kwds_docs[:opacity]),
    :color => __dic(:default=> :steelblue, :__ord=>3, :__cat=>"Polygon appearance", :__doc=>Kwds_docs[:color_grad]),
    :interpolate => __dic(:default=>  :linear, :__ord=>1, :__cat=>"Polygon Options", :__doc=>Kwds_docs[:interpolate]),
    :outline => __dic(:default=>true, :__ord=>1, :__cat=>"Polygon Options", :__doc=>"If `true` an outline will be drawn for each polygon."),
    :outlinethickness => __dic(:default=> 1, :__ord=>3, :__cat=>"Polygon appearance", :__doc=>"The outline thickness."),
    :outlinedash => __dic(:default=> [0], :__ord=>3, :__cat=>"Polygon appearance", :__doc=>"The outline dash style."),
    :outlinecolor => __dic(:default=> :steelblue, :__ord=>3, :__cat=>"Polygon appearance", :__doc=>Kwds_docs[:color_grad]),
    :outlineopacity => __dic(:default=>1, :__ord=>3, :__cat=>"Polygon appearance", :__doc=>"The ouline opacity."),

    :opacityresponse => __dic(:default=> nothing, :__ord=>1, :__cat=>"Polygon Options", :__doc=>"The column which its values will be used to determine the opacity of polygons."),
    :colorresponse => __dic(:default=> nothing, :__ord=>1, :__cat=>"Polygon Options", :__doc=>"The column which its values will be used to determine the fill color of polygons."),

    :colormodel => __dic(:default=>:diverging, :__ord=>3, :__cat=>"Polygon appearance", :__doc=>"The color model which will be used for fill color when `colorresponse` is passed. It can be an scheme or a vector of colors."),

    :group => __dic(:default=> nothing, :__ord=>2, :__cat=>"Grouping", :__doc=>"The name of column for grouping observation. Each group of observations will create seperate polygon and polygons in each group will have different color."),
    :x2axis => __dic(:default=> false, :__ord=>5, :__cat=>"Axes options", :__doc=>Kwds_docs[:x2axis]),
    :y2axis => __dic(:default=> false, :__ord=>5, :__cat=>"Axes options", :__doc=>Kwds_docs[:y2axis]),  
    :legend => __dic(:default=> nothing, :__ord=>6, :__cat=>"Legend", :__doc=>Kwds_docs[:legend]),

    :clip => __dic(:default=> nothing, :__ord=>7, :__cat=>"Miscellaneous", :__doc=>Kwds_docs[:clip]),
)

LINE_DEFAULT = SGKwds(
    :x => __dic(:default=> 0, :__ord=>0, :__cat => "Required", :__doc=>"The column to be used as x coordinate."),
    :y => __dic(:default=> 0, :__ord=>0, :__cat=> "Required", :__doc=>"The column to be used as y coordinate."),    
    :group => __dic(:default=> nothing, :__ord=>2, :__cat=>"Grouping", :__doc=>"The name of column for grouping observation. Each group of observations will create seperate Line."),

    :opacity => __dic(:default=> 1, :__ord=>3, :__cat=>"Line appearance", :__doc=>Kwds_docs[:opacity]),
    :thickness => __dic(:default=> 1, :__ord=>3, :__cat=>"Line appearance", :__doc=>"The Line thickness."),
    :dash => __dic(:default=> [0], :__ord=>3, :__cat=>"Line appearance", :__doc=>"The Line dash style."),
    :color => __dic(:default=> "#4682b4", :__ord=>3, :__cat=>"Line appearance", :__doc=>Kwds_docs[:color_grad]),

    :interpolate => __dic(:default=>:linear, :__ord=>1, :__cat=>"Line Options", :__doc=>Kwds_docs[:interpolate]),
    :breaks => __dic(:default=>false, :__ord=>1, :__cat=>"Line Options", :__doc=>Kwds_docs[:breaks]),

    :x2axis => __dic(:default=> false, :__ord=>5, :__cat=>"Axes options", :__doc=>Kwds_docs[:x2axis]),
    :y2axis => __dic(:default=> false, :__ord=>5, :__cat=>"Axes options", :__doc=>Kwds_docs[:y2axis]),
    :xshift => __dic(:default=> 0, :__ord=>5, :__cat=>"Axes options", :__doc=>"Shift the mark in direction of x. Useful for discrete type axes."),
    :yshift => __dic(:default=> 0, :__ord=>5, :__cat=>"Axes options", :__doc=>"Shift the mark in direction of y. Useful for discrete type axes."),  
    :legend => __dic(:default=> nothing, :__ord=>6, :__cat=>"Legend", :__doc=>Kwds_docs[:legend]),

    :clip => __dic(:default=> nothing, :__ord=>7, :__cat=>"Miscellaneous", :__doc=>Kwds_docs[:clip]),
)

HISTOGRAM_DEFAULT = SGKwds(
    :x => __dic(:default=> 0, :__ord=>0, :__cat => "Required", :__doc=>"The column to be used as x coordinate. User must pass either this or the `y` argument."),
    :y => __dic(:default=> 0, :__ord=>0, :__cat=> "Required", :__doc=>"The column to be used as y coordinate. User must pass either this or the `x` argument."),    
    :group => __dic(:default=> nothing, :__ord=>2, :__cat=>"Grouping", :__doc=>"The name of column for grouping observation. Each group of observations will create seperate histogram plot."),

    :x2axis => __dic(:default=> false, :__ord=>5, :__cat=>"Axes options", :__doc=>Kwds_docs[:x2axis]),
    :y2axis => __dic(:default=> false, :__ord=>5, :__cat=>"Axes options", :__doc=>Kwds_docs[:y2axis]),

    :opacity => __dic(:default=> 1, :__ord=>3, :__cat=>"Histogram appearance", :__doc=>"The opacity value for the outline."),

    :outlinethickness => __dic(:default=> 1, :__ord=>3, :__cat=>"Histogram appearance", :__doc=>"The outline thickness."),
 

    :color => __dic(:default=> "#4682b4", :__ord=>3, :__cat=>"Histogram appearance", :__doc=>Kwds_docs[:color_grad]),
    :space => __dic(:default=> 1, :__ord=>3, :__cat=>"Histogram appearance", :__doc=>"Space between bars in pixel."),
    :outlinecolor => __dic(:default=> :white, :__ord=>3, :__cat=>"Histogram appearance", :__doc=>Kwds_docs[:color_grad]),

    
    :midpoints => __dic(:default=> :Sturges, :__ord=>1, :__cat=>"Histogram Options", :__doc=>"The location of midpoints. It can be a number to indicate the number of midpoints or a vector of midpoints."), 
    :scale => __dic(:default=> :pdf, :__ord=>1, :__cat=>"Histogram Options", :__doc=>"The scale to use for the bar heights, e.g. `:pdf`, `:cdf`, `:count`."), 
    
   
    :legend => __dic(:default=> nothing, :__ord=>6, :__cat=>"Legend", :__doc=>Kwds_docs[:legend]),

    :clip => __dic(:default=> nothing, :__ord=>7, :__cat=>"Miscellaneous", :__doc=>Kwds_docs[:clip]),
)

TEXT_DEFAULT = SGKwds(
    :x => __dic(:default=> nothing, :__ord=>0, :__cat => "Required", :__doc=>"The column to be used as x coordinate."),
    :y => __dic(:default=> nothing, :__ord=>0, :__cat=> "Required", :__doc=>"The column to be used as y coordinate."),   
    :text => __dic(:default=> nothing, :__ord=>0, :__cat=> "Required", :__doc=>"The column to be used as text values for each point."),    
 
    :group => __dic(:default=> nothing, :__ord=>2, :__cat=>"Grouping", :__doc=>"The name of column for grouping observation. Each group of observations will create seperate text plot."),

    :x2axis => __dic(:default=> false, :__ord=>5, :__cat=>"Axes options", :__doc=>Kwds_docs[:x2axis]),
    :y2axis => __dic(:default=> false, :__ord=>5, :__cat=>"Axes options", :__doc=>Kwds_docs[:y2axis]),
    
    :opacity => __dic(:default=> 1, :__ord=>3, :__cat=>"TextPlot appearance", :__doc=>Kwds_docs[:opacity]),

    :opacityresponse => __dic(:default=> nothing, :__ord=>1, :__cat=>"TextPlot Options", :__doc=>"The column which its values will be used to determine the opacity of text."),
    :angleresponse => __dic(:default=> nothing, :__ord=>1, :__cat=>"TextPlot Options", :__doc=>"The column which its values will be used to determine the angle of text."),
    :colorresponse => __dic(:default=> nothing, :__ord=>1, :__cat=>"TextPlot Options", :__doc=>"The column which its values will be used to determine the color of text."),
    
    :size => __dic(:default=> 10, :__ord=>3, :__cat=>"TextPlot appearance", :__doc=>Kwds_docs[:fontsize]),
    :font => __dic(:default=> nothing, :__ord=>3, :__cat=>"TextPlot appearance", :__doc=>Kwds_docs[:font]),
    :fontweight => __dic(:default=> nothing, :__ord=>3, :__cat=>"TextPlot appearance", :__doc=>Kwds_docs[:fontweight]),
    :italic => __dic(:default=> nothing, :__ord=>3, :__cat=>"TextPlot appearance", :__doc=>Kwds_docs[:italic]),
    :limit => __dic(:default=> nothing, :__ord=>3, :__cat=>"TextPlot appearance", :__doc=>Kwds_docs[:fontlimit]),
    :dir => __dic(:default=> :ltr, :__ord=>3, :__cat=>"TextPlot appearance", :__doc=>Kwds_docs[:fontdir]),
    :align => __dic(:default=> :left, :__ord=>3, :__cat=>"TextPlot appearance", :__doc=>Kwds_docs[:fontalign]),
    :textbaseline => __dic(:default=> :alphabetic, :__ord=>3, :__cat=>"TextPlot appearance", :__doc=>Kwds_docs[:fontbaseline]),
    :angle => __dic(:default=> 0, :__ord=>3, :__cat=>"TextPlot appearance", :__doc=>Kwds_docs[:fontangle]),
    :color => __dic(:default=> :black, :__ord=>3, :__cat=>"TextPlot appearance", :__doc=>Kwds_docs[:fontcolor]),
    :colormodel => __dic(:default=> :diverging, :__ord=>3, :__cat=>"TextPlot appearance", :__doc=>Kwds_docs[:colormodel]),

    :legend => __dic(:default=> nothing, :__ord=>6, :__cat=>"Legend", :__doc=>Kwds_docs[:legend]),

    :clip => __dic(:default=> nothing, :__ord=>7, :__cat=>"Miscellaneous", :__doc=>Kwds_docs[:clip]),
)

SCATTER_DEFAULT = SGKwds(
    :x => __dic(:default=> 0, :__ord=>0, :__cat => "Required", :__doc=>"The column to be used as x coordinate."),
    :y => __dic(:default=> 0, :__ord=>0, :__cat=> "Required", :__doc=>"The column to be used as y coordinate."), 
    :group => __dic(:default=> nothing, :__ord=>2, :__cat=>"Grouping", :__doc=>"The name of column for grouping observation. Each group of observations will create seperate scatter plot."),

    :opacity => __dic(:default=> 1, :__ord=>3, :__cat=>"Scatter appearance", :__doc=>Kwds_docs[:opacity]),
    :thickness => __dic(:default=> 1, :__ord=>3, :__cat=>"Scatter appearance", :__doc=>Kwds_docs[:outlinethickness]),
    :color => __dic(:default=> nothing, :__ord=>3, :__cat=>"Scatter appearance", :__doc=>Kwds_docs[:color]),
    :outlinecolor => __dic(:default=> nothing, :__ord=>3, :__cat=>"Scatter appearance", :__doc=>Kwds_docs[:color]),
    :size => __dic(:default=> 50, :__ord=>3, :__cat=>"Scatter appearance", :__doc=>"The symbol size."),
    :symbol => __dic(:default=> "circle", :__ord=>3, :__cat=>"Scatter appearance", :__doc=>"The symbol type, e.g. `:circle`, `:square`, ..."),
    :angle => __dic(:default=> 0, :__ord=>3, :__cat=>"Scatter appearance", :__doc=>"The symbol angle."),
    :colormodel => __dic(:default=> :diverging, :__ord=>3, :__cat=>"Scatter appearance", :__doc=>Kwds_docs[:colormodel]),



    :jitter => __dic(:default=> [0,0], :__ord=>1, :__cat=>"Scatter Options", :__doc=>"The jitter strength in the x and y axes direction, respectively."),

    :opacityresponse => __dic(:default=> nothing, :__ord=>1, :__cat=>"Scatter Options", :__doc=>"The column which its values will be used to determine the opacity of the marks."),
    :symbolresponse => __dic(:default=> nothing, :__ord=>1, :__cat=>"Scatter Options", :__doc=>"The column which its values will be used to determine the symbol of the marks."),
    :angleresponse => __dic(:default=> nothing, :__ord=>1, :__cat=>"Scatter Options", :__doc=>"The column which its values will be used to determine the angle of the marks."),
    :colorresponse => __dic(:default=> nothing, :__ord=>1, :__cat=>"Scatter Options", :__doc=>"The column which its values will be used to determine the fill color of the marks."),

    :labelresponse => __dic(:default=> nothing, :__ord=>4, :__cat=>"Scatter Label", :__doc=>"The column which its values will be used to label points."),
    :labelfont => __dic(:default=> nothing, :__ord=>4, :__cat=>"Scatter Label", :__doc=>Kwds_docs[:font]),
    :labelfontweight => __dic(:default=> nothing, :__ord=>4, :__cat=>"Scatter Label", :__doc=>Kwds_docs[:fontweight]),
    :labelitalic => __dic(:default=> nothing, :__ord=>4, :__cat=>"Scatter Label", :__doc=>Kwds_docs[:italic]),
    :labelsize => __dic(:default=> nothing, :__ord=>4, :__cat=>"Scatter Label", :__doc=>Kwds_docs[:fontsize]),
    :labelcolor => __dic(:default=> :black, :__ord=>4, :__cat=>"Scatter Label", :__doc=>"The label text color, it can also be `:group` or `:colorresponse` for choosing the color based on the points groups."),
    :labelangle => __dic(:default=> 0, :__ord=>4, :__cat=>"Scatter Label", :__doc=>Kwds_docs[:fontangle]),
    :labeldir => __dic(:default=> :ltr, :__ord=>4, :__cat=>"Scatter Label", :__doc=>Kwds_docs[:fontdir]),
    :labellimit => __dic(:default=> nothing, :__ord=>4, :__cat=>"Scatter Label", :__doc=>Kwds_docs[:fontlimit]),
    :labelanchor => __dic(:default=> [:top, :bottom, :left, :right], :__ord=>4, :__cat=>"Scatter Label", :__doc=>"The anchors for choosing the location of labels."),
    :labelalgorithm => __dic(:default=> :naive, :__ord=>4, :__cat=>"Scatter Label", :__doc=>"The algorithm for placing labels."),
    :tooltip => __dic(:default=> false, :__ord=>4, :__cat=>"Scatter Label", :__doc=>Kwds_docs[:tooltip]),



    :x2axis => __dic(:default=> false, :__ord=>5, :__cat=>"Axes options", :__doc=>Kwds_docs[:x2axis]),
    :y2axis => __dic(:default=> false, :__ord=>5, :__cat=>"Axes options", :__doc=>Kwds_docs[:y2axis]),
    :xshift => __dic(:default=> 0, :__ord=>5, :__cat=>"Axes options", :__doc=>"Shift the mark in direction of x. Useful for discrete type axes."),
    :yshift => __dic(:default=> 0, :__ord=>5, :__cat=>"Axes options", :__doc=>"Shift the mark in direction of y. Useful for discrete type axes."),  
    :legend => __dic(:default=> nothing, :__ord=>6, :__cat=>"Legend", :__doc=>Kwds_docs[:legend]),

    :clip => __dic(:default=> nothing, :__ord=>7, :__cat=>"Miscellaneous", :__doc=>Kwds_docs[:clip]),
)

BUBBLE_DEFAULT = SGKwds(
    :x => __dic(:default=> 0, :__ord=>0, :__cat => "Required", :__doc=>"The column to be used as x coordinate."),
    :y => __dic(:default=> 0, :__ord=>0, :__cat=> "Required", :__doc=>"The column to be used as y coordinate."), 
    :size => __dic(:default=> 0, :__ord=>0, :__cat=> "Required", :__doc=>"The column to be used as size."), 
    :group => __dic(:default=> nothing, :__ord=>2, :__cat=>"Grouping", :__doc=>"The name of column for grouping observation. Each group of observations will create seperate bubble plot."),

    :opacity => __dic(:default=> 1, :__ord=>3, :__cat=>"Bubble appearance", :__doc=>Kwds_docs[:opacity]),
    :thickness => __dic(:default=> 1, :__ord=>3, :__cat=>"Bubble appearance", :__doc=>Kwds_docs[:outlinethickness]),
    :color => __dic(:default=> nothing, :__ord=>3, :__cat=>"Bubble appearance", :__doc=>Kwds_docs[:color]),
    :outlinecolor => __dic(:default=> nothing, :__ord=>3, :__cat=>"Bubble appearance", :__doc=>Kwds_docs[:color]),
    :size => __dic(:default=> 50, :__ord=>3, :__cat=>"Bubble appearance", :__doc=>"The symbol size."),
    :colormodel => __dic(:default=> :diverging, :__ord=>3, :__cat=>"Bubble appearance", :__doc=>Kwds_docs[:colormodel]),



    :minsize => __dic(:default=> nothing, :__ord=>1, :__cat=>"Bubble Options", :__doc=>"The minimum size of the bubbles."),
    :maxsize => __dic(:default=> nothing, :__ord=>1, :__cat=>"Bubble Options", :__doc=>"The maximum size of the bubbles."),

    :opacityresponse => __dic(:default=> nothing, :__ord=>1, :__cat=>"Bubble Options", :__doc=>"The column which its values will be used to determine the opacity of the marks."),
    :colorresponse => __dic(:default=> nothing, :__ord=>1, :__cat=>"Bubble Options", :__doc=>"The column which its values will be used to determine the fill color of the marks."),

    :labelresponse => __dic(:default=> nothing, :__ord=>4, :__cat=>"Bubble Label", :__doc=>"The column which its values will be used to label points."),
    :labelfont => __dic(:default=> nothing, :__ord=>4, :__cat=>"Bubble Label", :__doc=>Kwds_docs[:font]),
    :labelfontweight => __dic(:default=> nothing, :__ord=>4, :__cat=>"Bubble Label", :__doc=>Kwds_docs[:fontweight]),
    :labelitalic => __dic(:default=> nothing, :__ord=>4, :__cat=>"Bubble Label", :__doc=>Kwds_docs[:italic]),
    :labelsize => __dic(:default=> nothing, :__ord=>4, :__cat=>"Bubble Label", :__doc=>Kwds_docs[:fontsize]),
    :labelcolor => __dic(:default=> :black, :__ord=>4, :__cat=>"Bubble Label", :__doc=>"The label text color, it can also be `:group` or `:colorresponse` for choosing the color based on the points groups."),
    :labelangle => __dic(:default=> 0, :__ord=>4, :__cat=>"Bubble Label", :__doc=>Kwds_docs[:fontangle]),
    :labeldir => __dic(:default=> :ltr, :__ord=>4, :__cat=>"Bubble Label", :__doc=>Kwds_docs[:fontdir]),
    :labellimit => __dic(:default=> nothing, :__ord=>4, :__cat=>"Bubble Label", :__doc=>Kwds_docs[:fontlimit]),
    :labelanchor => __dic(:default=> [:top, :bottom, :left, :right], :__ord=>4, :__cat=>"Bubble Label", :__doc=>"The anchors for choosing the location of labels."),
    :labelalgorithm => __dic(:default=> :naive, :__ord=>4, :__cat=>"Bubble Label", :__doc=>"The algorithm for placing labels."),
    :tooltip => __dic(:default=> false, :__ord=>4, :__cat=>"Bubble Label", :__doc=>Kwds_docs[:tooltip]),



    :x2axis => __dic(:default=> false, :__ord=>5, :__cat=>"Axes options", :__doc=>Kwds_docs[:x2axis]),
    :y2axis => __dic(:default=> false, :__ord=>5, :__cat=>"Axes options", :__doc=>Kwds_docs[:y2axis]),
    :xshift => __dic(:default=> 0, :__ord=>5, :__cat=>"Axes options", :__doc=>"Shift the mark in direction of x. Useful for discrete type axes."),
    :yshift => __dic(:default=> 0, :__ord=>5, :__cat=>"Axes options", :__doc=>"Shift the mark in direction of y. Useful for discrete type axes."),  
    :legend => __dic(:default=> nothing, :__ord=>6, :__cat=>"Legend", :__doc=>Kwds_docs[:legend]),

    :clip => __dic(:default=> nothing, :__ord=>7, :__cat=>"Miscellaneous", :__doc=>Kwds_docs[:clip]),
)
                                  
BOXPLOT_DEFAULT = SGKwds(
    :x => __dic(:default=> 0, :__ord=>0, :__cat => "Required", :__doc=>"User should pass multiple columns for plotting the comparative box plot, i.e. side by side box plot for passed columns. User must pass either this or the `y` argument."),
    :y => __dic(:default=> 0, :__ord=>0, :__cat=> "Required", :__doc=>"User should pass multiple columns for plotting the comparative box plot, i.e. side by side box plot for passed columns. User must pass either this or the `x` argument."),

    :category => __dic(:default=> nothing, :__ord=>2, :__cat=>"Grouping", :__doc=>"A category column which indicates the box plot must be drawn within each category."),

    :categoryorder => __dic(:default=> :ascending, :__ord=>1, :__cat=>"BoxPlot options", :__doc=>"How the category should be ordered, i.e. `:ascending`, `:descending`, `:data`."),
    :outliers => __dic(:default=> false, :__ord=>1, :__cat=>"BoxPlot options", :__doc=>"If `true` the oultliers will be shown. The outliers are computed based on how many `outliersfactor` they are far from quartiles." ),
    :outliersfactor => __dic(:default=> 1.5, :__ord=>1, :__cat=>"BoxPlot options", :__doc=>"The factor to be used for computing outliers." ),

    :opacity => __dic(:default=> 1, :__ord=>3, :__cat=>"BoxPlot appearance", :__doc=>Kwds_docs[:opacity]),
    :outlinethickness => __dic(:default=> 1, :__ord=>3, :__cat=>"BoxPlot appearance", :__doc=>Kwds_docs[:outlinethickness]),
    :boxwidth => __dic(:default=> 1, :__ord=>3, :__cat=>"BoxPlot appearance", :__doc=>"The box width, it must be a number between 0 and 1."),
    :boxcorner => __dic(:default=> 0, :__ord=>3, :__cat=>"BoxPlot appearance", :__doc=>"Corner radius for boxes. (`cornerRadiusTopLeft`, `cornerRadiusTopRight`, `cornerRadiusBottomLeft`, `cornerRadiusBottomRight`)."),
    :space => __dic(:default=> 0.1, :__ord=>3, :__cat=>"BoxPlot appearance", :__doc=>"The space between boxes. It must be a number between 0 and 1."),
    :groupspace => __dic(:default=> 0.05, :__ord=>3, :__cat=>"BoxPlot appearance", :__doc=>"The space between boxes inside each category. It must be a number between 0 and 1."),
    :outlinecolor => __dic(:default=> :white, :__ord=>3, :__cat=>"BoxPlot appearance", :__doc=>Kwds_docs[:color]),
    :medianwidth => __dic(:default=> 1, :__ord=>3, :__cat=>"BoxPlot appearance", :__doc=>"The total width to be used for the median indicator. It must be a number between 0 and 1."),
    :mediancolor => __dic(:default=> :white, :__ord=>3, :__cat=>"BoxPlot appearance", :__doc=>"Specifiy the color for the median indicator."),
    :medianthickness => __dic(:default=> 1, :__ord=>3, :__cat=>"BoxPlot appearance", :__doc=>"Specifiy the thickness for the median indicator."),
    :tooltip => __dic(:default=> false, :__ord=>4, :__cat=>"BoxPlot tooltip", :__doc=>Kwds_docs[:tooltip]), 
    :whiskercolor => __dic(:default=> :black, :__ord=>3, :__cat=>"BoxPlot appearance", :__doc=>"Specifiy the color for the whisker lines."),
    :whiskerdash => __dic(:default=> [3,3], :__ord=>3, :__cat=>"BoxPlot appearance", :__doc=>"Specifiy the dash style for the whisker lines."),
    :whiskerthickness => __dic(:default=> 1, :__ord=>3, :__cat=>"BoxPlot appearance", :__doc=>"Specifiy the thickness for the whisker lines."),
    :fencewidth => __dic(:default=> 0.5, :__ord=>3, :__cat=>"BoxPlot appearance", :__doc=>"Specifiy the total width for the fence lines. It must be a number between 0 and 1."),
    :fencecolor => __dic(:default=> :black, :__ord=>3, :__cat=>"BoxPlot appearance", :__doc=>"Specifiy the color for the fence lines."),
    :meansymbol => __dic(:default=> :diamond, :__ord=>3, :__cat=>"BoxPlot appearance", :__doc=>"Specifiy the symbol to be used for the mean indicator."),
    :meansymbolsize => __dic(:default=> 40, :__ord=>3, :__cat=>"BoxPlot appearance", :__doc=>"Specifiy the symbol size to be used for the mean indicator."),

    :outliercolor => __dic(:default=> nothing, :__ord=>3.5, :__cat=>"Outliers appearance", :__doc=>"Specifiy the color for the outliers symobls."),
    :outlieroutlinecolor => __dic(:default=> nothing, :__ord=>3.5, :__cat=>"Outliers appearance", :__doc=>"Specifiy the outline color for the outliers symobls."),
    :outlierthickness => __dic(:default=> 1, :__ord=>3.5, :__cat=>"Outliers appearance", :__doc=>"Specifiy the outline thickness for the outliers symobls."),
    :outliersymbolsize => __dic(:default=> 30, :__ord=>3.5, :__cat=>"Outliers appearance", :__doc=>"Specifiy the symbol size for the outliers symobls."),
    :outlierjitter => __dic(:default=> 0, :__ord=>3.5, :__cat=>"Outliers appearance", :__doc=>"Specifiy the jitter strength for the outliers symobls."),
    :outliersymbol => __dic(:default=> :circle, :__ord=>3.5, :__cat=>"Outliers appearance", :__doc=>"Specifiy the symbol shape for the outliers symobls."),
    :outlieropacity => __dic(:default=> 1, :__ord=>3.5, :__cat=>"Outliers appearance", :__doc=>"Specifiy the mark opacity for the outliers symobls."),

    :x2axis => __dic(:default=> false, :__ord=>5, :__cat=>"Axes options", :__doc=>Kwds_docs[:x2axis]),
    :y2axis => __dic(:default=> false, :__ord=>5, :__cat=>"Axes options", :__doc=>Kwds_docs[:y2axis]),

    :legend => __dic(:default=> nothing, :__ord=>6, :__cat=>"Legend", :__doc=>Kwds_docs[:legend]),

    :clip => __dic(:default=> nothing, :__ord=>7, :__cat=>"Miscellaneous", :__doc=>Kwds_docs[:clip]),

    
    :missingmode => __dic(:default=> 0, :__ord=>1, :__cat=>"BoxPlot options", :__doc=>"Indicate how to handle missing values in category or group.  `0` = nothing, `1` = no missing in category.")

)                 

violin_default_scale(x; args...) = x

VIOLIN_DEFAULT = SGKwds(
    :x => __dic(:default=> 0, :__ord=>0, :__cat => "Required", :__doc=>"User should pass multiple columns for plotting the comparative violin plot, i.e. side by side violin plot for passed columns. User must pass either this or the `y` argument."),
    :y => __dic(:default=> 0, :__ord=>0, :__cat=> "Required", :__doc=>"User should pass multiple columns for plotting the comparative violin plot, i.e. side by side violin plot for passed columns. User must pass either this or the `x` argument."),

    :weights => __dic(:default=> :gaussian, :__ord=>1, :__cat=>"Violin options", :__doc=>"The kernel weight function."),
    :bw => __dic(:default=> nothing, :__ord=>1, :__cat=>"Violin options", :__doc=>"The kernel bandwidth."),
    :npoints => __dic(:default=> 100, :__ord=>1, :__cat=>"Violin options", :__doc=>"The number of points for drawing the density line."),
    :interpolate => __dic(:default=> :linear, :__ord=>1, :__cat=>"Violin options", :__doc=>"The line interpolation algorithm for drawing the density line."),
    :scale => __dic(:default=> violin_default_scale, :__ord=>1, :__cat=>"Violin options", :__doc=>"The scale to be used for density estimation, see `Density`."),


    :category => __dic(:default=> nothing, :__ord=>2, :__cat=>"Grouping", :__doc=>"A category column which indicates the violin plot must be drawn within each category."),

    :side => __dic(:default=> :both, :__ord=>3, :__cat=>"Violin appearance", :__doc=>"Specifiy which half of the violin plot should be plotted, i.e. `:right(:bottom)`, `:left(:top)`."),
    :thickness => __dic(:default=> 1, :__ord=>3, :__cat=>"Violin appearance", :__doc=>"Specifiy The thickness of the outline line."),
    :fillopacity => __dic(:default=> 0.5, :__ord=>3, :__cat=>"Violin appearance", :__doc=>"Specifiy The fill opacity of the plot."),
    :opacity => __dic(:default=> 1, :__ord=>3, :__cat=>"Violin appearance", :__doc=>"Specifiy The opacity of the density line."),
    :filled => __dic(:default=> true, :__ord=>3, :__cat=>"Violin appearance", :__doc=>"Specifiy the plot should be filled with color."),
    :color => __dic(:default=> nothing, :__ord=>3, :__cat=>"Violin appearance", :__doc=>Kwds_docs[:color_grad]),



    :x2axis => __dic(:default=> false, :__ord=>5, :__cat=>"Axes options", :__doc=>Kwds_docs[:x2axis]),
    :y2axis => __dic(:default=> false, :__ord=>5, :__cat=>"Axes options", :__doc=>Kwds_docs[:y2axis]),

    :legend => __dic(:default=> nothing, :__ord=>6, :__cat=>"Legend", :__doc=>Kwds_docs[:legend]),

    :clip => __dic(:default=> nothing, :__ord=>7, :__cat=>"Miscellaneous", :__doc=>Kwds_docs[:clip]),

    
    :missingmode => __dic(:default=> 0, :__ord=>1, :__cat=>"Violin options", :__doc=>"Indicate how to handle missing values in category or group.  `0` = nothing, `1` = no missing in category."),

    :categoryorder => __dic(:default=> :ascending, :__ord=>1, :__cat=>"Violin options", :__doc=>"How the category should be ordered, i.e. `:ascending`, `:descending`, `:data`."),
    :space => __dic(:default=> 0.1, :__ord=>3, :__cat=>"Violin appearance", :__doc=>"The space between violins. It must be a number between 0 and 1."),
    :groupspace => __dic(:default=> 0.05, :__ord=>3, :__cat=>"Violin appearance", :__doc=>"The space between violins inside each category. It must be a number between 0 and 1.")
    # :scale => (x; args...) -> x, # see Density for more information
  

)

REG_DEFAULT = SGKwds(
    :x => __dic(:default=> 0, :__ord=>0, :__cat => "Required", :__doc=>"The column to be used as x, i.e. the independent variable."),
    :y => __dic(:default=> 0, :__ord=>0, :__cat=> "Required", :__doc=>"The column to be used as y, i.e. the response variable."),    
    :group => __dic(:default=> nothing, :__ord=>2, :__cat=>"Grouping", :__doc=>"The name of column for grouping observation. Each group of observations will create seperate Regression Line."),

    :opacity => __dic(:default=> 1, :__ord=>3, :__cat=>"Reg appearance", :__doc=>Kwds_docs[:opacity]),
    :thickness => __dic(:default=> 1, :__ord=>3, :__cat=>"Reg appearance", :__doc=>"The Line thickness."),
    :dash => __dic(:default=> [0], :__ord=>3, :__cat=>"Reg appearance", :__doc=>"The Line dash style."),
    :color => __dic(:default=> "#4682b4", :__ord=>3, :__cat=>"Reg appearance", :__doc=>Kwds_docs[:color_grad]),

    :interpolate => __dic(:default=>:linear, :__ord=>1, :__cat=>"Reg Options", :__doc=>Kwds_docs[:interpolate]),
    :degree => __dic(:default=>1, :__ord=>1, :__cat=>"Reg Options", :__doc=>"The maximum polynomial degree for the fitted line."),
    :intercept => __dic(:default=>true, :__ord=>1, :__cat=>"Reg Options", :__doc=>"Whether the fitted line should have the intercept term."),
    :npoints => __dic(:default=>100, :__ord=>1, :__cat=>"Reg Options", :__doc=>"The number of points in grid for drawing the regression line."),

    :clm => __dic(:default=>false, :__ord=>4, :__cat=>"Confidence Interval ", :__doc=>"Draw the mean confidence interval."),
    :clmcolor => __dic(:default=>nothing, :__ord=>4, :__cat=>"Confidence Interval ", :__doc=>"The filling color for the mean confidence interval."),
    :clmopacity => __dic(:default=>0.3, :__ord=>4, :__cat=>"Confidence Interval ", :__doc=>"The opacity for the mean confidence interval."),

    :cli => __dic(:default=>false, :__ord=>4, :__cat=>"Confidence Interval ", :__doc=>"Draw the prediction confidence interval."),
    :clicolor => __dic(:default=>nothing, :__ord=>4, :__cat=>"Confidence Interval ", :__doc=>"The filling color for the prediction confidence interval."),
    :cliopacity => __dic(:default=>0.3, :__ord=>4, :__cat=>"Confidence Interval ", :__doc=>"The opacity for the prediction confidence interval."),
    :alpha => __dic(:default=>0.05, :__ord=>4, :__cat=>"Confidence Interval ", :__doc=>"Control the confidence intervals level."),


    :x2axis => __dic(:default=> false, :__ord=>5, :__cat=>"Axes options", :__doc=>Kwds_docs[:x2axis]),
    :y2axis => __dic(:default=> false, :__ord=>5, :__cat=>"Axes options", :__doc=>Kwds_docs[:y2axis]),
    :legend => __dic(:default=> nothing, :__ord=>6, :__cat=>"Legend", :__doc=>Kwds_docs[:legend]),

    :clip => __dic(:default=> nothing, :__ord=>7, :__cat=>"Miscellaneous", :__doc=>Kwds_docs[:clip]),
)
