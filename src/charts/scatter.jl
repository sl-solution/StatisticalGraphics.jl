"""
    Scatter(args...)

Represent a Scatter plot with given arguments.

$(print_doc(SCATTER_DEFAULT))
"""
mutable struct Scatter <: SGMarks
    opts
    function Scatter(;opts...)
        optsd = val_opts(opts)
        cp_SCATTER_DEFAULT = update_default_opts!(deepcopy(SCATTER_DEFAULT), optsd)
        cp_SCATTER_DEFAULT[:tooltip] && cp_SCATTER_DEFAULT[:labelresponse] === nothing && throw(ArgumentError("tooltip only works when the labelresponse keyword is set"))
        if !(cp_SCATTER_DEFAULT[:jitter] isa AbstractVector)
            cp_SCATTER_DEFAULT[:jitter] = [cp_SCATTER_DEFAULT[:jitter], cp_SCATTER_DEFAULT[:jitter]]
        else
            length(cp_SCATTER_DEFAULT[:jitter]) != 2 && throw(ArgumentError("jitter must be a vector of two values"))
        end
        !all(>=(0), cp_SCATTER_DEFAULT[:jitter]) && throw(ArgumentError("jitter must be a positive value"))
        if cp_SCATTER_DEFAULT[:x] == 0 || cp_SCATTER_DEFAULT[:y] == 0
            throw(ArgumentError("Scatter plot needs both x and y keyword arguments"))
        end
        new(cp_SCATTER_DEFAULT)
    end
end

