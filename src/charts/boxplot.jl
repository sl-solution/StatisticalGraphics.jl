BOXPLOT_DEFAULT = Dict{Symbol,Any}(:x => 0, :y => 0, :category => nothing, # x or y can be a set of analysis variables
   
    :x2axis => false,
    :y2axis => false,
    :opacity => 1,
    :outlinethickness => 1,
    :boxwidth => 1, # can be between[0,1]
    :boxcorner=>0,
    :filled => true,
    :fill => "null",
    :color => "#4682b4",
    :space => 0.1, # the space between box 
    :groupspace => 0.05, # the space between boxes inside each group 
    :outlinecolor => :white,
    :categoryorder => :ascending, # :data, :ascending, :descending
    :outliers => false, # if the outlier should be shown?
    :outliersfactor => 1.5, # default factor for calculating outliers
    :medianwidth => 1, # width of median line
    :mediancolor=>:white,
    :medianthickness=>1.0,
    :whiskercolor => :black, # color for the line which connect q1 and q3 to min and max values
    :whiskerdash => [3,3],
    :whiskerthickness => 1,
    :fencewidth=>0.5,
    :fencecolor=>:black,
    :meansymbol=>:diamond,
    :meansymbolsize=>40,
    :outliercolor => nothing,
    :outlieroutlinecolor=>nothing,
    :outlierthickness=>1,
    :outliersymbolsize=>30,
    :outlierjitter=>0,
    :outliersymbol=>:circle,
    :outlieropacity=>1,
    :legend => nothing,

    :tooltip=>false,
    :clip=>nothing

)
mutable struct BoxPlot <: SGMarks
    opts
    function BoxPlot(; opts...)
        optsd = val_opts(opts)
        cp_BOXPLOT_DEFAULT = update_default_opts!(deepcopy(BOXPLOT_DEFAULT), optsd)
        haskey(cp_BOXPLOT_DEFAULT, :group) && throw(ArgumentError("BoxPlot does not support the group keyword argument, pass category for creating box plot across different level of a column"))
        if (cp_BOXPLOT_DEFAULT[:x] == 0 && cp_BOXPLOT_DEFAULT[:y] == 0) || (cp_BOXPLOT_DEFAULT[:x] != 0 && cp_BOXPLOT_DEFAULT[:y] != 0)
            throw(ArgumentError("Box plot needs one of x or y keyword arguments"))
        end
        if !(cp_BOXPLOT_DEFAULT[:boxcorner] isa AbstractVector)
            cp_BOXPLOT_DEFAULT[:boxcorner] = fill(cp_BOXPLOT_DEFAULT[:boxcorner], 4)
        else
            length(cp_BOXPLOT_DEFAULT[:boxcorner]) != 4 && throw(ArgumentError("the boxcorner option must be a single value or a vector of length four of values"))
        end
        new(cp_BOXPLOT_DEFAULT)
    end
end

function _filter_barrier!(y, minval, maxval) 
    filter!(x -> isless(maxval, x) || isless(x, minval), y)
    y
end

function _box_plot_fun(x, outliers; olf = 1.5, fun = identity)
    y = collect(fun(_val_) for _val_ in skipmissing(x))
    isempty(y) && return (missing, missing, missing, missing, missing, missing, missing, missing, Any[])#throw(ArgumentError("the input vector is empty"))
    if outliers
        q1, med, q3 = quantile(y, [0.25, 0.5, 0.75])
        mu = IMD.mean(y)
        iqr = q3 - q1
        actual_min = IMD.minimum(y)
        actual_max = IMD.maximum(y)
        minval = q1 - olf * iqr
        maxval = q3 + olf * iqr
        minval = isless(minval, actual_min) ? actual_min : minval
        maxval = isless(actual_max, maxval) ? actual_max : maxval
        return (q1, q3, med, mu, minval, maxval, actual_min, actual_max, _filter_barrier!(y, minval, maxval))
    else
        
        return (quantile(y, [0.25, 0.75, 0.5])..., IMD.mean(y), IMD.minimum(y), IMD.maximum(y), IMD.minimum(y), IMD.maximum(y), Any[])
    end
