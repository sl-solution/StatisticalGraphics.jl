BAR_DEFAULT = Dict{Symbol,Any}(:x => 0, :y => 0, :group => nothing,
    :response => nothing,
    :stat => nothing, #by default, if response is given we use sum, if not we use freq - the function passed as stat must accept two arguments f and x, f is a function and x is a abstract vector. function apply f on each elements of x and return the aggregations
    :normalize => false, # use normalizer for more control about how to do it
    :normalizer => x -> x ./ sum(x), # within each level of x/y 
    :x2axis => false,
    :y2axis => false,
    :opacity => 1,
    :outlinethickness => 1,
    :barwidth => 1, # can be between[0,1], or :nest to display each group nested in the other one
    :nestfactor => nothing,
    :filled => true,
    :fill => "null",
    :fillcolor => :white,
    :opacity => 1,
    :color => "#4682b4",
    :colorresponse => nothing,
    :colorstat => nothing, # the same rule as :stat
    :colormodel => :diverging, # we use linear scale to produce colors
    :space => 0.1, # the space between bars - the space is calculated as space * total_bandwidth
    :groupspace => 0.05, # the space between bars inside each group - for groupdisplay = :cluster
    :outlinecolor => :white,
    :groupdisplay => :stack, #:stack, :cluster, :step (i.e. stacked and cluster), or :none
    :grouporder => :ascending, # :data, :ascending, :descending, userdefined order (by giving a vector of group level) - having a group column in panelby can cause some issues
    :orderresponse => nothing, # by default axis order control it, but it can be controlled by a column
    :orderstat => freq, # freq is default aggregator, however, it can be any other function 
    :baseline => 0,
    :baselineresponse => nothing,  # each bar (or each group when groupped) can have its own baseline 
    :baselinestat => nothing, # same rule as :stat

    #data label
    :label=>:none, # :height or :category
    :labelfont=>nothing,
    :labelbaseline=>nothing,
    :labelfontweight=>nothing,
    :labelitalic=>nothing,
    :labelsize=>nothing,
    :labelcolor=>:black,# allow :group, :colorresponse to use their color if available 
    :labelangle=>nothing,
    :labeldir=>:ltr,
    :labellimit=>nothing,
    :labeloffset=>0,
    :labelpos => :end, # :end, :start, :middle
    :labelloc=>0.5, # between 0 and 1
    :labeld3format=>"",
    :labelopacity=>1,
    :labelalign=>nothing,
    :tooltip => false, # it can be true, only if labelresponse is provided


    :legend => nothing, :barcorner => [0, 0, 0, 0], #corner radius (cornerRadiusTopLeft, cornerRadiusTopRight, cornerRadiusBottomLeft, cornerRadiusBottomRight)
    :clip => nothing
)
mutable struct Bar <: SGMarks
    opts
    function Bar(; opts...)
        optsd = val_opts(opts)
        cp_BAR_DEFAULT = update_default_opts!(deepcopy(BAR_DEFAULT), optsd)
        if (cp_BAR_DEFAULT[:x] == 0 && cp_BAR_DEFAULT[:y] == 0)
            throw(ArgumentError("Bar plot needs one of x or y keyword arguments"))
        end
        if !(cp_BAR_DEFAULT[:barcorner] isa AbstractVector)
            cp_BAR_DEFAULT[:barcorner] = fill(cp_BAR_DEFAULT[:barcorner], 4)
        else
            length(cp_BAR_DEFAULT[:barcorner]) != 4 && throw(ArgumentError("the barcorner option must be a single value or a vector of length four of values"))
        end
        !(cp_BAR_DEFAULT[:groupdisplay] in (:stack, :none, :cluster, :step)) && throw(ArgumentError("the groupdisplay option can be one of :stack, :cluster, :step, or :none"))
        if cp_BAR_DEFAULT[:x] == 0
            cp_BAR_DEFAULT[:labelbaseline] = something(cp_BAR_DEFAULT[:labelbaseline], :middle)
            _tmp_align = Dict(:end=>:right, :start=>:left, :middle=>:center)
            cp_BAR_DEFAULT[:labelalign] = something(cp_BAR_DEFAULT[:labelalign], _tmp_align[cp_BAR_DEFAULT[:labelpos]])

        else
            _tmp_align = Dict(:end=>:top, :start=>:bottom, :middle=>:middle)
            cp_BAR_DEFAULT[:labelbaseline] = something(cp_BAR_DEFAULT[:labelbaseline], _tmp_align[cp_BAR_DEFAULT[:labelpos]])
            cp_BAR_DEFAULT[:labelalign] = something(cp_BAR_DEFAULT[:labelalign], :center)
        end
        new(cp_BAR_DEFAULT)
    end
