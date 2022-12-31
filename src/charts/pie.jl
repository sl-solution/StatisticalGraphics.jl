PIE_DEFAULT = Dict{Symbol,Any}(:category => nothing,
    :response => nothing,
    :stat => nothing, #by default, if response is given we use sum, if not we use freq - the function passed as stat must accept two arguments f and x, f is a function and x is a abstract vector. function apply f on each elements of x and return the aggregations
   
    :sort => false,

    :opacity => 1,
    :outlinethickness => 1,

    :innerradius=>0, # donut pie
    :piecorner=>0,
    :startangle => 0, # can be between[0,1], or :nest to display each group nested in the other one
    :endangle=>360,
    :opacity => 1,
    :space => 0,

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

function _pie_transform(x, startangle, endangle)::Vector{Tuple}
    total_angle = abs(endangle - startangle)
    xprop = x ./ IMD.sum(x)
    xprop .*= total_angle
    _endangles_ = IMD.cumsum(xprop, missings=:ignore)
    _startangles_ = [0.0; _endangles_[1:end-1]]
    _endangles_ .+= startangle
    _startangles_ .+= startangle
    tuple.(_startangles_, _endangles_, x ./ IMD.sum(x), rad2deg.((_endangles_ .+ _startangles_) ./ 2))
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
    push!(vspec[:data], Dict{Symbol,Any}(:name => "pie_data_$idx", :values => read(data_csv, String), :format => Dict(:type => "csv", :delimiter => ",", :parse => :auto)))


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
    s_spec_marks[:encode][:enter][:innerRadius] = Dict{Symbol,Any}(:value => opts[:innerradius])
    s_spec_marks[:encode][:enter][:outerRadius] = Dict{Symbol,Any}(:signal => "min(width,height) / 2")
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
        s_spec_marks[:encode][:enter][:opacity] = Dict{Symbol,Any}(:value => opts[:opacity])

        s_spec_marks[:encode][:enter][:x] = Dict{Symbol,Any}(:signal => "width / 2")
        s_spec_marks[:encode][:enter][:y] = Dict{Symbol,Any}(:signal => "height / 2")

        w_label_pos = opts[:labelpos]

        s_spec_marks[:encode][:enter][:radius] = Dict{Symbol,Any}(:signal => "($(w_label_pos)*min(width,height) / 2 + (1-$(w_label_pos))*$(opts[:innerradius]))")
        s_spec_marks[:encode][:enter][:theta] = Dict{Symbol,Any}(:signal => "(datum['$(sg_col_prefix)pie__endangle__'] + datum['$(sg_col_prefix)pie__startangle__'])/2 ")
        if opts[:label] == :category
            t_val = "datum['$(opts[:category])']"
        elseif opts[:label] == :percent
            t_val = "format(datum['$(sg_col_prefix)pie__percentage__'], '0.$(opts[:decimal])%')"
        elseif opts[:label] == :both 
            t_val = "[datum['$(opts[:category])'], format(datum['$(sg_col_prefix)pie__percentage__'], '0.$(opts[:decimal])%')]"
        end
        s_spec_marks[:encode][:enter][:text] = Dict{Symbol,Any}(:signal => t_val)
        s_spec_marks[:encode][:enter][:fill] = Dict{Symbol,Any}(:value => "$(opts[:labelcolor])")
        s_spec_marks[:encode][:enter][:font] = Dict{Symbol,Any}(:value => something(opts[:labelfont], all_args.opts[:font]))
        s_spec_marks[:encode][:enter][:fontWeight] = Dict{Symbol,Any}(:value => something(opts[:labelfontweight], all_args.opts[:fontweight]))
        s_spec_marks[:encode][:enter][:fontStyle] = Dict{Symbol,Any}(:value => something(opts[:labelitalic], all_args.opts[:italic]) ? "italic" : "normal")
        s_spec_marks[:encode][:enter][:baseline] = Dict{Symbol,Any}(:value => "$(opts[:labelbaseline])")

        if opts[:labelangle] === nothing
            s_spec_marks[:encode][:enter][:angle] = Dict{Symbol,Any}(:field => "$(sg_col_prefix)pie__textangle__")
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
    
    if all_args.mapformats
        _f = getformat(ds, col)
    else
        _f = identity
    end

    g_col = _extra_col_for_panel
  
    # we need to refer to the names in bar_ds not ds - so index are not useful
    _extra_col_for_panel_names_ = names(ds, _extra_col_for_panel)
    unique!(pushfirst!(g_col, IMD.index(ds)[col]))

    if opts[:response] === nothing
        # TODO we should move this to constructor
        if opts[:stat] === nothing
            opts[:stat] = freq
        end

        pie_ds = combine(gatherby(ds, g_col, mapformats=all_args.mapformats, threads=threads), col => (x -> opts[:stat](_f, x)) => "$(sg_col_prefix)__pie__val__", threads=threads)
    else
        _f_response = identity
        if all_args.mapformats
            _f_response = getformat(ds, opts[:response])
        end
        if opts[:stat] === nothing
            opts[:stat] = IMD.sum
        end
        pie_ds = combine(gatherby(ds, g_col, mapformats=all_args.mapformats, threads=threads), opts[:response] => (x -> opts[:stat](_f_response, x)) => "$(sg_col_prefix)__pie__val__", threads=threads)
     
    end
    if opts[:sort]
        sort!(pie_ds, "$(sg_col_prefix)__pie__val__", threads=false)
    end
    modify!(gatherby(pie_ds, _extra_col_for_panel_names_, mapformats=all_args.mapformats, threads=false), "$(sg_col_prefix)__pie__val__" =>byrow(identity)=>"$(sg_col_prefix)__pie__val__", "$(sg_col_prefix)__pie__val__" => (x->_pie_transform(x, deg2rad(opts[:startangle]), deg2rad(opts[:endangle])))=> "$(sg_col_prefix)pie__info__", "$(sg_col_prefix)pie__info__"=>splitter=>["$(sg_col_prefix)pie__startangle__","$(sg_col_prefix)pie__endangle__", "$(sg_col_prefix)pie__percentage__", "$(sg_col_prefix)pie__textangle__"])
    select!(pie_ds, Not("$(sg_col_prefix)pie__info__"))
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