end

# BoxPlot produces a simple Box plot chart
# It requires one of x or y keyword arguments 
# It needs the input data be processed before being sent to  vega
function _push_plots!(vspec, plt::BoxPlot, all_args; idx=1)
    # check if the required arguments are passed / create a new ds and push it to out_ds
    cols, new_ds, outlier_ds = _check_and_normalize!(plt, all_args)
    _add_legends!(plt, all_args, idx)
    data_csv = tempname()
    filewriter(data_csv, new_ds, mapformats=all_args.mapformats, quotechar='"')
    push!(vspec[:data], Dict{Symbol,Any}(:name => "box_data_$idx", :values => read(data_csv, String), :format => Dict(:type => "csv", :delimiter => ",", :parse => _write_parse_js(new_ds, all_args))))

    if plt.opts[:outliers] # show outliers
        data_csv = tempname()
        # flatten outliers and put them in vspec
        _tm_ds = flatten(outlier_ds, "__box__vars__outliers__")
        filewriter(data_csv, _tm_ds, mapformats=all_args.mapformats, quotechar='"')
        push!(vspec[:data], Dict{Symbol,Any}(:name => "box_data_outlier_$idx", :values => read(data_csv, String), :format => Dict(:type => "csv", :delimiter => ",", :parse => _write_parse_js(_tm_ds, all_args))))
    end

    # now we push every component of the box plot
    _push_boxplot_box!(vspec, plt, all_args, cols, new_ds; idx=idx)
    if plt.opts[:outliers]
        _push_boxplot_outliers!(vspec, plt, all_args, cols, outlier_ds; idx)
    end