end

# Bar produces a simple Barchart
# It requires one of x or y keyword arguments 
# It needs the input data be processed before being sent to  vega
function _push_plots!(vspec, plt::Bar, all_args; idx=1)
    # check if the required arguments are passed / create a new ds and push it to out_ds
    col, new_ds = _check_and_normalize!(plt, all_args)
    _add_legends!(plt, all_args, idx)
    data_csv = tempname()
    filewriter(data_csv, new_ds, mapformats=all_args.mapformats, quotechar='"')
    push!(vspec[:data], _prepare_data("bar_data_$idx", data_csv, new_ds, all_args))

    # # we add baseline to new_ds to make sure that domains calculation are adjusted
    # append!(new_ds, map(new_ds, x->plt.opts[:baseline], :__height__bar__, threads=false), promote = true)
    opts = plt.opts

    s_spec = Dict{Symbol,Any}()
    s_spec[:type] = "group"
    s_spec[:clip] = something(opts[:clip], all_args.opts[:clip])
    s_spec_marks = Dict{Symbol,Any}()
    s_spec_marks[:type] = "rect"
    s_spec_marks[:from] = Dict(:data => "bar_data_$idx")
    s_spec_marks[:encode] = Dict{Symbol,Any}()
    s_spec_marks[:encode][:enter] = Dict{Symbol,Any}()
    s_spec_marks[:encode][:enter][:cornerRadiusTopLeft] = Dict{Symbol,Any}(:value => opts[:barcorner][1])
    s_spec_marks[:encode][:enter][:cornerRadiusTopRight] = Dict{Symbol,Any}(:value => opts[:barcorner][2])
    s_spec_marks[:encode][:enter][:cornerRadiusBottomLeft] = Dict{Symbol,Any}(:value => opts[:barcorner][3])
    s_spec_marks[:encode][:enter][:cornerRadiusBottomRight] = Dict{Symbol,Any}(:value => opts[:barcorner][4])
    s_spec_marks[:encode][:enter][:opacity] = Dict{Symbol,Any}(:value => opts[:opacity])
    s_spec_marks[:encode][:enter][:stroke] = Dict{Symbol,Any}(:value => opts[:outlinecolor])
    s_spec_marks[:encode][:enter][:strokeWidth] = Dict{Symbol,Any}(:signal => "isValid(datum['__height__bar__']) ? $(opts[:outlinethickness]) : 0")
    s_spec_marks[:encode][:enter][:fill] = Dict{Symbol,Any}()

    if opts[:colorresponse] !== nothing
        s_spec_marks[:encode][:enter][:fill][:scale] = "color_scale_$idx"
        s_spec_marks[:encode][:enter][:fill][:field] = "__color__value__"
        addto_color_scale!(vspec, "bar_data_$idx", "color_scale_$idx", "__color__value__", false; color_model=opts[:colormodel])
    end


    # extract the information about the bar chart
    if opts[:x] != 0
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
    if opts[:barwidth] == :nest
        s_spec_marks[:encode][:enter][_var_][:band] = Dict{Symbol, Any}(:field=>"$(sg_col_prefix)nest__barwidth_complement")
        if _orient_ == :vertical
            s_spec_marks[:encode][:enter][:width] = Dict{Symbol,Any}(:scale => _scale_, :band => Dict{Symbol, Any}(:field=>"$(sg_col_prefix)nest__barwidth"))
        else
            s_spec_marks[:encode][:enter][:height] = Dict{Symbol,Any}(:scale => _scale_, :band => Dict{Symbol, Any}(:field=>"$(sg_col_prefix)nest__barwidth"))
        end
    else
        complement_bandwidth = (1 - opts[:barwidth]) / 2
        s_spec_marks[:encode][:enter][_var_][:band] = complement_bandwidth
        if _orient_ == :vertical
            s_spec_marks[:encode][:enter][:width] = Dict{Symbol,Any}(:scale => _scale_, :band => opts[:barwidth])
        else
            s_spec_marks[:encode][:enter][:height] = Dict{Symbol,Any}(:scale => _scale_, :band => opts[:barwidth])
        end
    end

    # we make sure addto_scale! knows about type before obtaining domain
    vspec[:scales][_scale_index_][:type] = :band
    all_args.scale_type[_scale_index_] = :band
    addto_scale!(all_args, _scale_index_, new_ds, col)
    addto_axis!(vspec[:axes][_scale_index_], all_args.axes[_scale_index_], opts[_var_])
    vspec[:scales][_scale_index_][:type] = :band
    vspec[:scales][_scale_index_][:paddingInner] = opts[:space]

    s_spec_marks[:encode][:enter][_var_2_] = Dict{Symbol,Any}()
    s_spec_marks[:encode][:enter][Symbol(_var_2_, 2)] = Dict{Symbol,Any}()

    s_spec_marks[:encode][:enter][_var_2_][:scale] = _scale_2_
    s_spec_marks[:encode][:enter][Symbol(_var_2_, 2)][:scale] = _scale_2_
    addto_scale!(all_args, _scale_2_index_, new_ds, "__height__bar__")
    addto_scale!(all_args, _scale_2_index_, new_ds, "__height__bar__start__")
    addto_axis!(vspec[:axes][_scale_2_index_], all_args.axes[_scale_2_index_], string(opts[:stat], " of ", opts[:response] === nothing ? opts[_var_] : opts[:response]))
    s_spec_marks[:encode][:enter][_var_][:field] = col
    s_spec_marks[:encode][:enter][_var_2_][:field] = "__height__bar__"
    s_spec_marks[:encode][:enter][Symbol(_var_2_, 2)][:field] = "__height__bar__start__"

    if opts[:group] === nothing
        s_spec_marks[:encode][:enter][:fill][:value] = opts[:color]
    else
        s_spec[:from] = Dict{Symbol,Any}()
        s_spec[:from][:facet] = Dict{Symbol,Any}()
        s_spec[:from][:facet][:name] = "group_facet_source"
        s_spec[:from][:facet][:data] = "bar_data_$idx"
        s_spec[:from][:facet][:groupby] = opts[:group]
        s_spec_marks[:from][:data] = "group_facet_source"
        s_spec_marks[:encode][:enter][:fill][:scale] = "group_scale"
        s_spec_marks[:encode][:enter][:fill][:field] = opts[:group]
        # group is the 5th element of scales
        addto_group_scale!(vspec[:scales][5], "bar_data_$idx", opts[:group], all_args)
        # for cluster we need to define y value and add a new scale
        if opts[:groupdisplay] in (:cluster, :step)
            s_spec[:encode] = Dict{Symbol,Any}()
            s_spec[:encode][:enter] = Dict{Symbol,Any}()
            if _orient_ == :vertical
                s_spec[:encode][:enter][:x] = Dict{Symbol,Any}(:scale => _scale_, :field => col)
                s_spec[:signals] = Dict{Symbol,Any}[Dict{Symbol,Any}(:name => "width", :update => "bandwidth('$(_scale_)')")]
                # for scale we collect group domain info from the main data no the facet one - i.e. we want the all group have the same number of categories
                s_spec[:scales] = Dict{Symbol,Any}[Dict{Symbol,Any}(:name => "pos_with_in_group", :type => :band, :range => "width", :domain => Dict{Symbol,Any}(:data => "bar_data_$idx", :field => opts[:group]), :paddingInner => opts[:groupspace])]
            else
                s_spec[:encode][:enter][:y] = Dict{Symbol,Any}(:scale => _scale_, :field => col)
                s_spec[:signals] = Dict{Symbol,Any}[Dict{Symbol,Any}(:name => "height", :update => "bandwidth('$(_scale_)')")]
                s_spec[:scales] = Dict{Symbol,Any}[Dict{Symbol,Any}(:name => "pos_with_in_group", :type => :band, :range => "height", :domain => Dict{Symbol,Any}(:data => "bar_data_$idx", :field => opts[:group]), :paddingInner => opts[:groupspace])]
            end
            if all_args.axes[_scale_index_].opts[:reverse]
                s_spec[:scales][1][:reverse] = true
            end
            s_spec_marks[:encode][:enter][_var_][:scale] = "pos_with_in_group"
            s_spec_marks[:encode][:enter][_var_][:field] = opts[:group]
            if _orient_ == :vertical
                s_spec_marks[:encode][:enter][:width][:scale] = "pos_with_in_group"
            else
                s_spec_marks[:encode][:enter][:height][:scale] = "pos_with_in_group"
            end
            s_spec[:from][:facet][:groupby] = col
        end
    end
    s_spec[:marks] = [s_spec_marks]
    push!(vspec[:marks], s_spec)
    if opts[:label] in (:height, :category)
        whole_mk = deepcopy(s_spec)
        _segment_label!(whole_mk[:marks][1], _var_, _var_2_, all_args, opts)
        push!(vspec[:marks], whole_mk)
    end
    
