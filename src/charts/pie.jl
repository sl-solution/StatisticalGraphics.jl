PIE_DEFAULT = Dict{Symbol,Any}(:category => nothing,
    :response => nothing,
    :stat => nothing, #by default, if response is given we use sum, if not we use freq - the function passed as stat must accept two arguments f and x, f is a function and x is a abstract vector. function apply f on each elements of x and return the aggregations
    :group => nothing,
    :groupspace=>0.01, # space between groups

    :sort => false,

    :opacity => 1,
    :outlinethickness => 1,

    :outerradius=>1, # [0,1], proportion of the pie radius compared to the maximum possilbe
    :innerradius=>0, # donut pie [0,1]
    :piecorner=>0,
    :startangle => 0, # can be between[0,1], or :nest to display each group nested in the other one
    :endangle=>360,
    :opacity => 1,
    :space => 0,

    :missingmode => 0, # how to handle missings in category or group.  0 = nothing, 1 = no missing in category, 2 = no missing in group, 3 = no missing in category or group, 4 = no missing in both category and group


    :label=>nothing,  # show labels for each piecorner - :category, :percent, :both are valid options
    :decimal=>1, # number of digits after the decimal when percentages are shown
    :labelpos => 0.5, # where to put the labels
    :labelfont=>nothing,
    :labelfontweight=>nothing,
    :labelitalic=>nothing,
    :labelsize=>nothing,
    :labelcolor=>:black,
    :labelangle=>nothing,
    :labeldir=>:ltr,
    :labellimit=>nothing,
    :labelalign=>:center,
    :labelbaseline=>:middle,
    :labelopacity => 1,
    :labelthreshold => 0.0,
    :labelrotate=>false, # rotate labels 90 degree, when is true

   
    :outlinecolor => :white,
    :colormodel=>:category,
    
    :tooltip=>false,

    :legend => nothing,
    :clip => nothing
)
mutable struct Pie <: SGMarks
    opts
    function Pie(; opts...)
        optsd = val_opts(opts)
        cp_PIE_DEFAULT = update_default_opts!(deepcopy(PIE_DEFAULT), optsd)
        if (cp_PIE_DEFAULT[:category] == 0)
            throw(ArgumentError("Pie plot needs the category keyword arguments"))
        end
        if abs(cp_PIE_DEFAULT[:endangle] - cp_PIE_DEFAULT[:startangle])>360
            throw(ArgumentError("the total angle of the Pie chart cannot be more than 360 degree"))
        end
        if !(cp_PIE_DEFAULT[:label] in (nothing, :category, :percent, :both))
            throw(ArgumentError("label can be :category, :percent or :both"))
        end
        new(cp_PIE_DEFAULT)
    end
end

_rad2deg(x) = rad2deg(x)
_rad2deg(::Missing) = missing
_deg2rad(x) = deg2rad(x)
_deg2rad(::Missing) = missing

function _pie_transform(x, startangle, endangle)::Vector{Tuple}
    total_angle = abs(endangle - startangle)
    xprop = x ./ IMD.sum(x)
    xprop .*= total_angle
    _endangles_ = IMD.cumsum(xprop, missings=:ignore)
    _startangles_ = [0.0; _endangles_[1:end-1]]
    _endangles_ .+= startangle
    _startangles_ .+= startangle
    tuple.(_startangles_, _endangles_, x ./ IMD.sum(x), _rad2deg.((_endangles_ .+ _startangles_) ./ 2))
end

