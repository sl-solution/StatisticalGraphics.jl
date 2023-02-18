VIOLIN_DEFAULT = Dict{Symbol,Any}(:x => 0, :y => 0, :category => nothing, # x or y can be a set of analysis variables
   
    :x2axis => false,
    :y2axis => false,
    
    :side=>:both, # :both, :right(:bottom), :left(:top)

    :thickness => 1,

    :weights => :gaussian,
    :bw => nothing,
    :npoints=>100, # the grid number of points
    :interpolate => :linear,
    :scale => (x; args...) -> x, # see Density for more information

    :fillopacity=>0.5,
    :opacity=>1,

    :filled => true,
    :fillcolor => nothing, # derive from :color


    :color => nothing,
    :space => 0.1, # the space between violins 
    :groupspace => 0.05, # the space between violins inside each group 
    :categoryorder => :ascending, # :data, :ascending, :descending
  
    :legend => nothing,

    :missingmode => 0, # how to handle missings in category.  0 = nothing, 1 = no missing in category

    :tooltip=>false,
    :clip=>nothing

)
mutable struct Violin <: SGMarks
    opts
    function Violin(; opts...)
        optsd = val_opts(opts)
        cp_VIOLIN_DEFAULT = update_default_opts!(deepcopy(VIOLIN_DEFAULT), optsd)
        haskey(cp_VIOLIN_DEFAULT, :group) && throw(ArgumentError("Violin does not support the group keyword argument, pass category for creating violin plot across different level of a column"))
        if (cp_VIOLIN_DEFAULT[:x] == 0 && cp_VIOLIN_DEFAULT[:y] == 0) || (cp_VIOLIN_DEFAULT[:x] != 0 && cp_VIOLIN_DEFAULT[:y] != 0)
            throw(ArgumentError("Violin plot needs one of x or y keyword arguments"))
        end
        new(cp_VIOLIN_DEFAULT)
    end
end


# Violin produces a Violin plot chart
# It requires one of x or y keyword arguments 
# It needs the input data be processed before being sent to  vega
function _push_plots!(vspec, plt::Violin, all_args; idx=1)
    # check if the required arguments are passed / create a new ds and push it to out_ds
    cols, new_ds, max_density = _check_and_normalize!(plt, all_args)
    if plt.opts[:missingmode] == 1 && plt.opts[:category] !== nothing
        dropmissing!(new_ds, plt.opts[:category], threads = false, mapformats=all_args.mapformats)
    end
    _add_legends!(plt, all_args, idx)
    data_csv = tempname()
    filewriter(data_csv, new_ds, mapformats=all_args.mapformats, quotechar='"')
    push!(vspec[:data], _prepare_data("violin_data_$idx", data_csv, new_ds, all_args))

    # now we push every component of the box plot
    _push_violin!(vspec, plt, all_args, new_ds, max_density; idx=idx)