end


# converts all column names to string, also check if the required arguments are passed
# TODO use macro to generate repeated code
function _check_and_normalize!(plt::Bar, all_args)

    opts = plt.opts
    ds = all_args.ds
    threads = all_args.threads
    _extra_col_for_panel = all_args._extra_col_for_panel

    col = ""
    if opts[:x] != 0 && length(IMD.index(ds)[opts[:x]]) == 1
        opts[:x] = _colname_as_string(ds, opts[:x])
        col = opts[:x]
    elseif opts[:x] != 0
        @goto argerr
    end
    if opts[:y] != 0 && length(IMD.index(ds)[opts[:y]]) == 1
        opts[:y] = _colname_as_string(ds, opts[:y])
        col = opts[:y]
    elseif opts[:y] != 0
        @goto argerr
    end
    if opts[:response] !== nothing && length(IMD.index(ds)[opts[:response]]) == 1
        opts[:response] = _colname_as_string(ds, opts[:response])
    elseif opts[:response] !== nothing
        @goto argerr
    end
    color_response = ""
    if opts[:colorresponse] !== nothing
        if length(IMD.index(ds)[opts[:colorresponse]]) == 1
            opts[:colorresponse] = _colname_as_string(ds, opts[:colorresponse])
        else
            @goto argerr
        end
        color_response = opts[:colorresponse]
    else
        # if colorresponse is not passed we define it as col so our combine phase can go without a problem
        color_response = col
    end
    _f_color = identity
    if all_args.mapformats
        _f_color = getformat(ds, color_response)
    end
    if opts[:colorstat] === nothing
        color_stat = freq
    else
        color_stat = opts[:colorstat]
    end


    base_response = ""
    if opts[:baselineresponse] !== nothing
        if length(IMD.index(ds)[opts[:baselineresponse]]) == 1
            opts[:baselineresponse] = _colname_as_string(ds, opts[:baselineresponse])
        else
            @goto argerr
        end
        base_response = opts[:baselineresponse]
    else
        # if baselineresponse is not passed we define it as col so our combine phase can go without a problem
        base_response = col
    end
    _f_base = identity
    if all_args.mapformats
        _f_base = getformat(ds, base_response)
    end
    if opts[:baselinestat] === nothing
        base_stat = freq
    else
        base_stat = opts[:baselinestat]
    end

    if all_args.mapformats
        _f = getformat(ds, col)
    else
        _f = identity
    end

    if opts[:orderresponse] !== nothing
        if length(IMD.index(ds)[opts[:orderresponse]]) == 1
            opts[:orderresponse] = _colname_as_string(ds, opts[:orderresponse])
        else
            @goto argerr
        end
        _f_order = identity
        if all_args.mapformats
            _f_order = getformat(ds, opts[:orderresponse])
        end
    end


    if opts[:group] !== nothing
        opts[:colorresponse] !== nothing && throw(ArgumentError("only one of group or colorresponse must be passed"))
        if length(IMD.index(ds)[opts[:group]]) == 1
            opts[:group] = _colname_as_string(ds, opts[:group])
            g_col = unique(prepend!([IMD.index(ds)[opts[:group]]], _extra_col_for_panel))
        else
            @goto argerr
        end
    else
        g_col = copy(_extra_col_for_panel)
    end
    # we need to refer to the names in bar_ds not ds - so index are not useful
    _extra_col_for_panel_names_ = names(ds, _extra_col_for_panel)
    unique!(pushfirst!(g_col, IMD.index(ds)[col]))

    if opts[:response] === nothing
        # TODO we should move this to constructor
        if opts[:stat] === nothing
            opts[:stat] = freq
        end

        bar_ds = combine(gatherby(ds, g_col, mapformats=all_args.mapformats, threads=threads), col => (x -> opts[:stat](_f, x)) => :__height__bar__, color_response => (x -> color_stat(_f_color, x)) => :__color__value__, threads=threads)
        if opts[:normalize] && opts[:group] !== nothing
            modify!(gatherby(bar_ds, [col; _extra_col_for_panel_names_], mapformats=all_args.mapformats, threads=false), :__height__bar__ => opts[:normalizer], threads=false)
        elseif opts[:normalize] && opts[:group] === nothing
            throw(ArgumentError("group column must be specified when normalize=true"))
        end
        #baseline must be computed within each group
        #we use hash method, since we are not sure the panel columns are sortable
        bar_ds_base = combine(gatherby(ds, unique([col; _extra_col_for_panel_names_]), mapformats=all_args.mapformats, threads=threads), base_response => (x -> base_stat(_f_base, x)) => :__baseline__value__, threads=threads)
        leftjoin!(bar_ds, bar_ds_base[!, unique(["__baseline__value__"; col; _extra_col_for_panel_names_])], on=unique([col; _extra_col_for_panel_names_]), method=:hash, mapformats=all_args.mapformats)
        if opts[:group] !== nothing
            if opts[:grouporder] == :ascending
                sort!(bar_ds, opts[:group], mapformats=all_args.mapformats, threads=false)
            elseif opts[:grouporder] == :decending
                sort!(bar_ds, opts[:group], rev=true, mapformats=all_args.mapformats, threads=false)
            elseif opts[:grouporder] isa AbstractVector
                leftjoin!(bar_ds, Dataset("$(sg_col_prefix)_bar_order_userdefine"=>opts[:grouporder], "$(sg_col_prefix)_bar_order_user"=>1:length(opts[:grouporder])), on = opts[:group] => "$(sg_col_prefix)_bar_order_userdefine", mapformats=all_args.mapformats, threads = false, method=:hash)
                sort!(bar_ds, "$(sg_col_prefix)_bar_order_user", mapformats=all_args.mapformats, threads=false)
            end
        end
        insertcols!(bar_ds, :__height__bar__start__ => plt.opts[:baseline])
        # if groupdisplay is stack we should stack the values
        if opts[:group] !== nothing && opts[:groupdisplay] in (:stack, :step)
            g_col = unique(push!(_extra_col_for_panel_names_, col))
            modify!(gatherby(bar_ds, g_col, mapformats=all_args.mapformats, threads=threads), :__height__bar__ => cumsum, :__height__bar__ => (x -> lag(x, 1, default=opts[:baseline])) => :__height__bar__start__, threads=false)
        end
    else
        _f_response = identity
        if all_args.mapformats
            _f_response = getformat(ds, opts[:response])
        end
        if opts[:stat] === nothing
            opts[:stat] = IMD.sum
        end
        bar_ds = combine(gatherby(ds, g_col, mapformats=all_args.mapformats, threads=threads), opts[:response] => (x -> opts[:stat](_f_response, x)) => :__height__bar__, color_response => (x -> color_stat(_f_color, x)) => :__color__value__, threads=threads)
        if opts[:normalize] && opts[:group] !== nothing
            modify!(gatherby(bar_ds, [col; _extra_col_for_panel_names_], mapformats=all_args.mapformats, threads=false), :__height__bar__ => opts[:normalizer], threads=false)
        elseif opts[:normalize] && opts[:group] === nothing
            throw(ArgumentError("group column must be specified when normalize=true"))
        end
        #baseline must be computed within each group
        #we use hash method, since we are not sure the panel columns are sortable
        bar_ds_base = combine(gatherby(ds, unique([col; _extra_col_for_panel_names_]), mapformats=all_args.mapformats, threads=false), base_response => (x -> base_stat(_f_base, x)) => :__baseline__value__)
        leftjoin!(bar_ds, bar_ds_base[!, unique(["__baseline__value__"; col; _extra_col_for_panel_names_])], on=unique([col; _extra_col_for_panel_names_]), method=:hash, mapformats=all_args.mapformats, threads=false)
        if opts[:group] !== nothing
            if opts[:grouporder] == :ascending
                sort!(bar_ds, opts[:group], mapformats=all_args.mapformats, threads=false)
            elseif opts[:grouporder] == :decending
                sort!(bar_ds, opts[:group], rev=true, mapformats=all_args.mapformats, threads=false)
            elseif opts[:grouporder] isa AbstractVector
                leftjoin!(bar_ds, Dataset("$(sg_col_prefix)_bar_order_userdefine"=>opts[:grouporder], "$(sg_col_prefix)_bar_order_user"=>1:length(opts[:grouporder])), on = opts[:group] => "$(sg_col_prefix)_bar_order_userdefine", mapformats=all_args.mapformats, threads = false, method=:hash)
                sort!(bar_ds, "$(sg_col_prefix)_bar_order_user", mapformats=all_args.mapformats, threads=false)
            end
            
        end
        insertcols!(bar_ds, :__height__bar__start__ => plt.opts[:baseline])
        if opts[:group] !== nothing && opts[:groupdisplay] in (:stack, :step)
            g_col = unique(push!(_extra_col_for_panel_names_, col))
            modify!(gatherby(bar_ds, g_col, mapformats=all_args.mapformats, threads=threads), :__height__bar__ => cumsum, :__height__bar__ => (x -> lag(x, 1, default=opts[:baseline])) => :__height__bar__start__, threads=threads)
        end
    end
    # the axes order must be :data for the following to be effective
    if opts[:orderresponse] !== nothing
        bar_order = combine(gatherby(ds, unique([col; _extra_col_for_panel_names_]), mapformats=all_args.mapformats, threads=all_args.threads), opts[:orderresponse] => (x -> opts[:orderstat](_f_order, x)) => :__bar__order__column__, threads=threads)
        leftjoin!(bar_ds, bar_order, on=unique([col; _extra_col_for_panel_names_]), mapformats=all_args.mapformats, threads=false, method=:hash)
        sort!(bar_ds, :__bar__order__column__)
    end

    #TODO should we apply baselineresponse after sorting?
    if opts[:baselineresponse] !== nothing
        modify!(bar_ds, [[:__height__bar__, :__baseline__value__], [:__height__bar__start__, :__baseline__value__]] .=> byrow(sum) .=> [:__height__bar__, :__height__bar__start__])
    end

    # take care of nested display
    if opts[:barwidth] == :nest && opts[:group] !== nothing
        nest_factor_lookup = Dict(1=>0, 2 => 0.3, (3:4 .=> 0.2)..., (5:7 .=> 0.15)...) # for more than 8 we calculate it
        g_col = unique(push!(_extra_col_for_panel_names_, col))
        # find the maximum number of group in one single category
        _temp_ds_ = combine(gatherby(bar_ds, g_col, mapformats=all_args.mapformats, threads = false), 1 => length => "$(sg_col_prefix)number__of__groups")
        max_level = IMD.maximum(_temp_ds_[!, "$(sg_col_prefix)number__of__groups"])
        
        if opts[:nestfactor] === nothing
            if haskey(nest_factor_lookup, max_level)
                opts[:nestfactor] = nest_factor_lookup[max_level]
            else
                opts[:nestfactor] = 1 / max_level
            end
        end
        _temp_ds_ = select(bar_ds, opts[:group])
        unique!(_temp_ds_, opts[:group], mapformats = all_args.mapformats, threads=false)
        modify!(_temp_ds_, 1 => (x -> _nest_barwidth_calculate(x, opts[:nestfactor])) => "$(sg_col_prefix)nest__barwidth", "$(sg_col_prefix)nest__barwidth" => byrow(x -> (1 - x) / 2) => "$(sg_col_prefix)nest__barwidth_complement", threads=false)
        leftjoin!(bar_ds, _temp_ds_, on=opts[:group], mapformats=all_args.mapformats, threads=false, method=:hash)
    end
    # make sure that values are recorded properly - sometime the column type may be Any and this will cause problem later when we are obtaining the domains
    #TODO we need to take the same approach for other chart types
    modify!(bar_ds, [:__height__bar__, :__height__bar__start__, :__baseline__value__, :__color__value__] .=> byrow(identity), threads=false)
    modify!(bar_ds, [:__height__bar__, :__height__bar__start__] .=> byrow(Float64), threads=false)

    return col, bar_ds
    @label argerr
    throw(ArgumentError("only a single column must be selected"))