end
function _push_boxplot_box!(vspec, plt, all_args, cols, new_ds; idx=1)
    opts = plt.opts
    complement_bandwidth = (1 - opts[:boxwidth]) / 2

    s_spec = Dict{Symbol,Any}()
    s_spec[:type] = "group"
    s_spec[:clip] = something(opts[:clip], all_args.opts[:clip])
    s_spec_marks = Dict{Symbol,Any}()
    s_spec_marks[:type] = "rect"
    s_spec_marks[:from] = Dict{Symbol,Any}(:data => "box_data_$idx")
    s_spec_marks[:encode] = Dict{Symbol,Any}()
    s_spec_marks[:encode][:enter] = Dict{Symbol,Any}()
    s_spec_marks[:encode][:enter][:cornerRadiusTopLeft] = Dict{Symbol,Any}(:value => opts[:boxcorner][1])
    s_spec_marks[:encode][:enter][:cornerRadiusTopRight] = Dict{Symbol,Any}(:value => opts[:boxcorner][2])
    s_spec_marks[:encode][:enter][:cornerRadiusBottomLeft] = Dict{Symbol,Any}(:value => opts[:boxcorner][3])
    s_spec_marks[:encode][:enter][:cornerRadiusBottomRight] = Dict{Symbol,Any}(:value => opts[:boxcorner][4])
    s_spec_marks[:encode][:enter][:opacity] = Dict{Symbol,Any}(:value => opts[:opacity])
    s_spec_marks[:encode][:enter][:stroke] = Dict{Symbol,Any}(:value => opts[:outlinecolor])
    s_spec_marks[:encode][:enter][:strokeWidth] = Dict{Symbol,Any}(:signal => "isValid(datum.__box__vars__q1) ? $(opts[:outlinethickness]) : 0")
    s_spec_marks[:encode][:enter][:fill] = Dict{Symbol,Any}()

    # extract the information about the box chart
    groupcol = opts[:category] === nothing ? "__box__fake__group__col__" : opts[:category]
    if opts[:x] == 0
        _var_ = :x
        _var_2_ = :y
        _orient_ = :vertical
        if opts[:x2axis]
            _scale_ = "x2"
            _scale_index_ = 2
        else
            _scale_ = "x1"
            _scale_index_ = 1
        end
        if opts[:y2axis]
            _scale_2_ = "y2"
            _scale_2_index_ = 4
        else
            _scale_2_ = "y1"
            _scale_2_index_ = 3
        end
    else
        _var_ = :y
        _var_2_ = :x
        _orient_ = :horizontal
        if opts[:y2axis]
            _scale_ = "y2"
            _scale_index_ = 4
        else
            _scale_ = "y1"
            _scale_index_ = 3
        end
        if opts[:x2axis]
            _scale_2_ = "x2"
            _scale_2_index_ = 2
        else
            _scale_2_ = "x1"
            _scale_2_index_ = 1
        end
    end

    s_spec_marks[:encode][:enter][_var_] = Dict{Symbol,Any}()
    s_spec_marks[:encode][:enter][_var_][:scale] = _scale_
    s_spec_marks[:encode][:enter][_var_][:band] = complement_bandwidth
    if _orient_ == :vertical
        s_spec_marks[:encode][:enter][:width] = Dict{Symbol,Any}(:scale => _scale_, :band => opts[:boxwidth])
    else
        s_spec_marks[:encode][:enter][:height] = Dict{Symbol,Any}(:scale => _scale_, :band => opts[:boxwidth])
    end

    # we make sure addto_scale! knows about type before obtaining domain
    vspec[:scales][_scale_index_][:type] = :band
    all_args.scale_type[_scale_index_] = :band
    addto_scale!(all_args, _scale_index_, new_ds, groupcol)
    addto_axis!(vspec[:axes][_scale_index_], all_args.axes[_scale_index_], opts[:category] === nothing ? "" : opts[:category])
    vspec[:scales][_scale_index_][:type] = :band
    vspec[:scales][_scale_index_][:paddingInner] = opts[:space]

    s_spec_marks[:encode][:enter][_var_2_] = Dict{Symbol,Any}()
    s_spec_marks[:encode][:enter][Symbol(_var_2_, 2)] = Dict{Symbol,Any}()

    s_spec_marks[:encode][:enter][_var_2_][:scale] = _scale_2_
    s_spec_marks[:encode][:enter][Symbol(_var_2_, 2)][:scale] = _scale_2_
    addto_scale!(all_args, _scale_2_index_, new_ds, "__box__vars__actual__min")
    addto_scale!(all_args, _scale_2_index_, new_ds, "__box__vars__actual__max")
    addto_axis!(vspec[:axes][_scale_2_index_], all_args.axes[_scale_2_index_], "")
    s_spec_marks[:encode][:enter][_var_][:field] = groupcol
    s_spec_marks[:encode][:enter][_var_2_][:field] = "__box__vars__q1"
    s_spec_marks[:encode][:enter][Symbol(_var_2_, 2)][:field] = "__box__vars__q3"
    if opts[:tooltip]
        s_spec_marks[:encode][:enter][:tooltip] = Dict{Symbol,Any}(:signal => "{min : datum['__box__vars__min'], q1 :  datum['__box__vars__q1']
       , median : datum['__box__vars__med'], mean : datum['__box__vars__mean'], q3 : datum['__box__vars__q3'], max : datum['__box__vars__max']}")
    end


    s_spec[:from] = Dict{Symbol,Any}()
    s_spec[:from][:facet] = Dict{Symbol,Any}()
    s_spec[:from][:facet][:name] = "group_facet_source"
    s_spec[:from][:facet][:data] = "box_data_$idx"
    s_spec[:from][:facet][:groupby] = groupcol
    s_spec_marks[:from][:data] = "group_facet_source"
    s_spec_marks[:encode][:enter][:fill][:scale] = "group_scale"
    s_spec_marks[:encode][:enter][:fill][:field] = "__box__groups__variable__"
    # group is the 5th element of scales
    push!(all_args.nominal, "__box__groups__variable__")
    addto_group_scale!(vspec[:scales][5], "box_data_$idx", "__box__groups__variable__", all_args)

    s_spec[:encode] = Dict{Symbol,Any}()
    s_spec[:encode][:enter] = Dict{Symbol,Any}()
    if _orient_ == :vertical
        s_spec[:encode][:enter][:x] = Dict{Symbol,Any}(:scale => _scale_, :field => groupcol)
        s_spec[:signals] = Dict{Symbol,Any}[Dict{Symbol,Any}(:name => "width", :update => "bandwidth('$(_scale_)')")]
        # for scale we collect group domain info from the main data no the facet one - i.e. we want the all group have the same number of categories
        s_spec[:scales] = Dict{Symbol,Any}[Dict{Symbol,Any}(:name => "pos_with_in_group", :type => :band, :range => "width", :domain => Dict{Symbol,Any}(:data => "box_data_$idx", :field => "__box__groups__variable__"), :paddingInner => opts[:groupspace])]
    else
        s_spec[:encode][:enter][:y] = Dict{Symbol,Any}(:scale => _scale_, :field => groupcol)
        s_spec[:signals] = Dict{Symbol,Any}[Dict{Symbol,Any}(:name => "height", :update => "bandwidth('$(_scale_)')")]
        s_spec[:scales] = Dict{Symbol,Any}[Dict{Symbol,Any}(:name => "pos_with_in_group", :type => :band, :range => "height", :domain => Dict{Symbol,Any}(:data => "box_data_$idx", :field => "__box__groups__variable__"), :paddingInner => opts[:groupspace])]
    end
    if all_args.axes[_scale_index_].opts[:reverse]
        s_spec[:scales][1][:reverse] = true
    end
    s_spec_marks[:encode][:enter][_var_][:scale] = "pos_with_in_group"
    s_spec_marks[:encode][:enter][_var_][:field] = "__box__groups__variable__"
    if _orient_ == :vertical
        s_spec_marks[:encode][:enter][:width][:scale] = "pos_with_in_group"
    else
        s_spec_marks[:encode][:enter][:height][:scale] = "pos_with_in_group"
    end
    #####################fix
    s_spec[:from][:facet][:groupby] = groupcol
    s_spec[:marks] = [s_spec_marks]
    push!(vspec[:marks], s_spec)

    # copy the s_spec_marks and modify it to draw median Line
    s_box_plot_med = deepcopy(s_spec_marks)
    delete!(s_box_plot_med[:encode][:enter], Symbol(_var_2_, 2))
    s_box_plot_med[:type] = "rule"
    s_box_plot_med[:encode][:enter][:stroke][:value] = opts[:mediancolor]
    s_box_plot_med[:encode][:enter][:strokeWidth][:signal] = "isValid(datum.__box__vars__q1) ? $(opts[:medianthickness]) : 0"
    s_box_plot_med[:encode][:enter][_var_2_][:field] = "__box__vars__med"
    s_box_plot_med[:encode][:enter][Symbol(_var_, 2)] = deepcopy(s_box_plot_med[:encode][:enter][_var_])
    median_pos = "bandwidth('$(s_box_plot_med[:encode][:enter][_var_][:scale])')*$(opts[:boxwidth]/2)"
    s_box_plot_med[:encode][:enter][_var_][:offset] = Dict{Symbol,Any}(:signal => "$(median_pos) - $(median_pos)*$(opts[:medianwidth])")
    s_box_plot_med[:encode][:enter][Symbol(_var_, 2)][:offset] = Dict{Symbol,Any}(:signal => "$(median_pos) + $(median_pos)*$(opts[:medianwidth])")



    push!(s_spec[:marks], s_box_plot_med)

    # mean symbol
    s_box_plot_mean = deepcopy(s_box_plot_med)
    s_box_plot_mean[:type] = "symbol"
    s_box_plot_mean[:encode][:enter][_var_2_][:field] = "__box__vars__mean"
    s_box_plot_mean[:encode][:enter][_var_][:offset] = Dict{Symbol,Any}(:signal => "bandwidth('$(s_box_plot_mean[:encode][:enter][_var_][:scale])')*$(opts[:boxwidth]/2)")
    s_box_plot_mean[:encode][:enter][:shape] = Dict{Symbol,Any}(:value => opts[:meansymbol])
    s_box_plot_mean[:encode][:enter][:size] = Dict{Symbol,Any}(:signal => "isValid(datum.__box__vars__q1) ? $(opts[:meansymbolsize]) : 0")

    push!(s_spec[:marks], s_box_plot_mean)

    # copy the s_spec_marks and modify it to draw minimum Line
    s_box_plot_whisker = deepcopy(s_spec_marks)
    s_box_plot_whisker[:type] = "rule"
    s_box_plot_whisker[:encode][:enter][_var_2_][:field] = "__box__vars__q1"
    s_box_plot_whisker[:encode][:enter][Symbol(_var_2_, 2)][:field] = "__box__vars__min"
    s_box_plot_whisker[:encode][:enter][_var_][:offset] = Dict{Symbol,Any}(:signal => "bandwidth('$(s_box_plot_whisker[:encode][:enter][_var_][:scale])')*$(opts[:boxwidth]/2)")
    s_box_plot_whisker[:encode][:enter][:stroke][:value] = opts[:whiskercolor]
    s_box_plot_whisker[:encode][:enter][:strokeDash] = Dict{Symbol,Any}(:value => opts[:whiskerdash])
    s_box_plot_whisker[:encode][:enter][:strokeWidth] = Dict{Symbol,Any}(:signal => "isValid(datum.__box__vars__q1) ? $(opts[:whiskerthickness]) : 0")

    push!(s_spec[:marks], s_box_plot_whisker)

    # copy the s_spec_marks and modify it to draw maximum Line
    s_box_plot_whisker = deepcopy(s_box_plot_whisker)
    s_box_plot_whisker[:encode][:enter][_var_2_][:field] = "__box__vars__q3"
    s_box_plot_whisker[:encode][:enter][Symbol(_var_2_, 2)][:field] = "__box__vars__max"

    push!(s_spec[:marks], s_box_plot_whisker)

    # add fences
    s_box_plot_fence = deepcopy(s_box_plot_whisker)
    s_box_plot_fence[:name] = "lower_fence"
    s_box_plot_fence[:encode][:enter][_var_2_][:field] = "__box__vars__min"
    delete!(s_box_plot_fence[:encode][:enter], Symbol(_var_2_, 2))
    delete!(s_box_plot_fence[:encode][:enter], :strokeDash)
    s_box_plot_fence[:encode][:enter][Symbol(_var_, 2)] = deepcopy(s_box_plot_fence[:encode][:enter][_var_])

    fence_pos = "bandwidth('$(s_box_plot_fence[:encode][:enter][_var_][:scale])')*$(opts[:boxwidth]/2)"
    s_box_plot_fence[:encode][:enter][_var_][:offset] = Dict{Symbol,Any}(:signal => "$(fence_pos) - $(fence_pos)*$(opts[:fencewidth])")
    s_box_plot_fence[:encode][:enter][Symbol(_var_, 2)][:offset] = Dict{Symbol,Any}(:signal => "$(fence_pos) + $(fence_pos)*$(opts[:fencewidth])")

    s_box_plot_fence[:encode][:enter][:stroke][:value] = opts[:fencecolor]

    push!(s_spec[:marks], s_box_plot_fence)

    s_box_plot_fence = deepcopy(s_box_plot_fence)
    s_box_plot_fence[:name] = "upper_fence"
    s_box_plot_fence[:encode][:enter][_var_2_][:field] = "__box__vars__max"
    push!(s_spec[:marks], s_box_plot_fence)