# Pie produces a simple Pie Chart
# It requires the category keyword arguments 
# It needs the input data be processed before being sent to  vega
function _push_plots!(vspec, plt::Pie, all_args; idx=1)
    # check if the required arguments are passed / create a new ds and push it to out_ds
    col, new_ds = _check_and_normalize!(plt, all_args)
    delete!(new_ds, ["$(sg_col_prefix)pie__startangle__", "$(sg_col_prefix)pie__endangle__"], type=isequal)
    _add_legends!(plt, all_args, idx)
    data_csv = tempname()
    filewriter(data_csv, new_ds, mapformats=all_args.mapformats, quotechar='"')
    push!(vspec[:data], _prepare_data("pie_data_$idx", data_csv, new_ds, all_args))


    opts = plt.opts

    s_spec = Dict{Symbol,Any}()
    s_spec[:type] = "group"
    s_spec[:clip] = something(opts[:clip], all_args.opts[:clip])
    s_spec_marks = Dict{Symbol,Any}()
    s_spec_marks[:type] = "arc"
    s_spec_marks[:from] = Dict(:data => "pie_data_$idx")
    s_spec_marks[:encode] = Dict{Symbol,Any}()
    s_spec_marks[:encode][:enter] = Dict{Symbol,Any}()
    s_spec_marks[:encode][:enter][:opacity] = Dict{Symbol,Any}(:value => opts[:opacity])
    s_spec_marks[:encode][:enter][:stroke] = Dict{Symbol,Any}(:value => opts[:outlinecolor])
    s_spec_marks[:encode][:enter][:strokeWidth] = Dict{Symbol,Any}(:value => opts[:outlinethickness])
    addto_radius_scale!(vspec, "$idx")
    if opts[:tooltip]
        s_spec_marks[:encode][:enter][:tooltip] = Dict{Symbol,Any}(:field => "$(sg_col_prefix)__pie__val__")
    end

    s_spec_marks[:encode][:enter][:fill] = Dict{Symbol,Any}()


    s_spec_marks[:encode][:enter][:fill][:scale] = "color_scale_$idx"
    s_spec_marks[:encode][:enter][:fill][:field] = col
    addto_color_scale!(vspec, "pie_data_$idx", "color_scale_$idx", col, true; color_model=opts[:colormodel])
    s_spec_marks[:encode][:enter][:startAngle] = Dict{Symbol,Any}(:field => "$(sg_col_prefix)pie__startangle__")
    s_spec_marks[:encode][:enter][:endAngle] = Dict{Symbol,Any}(:field => "$(sg_col_prefix)pie__endangle__")
    s_spec_marks[:encode][:enter][:padAngle] = Dict{Symbol,Any}(:value => opts[:space])

    total_radius = "min(width,height) / 2"

    outer_radius = "$(opts[:outerradius])*$total_radius"
    inner_radius = "$(opts[:innerradius])*$total_radius"


    s_spec_marks[:encode][:enter][:innerRadius] = Dict{Symbol,Any}(:field => "$(sg_col_prefix)_pie__innerradius", :scale=>"fixed_radius_$idx")
    s_spec_marks[:encode][:enter][:outerRadius] = Dict{Symbol,Any}(:field => "$(sg_col_prefix)_pie__outerradius", :scale=>"fixed_radius_$idx")
    s_spec_marks[:encode][:enter][:cornerRadius] = Dict{Symbol,Any}(:value => opts[:piecorner])

    s_spec_marks[:encode][:enter][:x] = Dict{Symbol,Any}(:signal => "width / 2")
    s_spec_marks[:encode][:enter][:y] = Dict{Symbol,Any}(:signal => "height / 2")
    s_spec[:marks] = [s_spec_marks]
    if opts[:label] !== nothing
        s_spec_marks = Dict{Symbol,Any}()
        s_spec_marks[:type] = "text"
        s_spec_marks[:from] = Dict(:data => "pie_data_$idx")
        s_spec_marks[:encode] = Dict{Symbol,Any}()
        s_spec_marks[:encode][:enter] = Dict{Symbol,Any}()
        # s_spec_marks[:encode][:enter][:opacity] = Dict{Symbol,Any}(:value => opts[:opacity])

        s_spec_marks[:encode][:enter][:x] = Dict{Symbol,Any}(:signal => "width / 2")
        s_spec_marks[:encode][:enter][:y] = Dict{Symbol,Any}(:signal => "height / 2")

        w_label_pos = opts[:labelpos]

        s_spec_marks[:encode][:enter][:radius] = Dict{Symbol,Any}(:field => "$(sg_col_prefix)_pie__labelradius", :scale=> "fixed_radius_$idx")
        s_spec_marks[:encode][:enter][:theta] = Dict{Symbol,Any}(:signal => "(datum['$(sg_col_prefix)pie__endangle__'] + datum['$(sg_col_prefix)pie__startangle__'])/2 ")
        if opts[:label] == :category
            t_val = "datum['$(opts[:category])']"
        elseif opts[:label] == :percent
            t_val = "format(datum['$(sg_col_prefix)pie__percentage__'], '0.$(opts[:decimal])%')"
        elseif opts[:label] == :both 
            t_val = "[datum['$(opts[:category])'], format(datum['$(sg_col_prefix)pie__percentage__'], '0.$(opts[:decimal])%')]"
        end
        s_spec_marks[:encode][:enter][:text] = Dict{Symbol,Any}(:signal => t_val)
        if opts[:labelcolor] == :auto
            s_spec_marks[:encode][:enter][:fill] = Dict{Symbol,Any}(:signal => "contrast('black', scale('color_scale_$idx', datum['$col'])) > contrast('white', scale('color_scale_$idx', datum['$col'])) ? 'black' : 'white'")
        else
            s_spec_marks[:encode][:enter][:fill] = Dict{Symbol,Any}(:value => "$(opts[:labelcolor])")
        end
        s_spec_marks[:encode][:enter][:font] = Dict{Symbol,Any}(:value => something(opts[:labelfont], all_args.opts[:font]))
        s_spec_marks[:encode][:enter][:fontWeight] = Dict{Symbol,Any}(:value => something(opts[:labelfontweight], all_args.opts[:fontweight]))
        s_spec_marks[:encode][:enter][:fontStyle] = Dict{Symbol,Any}(:value => something(opts[:labelitalic], all_args.opts[:italic]) ? "italic" : "normal")
        s_spec_marks[:encode][:enter][:baseline] = Dict{Symbol,Any}(:value => "$(opts[:labelbaseline])")
        s_spec_marks[:encode][:enter][:opacity] = Dict{Symbol, Any}(:signal => "isValid(datum['$(sg_col_prefix)__pie__val__']) ? datum['$(sg_col_prefix)pie__percentage__'] < $(opts[:labelthreshold]) ? 0 : $(opts[:labelopacity]) : 0")

        if opts[:labelangle] === nothing
            if opts[:labelrotate]
                _txt_ang_ = "datum['$(sg_col_prefix)pie__textangle__']"
                s_spec_marks[:encode][:enter][:angle] = Dict{Symbol,Any}(:signal => "$(_txt_ang_) > 180 ? $(_txt_ang_) + 90 : $(_txt_ang_) - 90")
            else
                s_spec_marks[:encode][:enter][:angle] = Dict{Symbol,Any}(:signal => "datum['$(sg_col_prefix)pie__textangle__']")
            end
        else
            s_spec_marks[:encode][:enter][:angle] = Dict{Symbol,Any}(:value => opts[:labelangle])
        end
        s_spec_marks[:encode][:enter][:align] = Dict{Symbol,Any}(:value => opts[:labelalign])
        if opts[:labelsize] !== nothing
            s_spec_marks[:encode][:enter][:fontSize] = Dict{Symbol,Any}(:value => opts[:labelsize])
        end
            s_spec_marks[:encode][:enter][:dir] = Dict{Symbol,Any}(:value => opts[:labeldir])
        if opts[:labellimit] !== nothing
            s_spec_marks[:encode][:enter][:limit] = Dict{Symbol,Any}(:value => opts[:labellimit])
        end

        push!(s_spec[:marks], s_spec_marks)
    end
    push!(vspec[:marks], s_spec)