# Scatter graphic produce a simple 2D scatter plot
# It requires two keyword arguments; x and y 
# It needs the input data set to be passed dirctly to vega
function _push_plots!(vspec, plt::Scatter, all_args; idx=1)
    # check if the required arguments are passed
    _check_and_normalize!(plt, all_args)
    _add_legends!(plt, all_args, idx)
    opts = plt.opts
    # we should filter out invalid data
    filter_data = Dict{Symbol,Any}()
    filter_data[:name] = "source_0_$idx"
    filter_data[:source] = "source_0"
    filter_data[:transform] = [Dict{Symbol,Any}(:type => :filter, :expr => "isValid(datum['$(opts[:x])']) && isValid(datum['$(opts[:y])'])")]
    push!(vspec[:data], filter_data)

    s_spec = Dict{Symbol,Any}()
    s_spec[:type] = "group"
    s_spec[:clip] = something(opts[:clip], all_args.opts[:clip])
    s_spec_marks = Dict{Symbol,Any}()
    s_spec_marks[:type] = "symbol"
    s_spec_marks[:style] = ["point"]
    s_spec_marks[:name] = "points"
    s_spec_marks[:from] = Dict(:data => "source_0_$idx")
    s_spec_marks[:encode] = Dict{Symbol,Any}()
    s_spec_marks[:encode][:enter] = Dict{Symbol,Any}()
    if opts[:tooltip]
        s_spec_marks[:encode][:enter][:tooltip] = Dict{Symbol,Any}(:field => opts[:labelresponse])
    end
    if opts[:opacityresponse] === nothing
        s_spec_marks[:encode][:enter][:opacity] = Dict(:value => opts[:opacity])
    else
        s_spec_marks[:encode][:enter][:opacity] = Dict(:field => opts[:opacityresponse], :scale => "opacity_scale_$idx")
        addto_identity_scale!(vspec, "source_0", "opacity_scale_$idx", opts[:opacityresponse])
    end
    s_spec_marks[:encode][:enter][:strokeWidth] = Dict(:value => opts[:thickness])
    s_spec_marks[:encode][:enter][:size] = Dict(:value => opts[:size])
    if opts[:angleresponse] === nothing
        s_spec_marks[:encode][:enter][:angle] = Dict(:value => opts[:angle])
    else
        s_spec_marks[:encode][:enter][:angle] = Dict(:field => opts[:angleresponse], :scale => "angle_scale_$idx")
        addto_identity_scale!(vspec, "source_0", "angle_scale_$idx", opts[:angleresponse])
    end
    s_spec_marks[:encode][:enter][:fill] = Dict{Symbol,Any}()
    if opts[:colorresponse] === nothing
        s_spec_marks[:encode][:enter][:fill][:value] = something(opts[:color], :white)
    else
        s_spec_marks[:encode][:enter][:fill][:scale] = "color_scale_$idx"
        s_spec_marks[:encode][:enter][:fill][:field] = opts[:colorresponse]
        addto_color_scale!(vspec, "source_0", "color_scale_$idx", opts[:colorresponse], opts[:colorresponse] in all_args.nominal, color_model=opts[:colormodel])
    end
    s_spec_marks[:encode][:enter][:shape] = Dict{Symbol,Any}()

    if opts[:symbolresponse] === nothing
        s_spec_marks[:encode][:enter][:shape][:value] = opts[:symbol]
    else
        s_spec_marks[:encode][:enter][:shape][:scale] = "symbol_scale_$idx"
        s_spec_marks[:encode][:enter][:shape][:field] = opts[:symbolresponse]
        addto_symbol_scale!(vspec, "source_0", "symbol_scale_$idx", opts[:symbolresponse])
    end
    s_spec_marks[:encode][:enter][:stroke] = Dict{Symbol,Any}()
    # group in all plots uses the same scale
    if opts[:group] === nothing
        s_spec_marks[:encode][:enter][:stroke][:value] = something(opts[:outlinecolor], :steelblue)
    else
        s_spec_marks[:encode][:enter][:stroke][:scale] = "group_scale"
        s_spec_marks[:encode][:enter][:stroke][:field] = opts[:group]
        # group is the 5th element of scales
        addto_group_scale!(vspec[:scales][5], "source_0_$idx", opts[:group], all_args)
    end
    s_spec_marks[:encode][:enter][:x] = Dict{Symbol,Any}()
    if opts[:x2axis]
        s_spec_marks[:encode][:enter][:x][:scale] = "x2"
        addto_scale!(all_args, 2, all_args.ds, opts[:x])
        addto_axis!(vspec[:axes][2], all_args.axes[2], opts[:x])
    else
        s_spec_marks[:encode][:enter][:x][:scale] = "x1"
        addto_scale!(all_args, 1, all_args.ds, opts[:x])
        addto_axis!(vspec[:axes][1], all_args.axes[1], opts[:x])
    end
    s_spec_marks[:encode][:enter][:x][:field] = opts[:x]
    if opts[:jitter][1] > 0
        s_spec_marks[:encode][:enter][:x][:offset] = Dict{Symbol,Any}(:signal => _addjitter(opts[:jitter][1]))
    end
    s_spec_marks[:encode][:enter][:y] = Dict{Symbol,Any}()
    if opts[:y2axis]
        s_spec_marks[:encode][:enter][:y][:scale] = "y2"
        addto_scale!(all_args, 4, all_args.ds, opts[:y])
        addto_axis!(vspec[:axes][4], all_args.axes[4], opts[:y])
    else
        s_spec_marks[:encode][:enter][:y][:scale] = "y1"
        addto_scale!(all_args, 3, all_args.ds, opts[:y])
        addto_axis!(vspec[:axes][3], all_args.axes[3], opts[:y])
    end
    s_spec_marks[:encode][:enter][:y][:field] = opts[:y]

    # shifting if it is supplied
    if opts[:xshift] > 0
        s_spec_marks[:encode][:enter][:x][:band] = opts[:xshift]
    end
    if opts[:yshift] > 0
        s_spec_marks[:encode][:enter][:y][:band] = opts[:yshift]
    end

    if opts[:jitter][2] > 0
        s_spec_marks[:encode][:enter][:y][:offset] = Dict{Symbol,Any}(:signal => _addjitter(opts[:jitter][2]))
    end
    s_spec[:marks] = [s_spec_marks]
    if opts[:labelresponse] !== nothing
        labels_mark = _label_for_points("points", opts, all_args; idx=idx)
        push!(s_spec[:marks], labels_mark)
    end
    push!(vspec[:marks], s_spec)
end