end
function _push_violin!(vspec, plt, all_args, new_ds, max_density; idx=1)
    opts = plt.opts

    groupcol = opts[:category] === nothing ? "__violin__fake__group__col__" : opts[:category]

    s_spec = Dict{Symbol,Any}()
    s_spec[:type] = "group"
    s_spec[:clip] = something(opts[:clip], all_args.opts[:clip])
   
    s_spec[:from] = Dict{Symbol,Any}()
    s_spec[:from][:facet] = Dict{Symbol,Any}()
    s_spec[:from][:facet][:name] = "group_facet_source"
    s_spec[:from][:facet][:data] = "violin_data_$idx"
    s_spec[:from][:facet][:groupby] = groupcol
   

    # extract the information about the box chart
   
    if opts[:x] == 0
        _var_ = :x
        _var_2_ = :y
        _orient_ = :vertical
        _orient_v = :width
        _orient_v_2 = :height
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
        _orient_v = :height
        _orient_v_2 = :width
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

    s_spec[:encode] = Dict{Symbol,Any}()
    s_spec[:encode][:enter] = Dict{Symbol,Any}()
    if _orient_ == :vertical
        s_spec[:encode][:enter][:x] = Dict{Symbol,Any}(:scale => _scale_, :field => groupcol)
        s_spec[:signals] = Dict{Symbol,Any}[Dict{Symbol,Any}(:name => "width", :update => "bandwidth('$(_scale_)')")]
        # for scale we collect group domain info from the main data no the facet one - i.e. we want the all group have the same number of categories
        s_spec[:scales] = Dict{Symbol,Any}[Dict{Symbol,Any}(:name => "pos_with_in_group", :type => :band, :range => "width", :domain => Dict{Symbol,Any}(:data => "violin_data_$idx", :field => "__violin__groups__variable__"), :paddingInner => opts[:groupspace])]
    else
        s_spec[:encode][:enter][:y] = Dict{Symbol,Any}(:scale => _scale_, :field => groupcol)
        s_spec[:signals] = Dict{Symbol,Any}[Dict{Symbol,Any}(:name => "height", :update => "bandwidth('$(_scale_)')")]
        s_spec[:scales] = Dict{Symbol,Any}[Dict{Symbol,Any}(:name => "pos_with_in_group", :type => :band, :range => "height", :domain => Dict{Symbol,Any}(:data => "violin_data_$idx", :field => "__violin__groups__variable__"), :paddingInner => opts[:groupspace])]
    end
    if all_args.axes[_scale_index_].opts[:reverse]
        s_spec[:scales][1][:reverse] = true
    end
    # group is the 5th element of scales
    push!(all_args.nominal, "__violin__groups__variable__")
    addto_group_scale!(vspec[:scales][5], "violin_data_$idx", "__violin__groups__variable__", all_args)

    
    s_spec_marks = Dict{Symbol,Any}()
    s_spec_marks[:type] = "group"
    s_spec_marks[:from] = Dict{Symbol,Any}()
    s_spec_marks[:from][:facet] = Dict{Symbol, Any}()
    s_spec_marks[:from][:facet][:name] = "group_facet_source_within"
    s_spec_marks[:from][:facet][:groupby] = "__violin__groups__variable__"
    s_spec_marks[:from][:facet][:data] = "group_facet_source"

    s_spec_marks[:signals] = [Dict{Symbol, Any}(:name=>_orient_v, :update => "bandwidth('pos_with_in_group')")]

    s_spec_marks[:scales] = [Dict{Symbol, Any}(:name=>"violin_$idx", :range=>_orient_v, :domain => sort([-max_density, max_density]), :type=>:linear)]

    s_spec_marks[:encode] = Dict{Symbol, Any}()
    s_spec_marks[:encode][:enter] = Dict{Symbol, Any}()
    s_spec_marks[:encode][:enter][_orient_v] = Dict{Symbol, Any}(:band=>1, :scale => "pos_with_in_group")
    s_spec_marks[:encode][:enter][_var_] = Dict{Symbol, Any}(:field=> "__violin__groups__variable__", :band=>0, :scale => "pos_with_in_group")
    s_spec_marks[:encode][:enter][_orient_v_2] = Dict{Symbol, Any}(:signal => _orient_v_2)

    s_spec_marks[:marks] = Dict{Symbol, Any}[]
   
    s_violin = Dict{Symbol, Any}()
    s_violin[:type] = "area"
    s_violin[:from] = Dict{Symbol, Any}(:data=> "group_facet_source_within")
    s_violin[:encode] = Dict{Symbol, Any}()
    s_violin[:encode][:enter] = Dict{Symbol, Any}()
    s_violin[:encode][:enter][_var_2_] = Dict{Symbol, Any}(:field => "$(sg_col_prefix)midpoint__density__", :scale => _scale_2_)
   
    s_violin[:encode][:enter][Symbol(_var_,2)] = Dict{Symbol, Any}(:value => 0, :scale => "violin_$idx")
    if opts[:filled]
        s_violin[:encode][:enter][:fill] = Dict{Symbol, Any}()
        s_violin[:encode][:enter][:fill][:field] = "__violin__groups__variable__"
        s_violin[:encode][:enter][:fill][:scale] = "group_scale"
    else
        s_violin[:encode][:enter][:fill] = Dict{Symbol, Any}(:value=>:transparent)
    end
    if opts[:color] !== nothing
        s_violin[:encode][:enter][:stroke] = Dict{Symbol, Any}(:value=>opts[:color])
    else
        s_violin[:encode][:enter][:stroke] = Dict{Symbol, Any}()
        s_violin[:encode][:enter][:stroke][:field] = "__violin__groups__variable__"
        s_violin[:encode][:enter][:stroke][:scale] = "group_scale"
    end
    s_violin[:encode][:enter][:fillOpacity] = Dict{Symbol, Any}(:value=>opts[:fillopacity])
    s_violin[:encode][:enter][:interpolate] = Dict{Symbol, Any}(:value=>opts[:interpolate])
    s_violin[:encode][:enter][:strokeWidth] = Dict{Symbol, Any}(:value=>opts[:thickness])
    s_violin[:encode][:enter][:orient] = Dict{Symbol,Any}(:value => _orient_ == :vertical ? :horizontal : :vertical)
    addto_scale!(all_args, _scale_2_index_, new_ds, "$(sg_col_prefix)midpoint__density__")
    addto_axis!(vspec[:axes][_scale_2_index_], all_args.axes[_scale_2_index_], "")
    all_args.scale_type[_scale_index_] = :band
    addto_scale!(all_args, _scale_index_, new_ds, groupcol)
    addto_axis!(vspec[:axes][_scale_index_], all_args.axes[_scale_index_], opts[:category] === nothing ? "" : opts[:category])
    vspec[:scales][_scale_index_][:type] = :band
    vspec[:scales][_scale_index_][:paddingInner] = opts[:space]

    # s_violin[:encode][:enter][_var_] = Dict{Symbol, Any}(:signal => "datum['$(sg_col_prefix)height__density__']", :scale => "violin_$idx")

    if opts[:side] == :both 
        s_violin[:encode][:enter][_var_] = Dict{Symbol, Any}(:signal => "datum['$(sg_col_prefix)height__density__']", :scale => "violin_$idx")
        s_violin[:encode][:enter][Symbol(_var_,2)] = Dict{Symbol, Any}(:signal => "-datum['$(sg_col_prefix)height__density__']", :scale => "violin_$idx")
        push!(s_spec_marks[:marks], s_violin)
    end
    if opts[:side] in (:right, :top)
        s_violin_l = deepcopy(s_violin)
        s_violin_l[:encode][:enter][_var_] = Dict{Symbol, Any}(:signal => "datum['$(sg_col_prefix)height__density__']", :scale => "violin_$idx")
        push!(s_spec_marks[:marks], s_violin_l)
    end
    if opts[:side] in (:left, :bottom)
        s_violin_r = deepcopy(s_violin)
        s_violin_r[:encode][:enter][_var_] = Dict{Symbol, Any}(:signal => "-datum['$(sg_col_prefix)height__density__']", :scale => "violin_$idx")
        push!(s_spec_marks[:marks], s_violin_r)
    end

    s_spec[:marks] = [s_spec_marks]
    push!(vspec[:marks], s_spec)

