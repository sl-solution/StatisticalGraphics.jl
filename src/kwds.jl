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
    ds = Dataset(allk=Symbol[], dfs=Any[], ords=Int[], cat=String[], docs=String[])
    
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
        :color=>"The default color for the mark. User can pass color's name as symbol (e.g. `:red`), as string (e.g. `\"red\"`), as HTML color value (e.g. `\"#4682b4\"`), or pass a gradient color using the `gradient()` function.",
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



)

bar_normalizer(x) = x ./ sum(x)

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
    :color => __dic(:default=> "#4682b4", :__ord=>3, :__cat=>"Bar appearance", :__doc=>Kwds_docs[:color]),
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
    :label=>__dic(:default=> :none, :__ord=>4, :__cat=>"Bar labels", :__doc=>"What information should be used for bar labels. It can be :none, :height, or :category."), # :height or :category
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