end


# converts all column names to string, also check if the required arguments are passed
# TODO use macro to generate repeated code
function _check_and_normalize!(plt::Pie, all_args)

    opts = plt.opts
    ds = all_args.ds
    threads = all_args.threads
    _extra_col_for_panel = all_args._extra_col_for_panel

    col = ""
    if opts[:category] != 0 && length(IMD.index(ds)[opts[:category]]) == 1
        opts[:category] = _colname_as_string(ds, opts[:category])
        col = opts[:category]
    elseif opts[:category] != 0
        @goto argerr
    end
    
    if opts[:response] !== nothing && length(IMD.index(ds)[opts[:response]]) == 1
        opts[:response] = _colname_as_string(ds, opts[:response])
    elseif opts[:response] !== nothing
        @goto argerr
    end

    if opts[:group] !== nothing && length(IMD.index(ds)[opts[:group]]) == 1
        opts[:group] = _colname_as_string(ds, opts[:group])
    elseif opts[:group] !== nothing
        @goto argerr
    end
    
    if all_args.mapformats
        _f = getformat(ds, col)
    else
        _f = identity
    end

    g_col = copy(_extra_col_for_panel)
  
    # we need to refer to the names in bar_ds not ds - so index are not useful
    _extra_col_for_panel_names_ = names(ds, _extra_col_for_panel)
    unique!(pushfirst!(g_col, IMD.index(ds)[col]))

    if opts[:group] !== nothing
        unique!(pushfirst!(g_col, IMD.index(ds)[opts[:group]]))
        unique!(pushfirst!(_extra_col_for_panel_names_, opts[:group]))
    end

     # we should handle missings here before passing ds for further analysis
    if opts[:missingmode] in (1, 3)
        cp_ds = dropmissing(ds, col, threads = threads, mapformats=all_args.mapformats, view=true)
    elseif opts[:missingmode] in (2, 3) && opts[:group] !== nothing
        cp_ds = dropmissing(ds, opts[:group], threads = threads, mapformats=all_args.mapformats, view=true)
    elseif opts[:missingmode] == 4
        _cols = unique([col, something(opts[:group], col) ])
        cp_ds = dropmissing(ds, _cols, threads = threads, mapformats=all_args.mapformats, view=true)
    else
        cp_ds = ds
    end


    if opts[:response] === nothing
        # TODO we should move this to constructor
        if opts[:stat] === nothing
            opts[:stat] = freq
        end

        pie_ds = combine(gatherby(cp_ds, g_col, mapformats=all_args.mapformats, threads=threads), col => (x -> opts[:stat](_f, x)) => "$(sg_col_prefix)__pie__val__", threads=threads)
    else
        _f_response = identity
        if all_args.mapformats
            _f_response = getformat(cp_ds, opts[:response])
        end
        if opts[:stat] === nothing
            opts[:stat] = IMD.sum
        end
        pie_ds = combine(gatherby(cp_ds, g_col, mapformats=all_args.mapformats, threads=threads), opts[:response] => (x -> opts[:stat](_f_response, x)) => "$(sg_col_prefix)__pie__val__", threads=threads)
     
    end
    if opts[:sort]
        sort!(pie_ds, "$(sg_col_prefix)__pie__val__", threads=false)
    end
    
    modify!(gatherby(pie_ds, _extra_col_for_panel_names_, mapformats=all_args.mapformats, threads=false), "$(sg_col_prefix)__pie__val__" =>byrow(identity)=>"$(sg_col_prefix)__pie__val__", "$(sg_col_prefix)__pie__val__" => (x->_pie_transform(x, _deg2rad(opts[:startangle]), _deg2rad(opts[:endangle])))=> "$(sg_col_prefix)pie__info__", "$(sg_col_prefix)pie__info__"=>splitter=>["$(sg_col_prefix)pie__startangle__","$(sg_col_prefix)pie__endangle__", "$(sg_col_prefix)pie__percentage__", "$(sg_col_prefix)pie__textangle__"])
    select!(pie_ds, Not("$(sg_col_prefix)pie__info__"))

    _w_ = opts[:labelpos]

    if opts[:group] === nothing
        insertcols!(pie_ds, "$(sg_col_prefix)_pie__innerradius" => opts[:innerradius])
        insertcols!(pie_ds, "$(sg_col_prefix)_pie__outerradius" => opts[:outerradius])
        insertcols!(pie_ds, "$(sg_col_prefix)_pie__labelradius" => _w_ * opts[:outerradius] + (1- _w_) * opts[:innerradius])
    else
        group_info_ds = unique(cp_ds[!, [opts[:group]]], threads=threads, mapformats=all_args.mapformats)
        n_groups = nrow(group_info_ds)
        total_radius = opts[:outerradius] - opts[:innerradius] # TODO should we use abs value?
        total_radius -= (n_groups-1) * opts[:groupspace] # subtract the space between groups
        radius_eachgroup = total_radius / n_groups
        inner_radius = [(i-1)*(opts[:groupspace] + radius_eachgroup) + opts[:innerradius] for i in 1:n_groups]
        insertcols!(group_info_ds, "$(sg_col_prefix)_pie__innerradius" => inner_radius)
        insertcols!(group_info_ds, "$(sg_col_prefix)_pie__outerradius" => inner_radius .+ radius_eachgroup)
        insertcols!(group_info_ds, "$(sg_col_prefix)_pie__labelradius" => inner_radius .+ _w_ * radius_eachgroup)
        leftjoin!(pie_ds, group_info_ds, on = opts[:group], mapformats=all_args.mapformats, threads=false, method=:hash)
    end

    return  col, pie_ds
    @label argerr
    throw(ArgumentError("only a single column must be selected"))
end


function _add_legends!(plt::Pie, all_args, idx)
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
        leg_spec_cp[:fill] = "color_scale_$idx"
        _build_legen!(leg_spec_cp, leg_spec.opts, "square", _title, "$(legend_id)_color_scale_legend_$idx", all_args)
        push!(all_args.out_legends, leg_spec_cp)
    end
end   