end

function _nest_barwidth_calculate(x, nest_factor)
    res = ones(length(x))
    for i in 2:length(x)
        res[i] = res[i-1] - nest_factor
    end
    res
end


function _add_legends!(plt::Bar, all_args, idx)
    opts = plt.opts
    # find the suitable scales for the legend
    # group, color, symbol, angle, ...
    which_scale = [opts[:group], opts[:colorresponse]]

    if opts[:legend] === nothing
        legend_id = "__internal__name__for__legend__$idx"
    else
        legend_id = opts[:legend]
    end
    if all_args.legends isa Vector
        loc_of_leg = findfirst(x -> x.opts[:name] == legend_id, all_args.legends)
    else
        loc_of_leg = nothing
    end
    if loc_of_leg !== nothing # user provided some customisation
        leg_spec = all_args.legends[loc_of_leg]
    else
        leg_spec = Legend(name=legend_id)
    end


    leg_spec_cp = Dict{Symbol,Any}()
    if which_scale[1] !== nothing
        _title = which_scale[1]
        leg_spec_cp[:fill] = "group_scale"
        _build_legen!(leg_spec_cp, leg_spec.opts, "square", _title, "$(legend_id)_group_scale_legend_$idx", all_args)
        push!(all_args.out_legends, leg_spec_cp)
    end

    leg_spec_cp = Dict{Symbol,Any}()
    if which_scale[2] !== nothing
        _title = which_scale[2]
        leg_spec_cp[:fill] = "color_scale_$idx"
        _build_legen!(leg_spec_cp, leg_spec.opts, "square", _title, "$(legend_id)_color_scale_legend_$idx", all_args)
        push!(all_args.out_legends, leg_spec_cp)
    end