end


function _push_boxplot_outliers!(vspec, plt, all_args, cols, outlier_ds; idx=1)
    opts = plt.opts
    complement_bandwidth = (1 - opts[:boxwidth]) / 2

    s_spec = Dict{Symbol,Any}()
    s_spec[:type] = "group"
    s_spec[:clip] = something(opts[:clip], all_args.opts[:clip])
    s_spec_marks = Dict{Symbol,Any}()
    s_spec_marks[:type] = "symbol"
    s_spec_marks[:from] = Dict(:data => "box_data_outlier_$idx")
    s_spec_marks[:encode] = Dict{Symbol,Any}()
    s_spec_marks[:encode][:enter] = Dict{Symbol,Any}()
    s_spec_marks[:encode][:enter][:shape] = Dict{Symbol, Any}(:value => opts[:outliersymbol])
    s_spec_marks[:encode][:enter][:opacity] = Dict{Symbol,Any}(:value => opts[:outlieropacity])
    s_spec_marks[:encode][:enter][:stroke] = Dict{Symbol,Any}(:value => something(opts[:outlieroutlinecolor], :white))
    s_spec_marks[:encode][:enter][:strokeWidth] = Dict{Symbol,Any}(:value => opts[:outlierthickness])
    s_spec_marks[:encode][:enter][:size] = Dict{Symbol,Any}(:value => opts[:outliersymbolsize])
    s_spec_marks[:encode][:enter][:fill] = Dict{Symbol,Any}()

    # extract the information about the box chart
    groupcol = opts[:category] === nothing ? "__box__fake__group__col__" : opts[:category]
    if opts[:x] == 0
        _var_ = :x
        _var_2_ = :y
        _orient_ = :vertical
        if opts[:x2axis]
            _scale_ = "x2"
            _scale_index_ = 2
        else
            _scale_ = "x1"
            _scale_index_ = 1
        end
        if opts[:y2axis]
            _scale_2_ = "y2"
            _scale_2_index_ = 4
        else
            _scale_2_ = "y1"
            _scale_2_index_ = 3
        end
    else
        _var_ = :y
        _var_2_ = :x
        _orient_ = :horizontal
        if opts[:y2axis]
            _scale_ = "y2"
            _scale_index_ = 4
        else
            _scale_ = "y1"
            _scale_index_ = 3
        end
        if opts[:x2axis]
            _scale_2_ = "x2"
            _scale_2_index_ = 2
        else
            _scale_2_ = "x1"
            _scale_2_index_ = 1
        end
    end

    s_spec_marks[:encode][:enter][_var_] = Dict{Symbol,Any}()
    s_spec_marks[:encode][:enter][_var_][:scale] = _scale_


    # we make sure addto_scale! knows about type before obtaining domain
    vspec[:scales][_scale_index_][:type] = :band
    all_args.scale_type[_scale_index_] = :band
    vspec[:scales][_scale_index_][:type] = :band
    vspec[:scales][_scale_index_][:paddingInner] = opts[:space]

    s_spec_marks[:encode][:enter][_var_2_] = Dict{Symbol,Any}()

    s_spec_marks[:encode][:enter][_var_2_][:scale] = _scale_2_
    s_spec_marks[:encode][:enter][_var_][:field] = groupcol
    s_spec_marks[:encode][:enter][_var_][:band] = 0.5
    s_spec_marks[:encode][:enter][_var_][:offset] = Dict{Symbol,Any}(:signal => _addjitter(opts[:outlierjitter]))
    s_spec_marks[:encode][:enter][_var_2_][:field] = "__box__vars__outliers__"


    s_spec[:from] = Dict{Symbol,Any}()
    s_spec[:from][:facet] = Dict{Symbol,Any}()
    s_spec[:from][:facet][:name] = "group_facet_source"
    s_spec[:from][:facet][:data] = "box_data_outlier_$idx"
    s_spec[:from][:facet][:groupby] = groupcol
    s_spec_marks[:from][:data] = "group_facet_source"
    if opts[:outliercolor] !== nothing
        s_spec_marks[:encode][:enter][:fill] = Dict{Symbol, Any}(:value => opts[:outliercolor])
    else
        s_spec_marks[:encode][:enter][:fill][:scale] = "group_scale"
        s_spec_marks[:encode][:enter][:fill][:field] = "__box__groups__variable__"
    end

    s_spec[:encode] = Dict{Symbol,Any}()
    s_spec[:encode][:enter] = Dict{Symbol,Any}()
    # outliers should use the scale of original data because not all levels of "__box__groups__variable__" have outliers
    if _orient_ == :vertical
        s_spec[:encode][:enter][:x] = Dict{Symbol,Any}(:scale => _scale_, :field => groupcol)
        s_spec[:signals] = Dict{Symbol,Any}[Dict{Symbol,Any}(:name => "width", :update => "bandwidth('$(_scale_)')")]
        # for scale we collect group domain info from the main data no the facet one - i.e. we want the all group have the same number of categories
        s_spec[:scales] = Dict{Symbol,Any}[Dict{Symbol,Any}(:name => "pos_with_in_group", :type => :band, :range => "width", :domain => Dict{Symbol,Any}(:data => "box_data_$idx", :field => "__box__groups__variable__"), :paddingInner => opts[:groupspace])]
    else
        s_spec[:encode][:enter][:y] = Dict{Symbol,Any}(:scale => _scale_, :field => groupcol)
        s_spec[:signals] = Dict{Symbol,Any}[Dict{Symbol,Any}(:name => "height", :update => "bandwidth('$(_scale_)')")]
        s_spec[:scales] = Dict{Symbol,Any}[Dict{Symbol,Any}(:name => "pos_with_in_group", :type => :band, :range => "height", :domain => Dict{Symbol,Any}(:data => "box_data_$idx", :field => "__box__groups__variable__"), :paddingInner => opts[:groupspace])]
    end
    if all_args.axes[_scale_index_].opts[:reverse]
        s_spec[:scales][1][:reverse] = true
    end
    s_spec_marks[:encode][:enter][_var_][:scale] = "pos_with_in_group"
    s_spec_marks[:encode][:enter][_var_][:field] = "__box__groups__variable__"

    #####################fix
    s_spec[:from][:facet][:groupby] = groupcol
    s_spec[:marks] = [s_spec_marks]
    push!(vspec[:marks], s_spec)