# converts all column names to string, also check if the required arguments are passed
# TODO use macro to generate repeated code
function _check_and_normalize!(plt::Scatter, all_args)
    opts = plt.opts
    ds = all_args.ds
    cols = all_args.referred_cols
    if length(IMD.index(ds)[opts[:x]]) == 1
        append!(cols, IMD.index(ds)[opts[:x]])
        opts[:x] = _colname_as_string(ds, opts[:x])
    else
        @goto argerr
    end
    if length(IMD.index(ds)[opts[:y]]) == 1
        append!(cols, IMD.index(ds)[opts[:y]])
        opts[:y] = _colname_as_string(ds, opts[:y])
    else
        @goto argerr
    end
    if opts[:group] !== nothing
        if length(IMD.index(ds)[opts[:group]]) == 1
            append!(cols, IMD.index(ds)[opts[:group]])
            opts[:group] = _colname_as_string(ds, opts[:group])
        else
            @goto argerr
        end
    end
    if opts[:symbolresponse] !== nothing
        if length(IMD.index(ds)[opts[:symbolresponse]]) == 1
            append!(cols, IMD.index(ds)[opts[:symbolresponse]])
            opts[:symbolresponse] = _colname_as_string(ds, opts[:symbolresponse])
        else
            @goto argerr 
        end
    end
    if opts[:angleresponse] !== nothing
        if length(IMD.index(ds)[opts[:angleresponse]]) == 1
            append!(cols, IMD.index(ds)[opts[:angleresponse]])
            opts[:angleresponse] = _colname_as_string(ds, opts[:angleresponse])
        else
            @goto argerr 
        end
    end
    if opts[:opacityresponse] !== nothing
        if length(IMD.index(ds)[opts[:opacityresponse]]) == 1
            append!(cols, IMD.index(ds)[opts[:opacityresponse]])
            opts[:opacityresponse] = _colname_as_string(ds, opts[:opacityresponse])
        else
            @goto argerr 
        end
    end
    if opts[:colorresponse] !== nothing
        if length(IMD.index(ds)[opts[:colorresponse]]) == 1
            append!(cols, IMD.index(ds)[opts[:colorresponse]])
            opts[:colorresponse] = _colname_as_string(ds, opts[:colorresponse])
        else
            @goto argerr
        end
    end
    if opts[:labelresponse] !== nothing
        if length(IMD.index(ds)[opts[:labelresponse]]) == 1
            append!(cols, IMD.index(ds)[opts[:labelresponse]])
            opts[:labelresponse] = _colname_as_string(ds, opts[:labelresponse])
        else
            @goto argerr
        end
    end
    return plt
    @label argerr
        throw(ArgumentError("only a single column must be selected"))
end

function _add_legends!(plt::Scatter, all_args, idx)
    opts = plt.opts
    # find the suitable scales for the legend
    # group, color, symbol, angle, ...
   which_scale = [opts[:group], opts[:colorresponse], opts[:symbolresponse], opts[:angleresponse]]

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
    leg_spec_cp = Dict{Symbol, Any}() 
    if which_scale[1] == which_scale[3] !== nothing
        leg_spec_cp[:stroke] = "group_scale"
        leg_spec_cp[:shape] = "symbol_scale_$idx"
        _build_legen!(leg_spec_cp, leg_spec.opts, "circle", which_scale[1], "$(legend_id)_group_color_scale_legend_$idx", all_args)
        push!(all_args.out_legends, leg_spec_cp)
    elseif (which_scale[1] != which_scale[3]) && (which_scale[1] !== nothing) && (which_scale[3] === nothing)
        leg_spec_cp[:stroke] = "group_scale" 
        _build_legen!(leg_spec_cp, leg_spec.opts, "circle", which_scale[1], "$(legend_id)_group_scale_legend_$idx", all_args)
        push!(all_args.out_legends, leg_spec_cp)
    elseif (which_scale[1] != which_scale[3]) && (which_scale[3] !== nothing) && (which_scale[1] === nothing)
        leg_spec_cp[:shape] = "symbol_scale_$idx"
        leg_spec_cp[:symbolStrokeColor] = plt.opts[:color]
        _build_legen!(leg_spec_cp, leg_spec.opts, nothing, which_scale[3], "$(legend_id)_symbol_scale_legend_$idx", all_args)
        push!(all_args.out_legends, leg_spec_cp)
    elseif (which_scale[1] != which_scale[3]) && (which_scale[3] !== nothing) && (which_scale[1] !== nothing)
        leg_spec_cp[:stroke] = "group_scale"
        _build_legen!(leg_spec_cp, leg_spec.opts, "circle", which_scale[1], "$(legend_id)_group_scale_legend_$idx", all_args)
        push!(all_args.out_legends, leg_spec_cp)
        leg_spec_cp = Dict{Symbol, Any}()  
        leg_spec_cp[:shape] = "symbol_scale_$idx"
        _build_legen!(leg_spec_cp, leg_spec.opts, nothing, which_scale[1], "$(legend_id)_symbol_scale_legend_$idx", all_args)
        push!(all_args.out_legends, leg_spec_cp)
    end
    leg_spec_cp = Dict{Symbol, Any}()     
    if which_scale[2] !== nothing
        leg_spec_cp[:fill] = "color_scale_$idx"
        _build_legen!(leg_spec_cp, leg_spec.opts, nothing, which_scale[2], "$(legend_id)_color_scale_legend_$idx", all_args)
        push!(all_args.out_legends, leg_spec_cp)
    end