end   


function _segment_label!(mk, cat, var, all_args, opts)
    mk[:type] = "text"

    mk_encode = mk[:encode][:enter]

    for prop in [:stroke, :strokeWidth, :height, :width, :cornerRadiusBottomLeft, :cornerRadiusTopLeft, :cornerRadiusBottomRight, :cornerRadiusTopRight]
        delete!(mk_encode, prop)
    end

    mk_encode[:opacity] = Dict{Symbol, Any}(:value => opts[:labelopacity])
    if opts[:labelcolor] == :auto && opts[:group] !== nothing
        mk_encode[:fill] = Dict{Symbol, Any}(:signal =>  "isValid(datum['__height__bar__']) ? contrast('black', scale('group_scale', datum['$(opts[:group])'])) > contrast('white', scale('group_scale', datum['$(opts[:group])'])) ? 'black' : 'white' : 'transparent'" )
    else
        if opts[:labelcolor] == :auto
            opts[:labelcolor] = :black
        end
        mk_encode[:fill] = Dict{Symbol, Any}(:signal =>  "isValid(datum['__height__bar__']) ? '$(opts[:labelcolor])' : 'transparent'" )
    end
    mk_encode[:text] =  deepcopy(mk_encode[var])
    delete!(mk_encode[:text], :scale)
    delete!(mk_encode[:text], :field)
    delete!(mk_encode[var], :field)

    if opts[:label] == :height 
        mk_encode[:text][:signal] = "format(datum['__height__bar__'] - datum['__height__bar__start__'], '$(opts[:labeld3format])')"
    else
        if opts[:group] === nothing
            mk_encode[:text][:field] = "$(opts[cat])"
        else
            mk_encode[:text][:field] = "$(opts[:group])"
        end
    end


    mk_encode[var][:offset] =  opts[:labeloffset]
    if opts[:labelpos] == :end 
        mk_encode[var][:field] = "__height__bar__"
    elseif opts[:labelpos] == :start 
        mk_encode[var][:field] = "__height__bar__start__"
    elseif opts[:labelpos] == :middle 
        mk_encode[var][:signal] = "(datum['__height__bar__'] + datum['__height__bar__start__'])/2"
    end
    delete!(mk_encode, Symbol(var,2))

    mk_encode[cat][:band] = opts[:labelloc]
   
    if opts[:labelangle] !== nothing
        mk_encode[:angle] = Dict{Symbol, Any}(:value => opts[:labelangle])
    end
    if opts[:labelalign] !== nothing
        mk_encode[:align] = Dict{Symbol, Any}(:value => opts[:labelalign])
    end
    mk_encode[:baseline] = Dict{Symbol, Any}(:value => opts[:labelbaseline])
    mk_encode[:font] = Dict{Symbol, Any}(:value => something(opts[:labelfont], all_args.opts[:font]))
    mk_encode[:fontWeight] = Dict{Symbol, Any}(:value => something(opts[:labelfontweight], all_args.opts[:fontweight]))
    mk_encode[:fontStyle] = Dict{Symbol, Any}(:value => something(opts[:labelitalic], all_args.opts[:italic] ? "italic" : "normal"))

    if opts[:labelsize] !== nothing
        mk_encode[:fontSize] = Dict{Symbol, Any}(:value => opts[:labelsize])
    end
    mk_encode[:dir] = Dict{Symbol,Any}(:value => opts[:labeldir])
    if opts[:labellimit] !== nothing
        mk_encode[:limit] = Dict{Symbol,Any}(:value => opts[:labellimit])
    end
    mk
end