end

# converts all column names to string, also check if the required arguments are passed
# TODO use macro to generate repeated code
function _check_and_normalize!(plt::BoxPlot, all_args)

    opts = plt.opts
    ds = all_args.ds
    threads = all_args.threads
    _extra_col_for_panel = all_args._extra_col_for_panel

    cols = String[]
    if opts[:x] != 0
        # here we need a vector of column indices
        colidx = IMD.index(ds)[opts[:x] isa IMD.ColumnIndex ? [opts[:x]] : opts[:x]]
        opts[:x] = [_colname_as_string(ds, i) for i in colidx]
        cols = opts[:x]
    elseif opts[:x] != 0
        @goto argerr
    end
    if opts[:y] != 0
        colidx = IMD.index(ds)[opts[:y] isa IMD.ColumnIndex ? [opts[:y]] : opts[:y]]
        opts[:y] = [_colname_as_string(ds, i) for i in colidx]
        cols = opts[:y]
    elseif opts[:y] != 0
        @goto argerr
    end

    # box plot allows multiple column as the analysis columns
    if all_args.mapformats
        _f = [getformat(ds, col) for col in cols]
    else
        _f = repeat([identity], length(cols))
    end

    # we need to refer to the names in bar_ds not ds - so index are not useful
    _extra_col_for_panel_names_ = names(ds, _extra_col_for_panel)
    if opts[:category] !== nothing
        if length(IMD.index(ds)[opts[:category]]) == 1
            opts[:category] = _colname_as_string(ds, opts[:category])
            g_col = unique(prepend!([opts[:category]], _extra_col_for_panel_names_))
        else
            @goto argerr
        end
    else
        g_col = _extra_col_for_panel_names_
    end
    
    box_ds = combine(gatherby(ds, g_col, mapformats=all_args.mapformats, threads=threads), cols .=> [x -> _box_plot_fun(x, plt.opts[:outliers], olf=plt.opts[:outliersfactor], fun=__f) for __f in _f] .=> ["__box__column__$col" for col in cols])
    # transpose data to put all analysis columns in a single group - the name for the new group column will be "__box__groups__variable__"
    box_ds = transpose(gatherby(box_ds, g_col, mapformats=all_args.mapformats, threads=threads), ["__box__column__$col" for col in cols], variable_name = "__box__groups__variable__", renamerowid = x -> replace(x, "__box__column__"=>""), renamecolid = x->"__col__id__in__transponse__")
    modify!(box_ds, "__col__id__in__transponse__" => splitter => [:__box__vars__q1, :__box__vars__q3, :__box__vars__med, :__box__vars__mean, :__box__vars__min, :__box__vars__max, :__box__vars__actual__min, :__box__vars__actual__max,:__box__vars__outliers__])
    # drop transpose column - we already splitted it into different columns
    select!(box_ds, Not("__col__id__in__transponse__"))
    
    # contains only outliers
    outliers_ds = select(box_ds, Not([:__box__vars__q1, :__box__vars__q3, :__box__vars__med, :__box__vars__mean, :__box__vars__min, :__box__vars__max,  :__box__vars__actual__min, :__box__vars__actual__max]))
    # contains everything else
    select!(box_ds, Not(:__box__vars__outliers__))
    if opts[:category] === nothing
        insertcols!(box_ds, :__box__fake__group__col__ => "variable(s)")
        insertcols!(outliers_ds, :__box__fake__group__col__ => "variable(s)")

    end
    if opts[:category] !== nothing
        if opts[:categoryorder] == :ascending 
            sort!(box_ds, opts[:category], mapformats = all_args.mapformats, threads = false)
        elseif opts[:categoryorder] == :descending 
            sort!(box_ds, opts[:category], rev=true, mapformats = all_args.mapformats, threads = false)
        end
    end
    return cols, box_ds, outliers_ds
    @label argerr
    throw(ArgumentError("only a single column must be selected"))
end

function _add_legends!(plt::BoxPlot, all_args, idx)
    opts = plt.opts
    # find the suitable scales for the legend
    # group, color, symbol, angle, ...
   which_scale = [opts[:category]]

    if opts[:legend] === nothing
        legend_id = "__internal__name__for__legend__$idx"
    else
        legend_id = opts[:legend]
    end
    if all_args.legends isa Vector
        loc_of_leg = findfirst(x->x.opts[:name] == legend_id, all_args.legends)
    else
        loc_of_leg = nothing
    end
    if loc_of_leg !== nothing # user provided some customisation
        leg_spec = all_args.legends[loc_of_leg]
    else
        leg_spec = Legend(name = legend_id)
    end
    
    # currently, group and symbol can be mixed
    # box plot use different color for each analysis variable
    leg_spec_cp = Dict{Symbol, Any}()    
    # if which_scale[1] !== nothing
        leg_spec_cp[:fill] = "group_scale"
        _build_legen!(leg_spec_cp, leg_spec.opts, "square", "variables", "$(legend_id)_group_scale_legend_$idx", all_args)
        push!(all_args.out_legends, leg_spec_cp)
    # end
end   