end   
    
function _label_for_points(source, opts, all_args; idx=1)
    s_mark = Dict{Symbol,Any}()
    s_mark[:type] = "text"
    s_mark[:name] = "DONOTCHANGE_label_for_$source"
    s_mark[:from] = Dict{Symbol,Any}(:data => source)
    s_mark[:encode] = Dict{Symbol,Any}()
    s_mark[:encode][:enter] = Dict{Symbol,Any}()
    if opts[:labelcolor] in (:group, :colorresponse)
        if opts[:labelcolor] == :group && opts[:group] !== nothing
            s_mark[:encode][:enter][:fill] = Dict{Symbol,Any}(:field => "datum['$(opts[:group])']", :scale => "group_scale")
        elseif opts[:colorresponse] !== nothing
            s_mark[:encode][:enter][:fill] = Dict{Symbol,Any}(:field => "datum['$(opts[:colorresponse])']", :scale => "color_scale_$idx")
        end
    else
        s_mark[:encode][:enter][:fill] = Dict{Symbol,Any}(:value => opts[:labelcolor])
    end
    s_mark[:encode][:enter][:text] = Dict{Symbol,Any}(:field => "datum['$(opts[:labelresponse])']")
    s_mark[:encode][:enter][:font] = Dict{Symbol,Any}(:value => something(opts[:labelfont], all_args.opts[:font]))
    s_mark[:encode][:enter][:fontWeight] = Dict{Symbol,Any}(:value => something(opts[:labelfontweight], all_args.opts[:fontweight]))
    s_mark[:encode][:enter][:fontStyle] = Dict{Symbol,Any}(:value => something(opts[:labelitalic], all_args.opts[:italic]) ? "italic" : "normal")
    s_mark[:encode][:enter][:angle] = Dict{Symbol,Any}(:value => opts[:labelangle])
    if opts[:labelsize] !== nothing
        s_mark[:encode][:enter][:fontSize] = Dict{Symbol,Any}(:value => opts[:labelsize])
    end
    s_mark[:encode][:enter][:dir] = Dict{Symbol,Any}(:value => opts[:labeldir])
    if opts[:labellimit] !== nothing
        s_mark[:encode][:enter][:limit] = Dict{Symbol,Any}(:value => opts[:labellimit])
    end

    s_mark[:transform] = Dict{Symbol,Any}[]
    s_mark_transform = Dict{Symbol,Any}()
    s_mark_transform[:type] = "label"
    s_mark_transform[:avoidMarks] = [source]
    s_mark_transform[:size] = Dict{Symbol,Any}(:signal => "[width, height]")
    s_mark_transform[:anchor] = opts[:labelanchor]
    s_mark_transform[:method] = opts[:labelalgorithm]
    push!(s_mark[:transform], s_mark_transform)
    s_mark
end