end

# converts all column names to string, also check if the required arguments are passed
# TODO use macro to generate repeated code
function _check_and_normalize!(plt::Violin, all_args)

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

    # violin plot allows multiple column as the analysis columns
    if all_args.mapformats
        _f = [getformat(ds, col) for col in cols]
    else
        _f = repeat([identity], length(cols))
    end

    # we need to refer to the names in violin_ds not ds - so index are not useful
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
    violin_ds = combine(gatherby(ds, g_col, mapformats=all_args.mapformats, threads=threads), cols .=> [x -> fit_density(x, :kernel, opts[:weights], opts[:bw], __f, opts[:npoints], opts[:scale]) for __f in _f] .=> ["$(sg_col_prefix)density_info__$col" for col in cols], threads = threads)
    modify!(violin_ds, ["$(sg_col_prefix)density_info__$col" for col in cols] .=> splitter .=> [["$(sg_col_prefix)midpoint__density__$col", "$(sg_col_prefix)height__density__$col"] for col in cols])

    select!(violin_ds, Not(["$(sg_col_prefix)density_info__$col" for col in cols]))
    # transpose data to put all analysis columns in a single group - the name for the new group column will be "__violin__groups__variable__"
    violin_ds = transpose(gatherby(violin_ds, g_col, mapformats=all_args.mapformats, threads=false, eachrow=true), (["$(sg_col_prefix)midpoint__density__$col" for col in cols], ["$(sg_col_prefix)height__density__$col" for col in cols]), variable_name = ["__violin__groups__variable__", nothing], renamerowid = x -> replace(x, "$(sg_col_prefix)midpoint__density__"=>""), renamecolid = (x,y)->contains(y[1], "$(sg_col_prefix)midpoint__density__") ? "$(sg_col_prefix)midpoint__density__" : "$(sg_col_prefix)height__density__", threads = false)
   
   
    if opts[:category] === nothing
        insertcols!(violin_ds, :__violin__fake__group__col__ => "variable(s)")
    end
    if opts[:category] !== nothing
        if opts[:categoryorder] == :ascending 
            sort!(violin_ds, opts[:category], mapformats = all_args.mapformats, threads = false)
        elseif opts[:categoryorder] == :descending 
            sort!(violin_ds, opts[:category], rev=true, mapformats = all_args.mapformats, threads = false)
        end
    end
    return cols, violin_ds, IMD.maximum(violin_ds[!, "$(sg_col_prefix)height__density__" ])
    @label argerr
    throw(ArgumentError("only a single column must be selected"))
end

function _add_legends!(plt::Violin, all_args, idx)
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