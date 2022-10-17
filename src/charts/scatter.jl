SCATTER_DEFAULT = Dict{Symbol, Any}(:x => 0, :y => 0,
                                    :group=>nothing,
                                    :x2axis=>false,
                                    :y2axis=>false,
                                    :opacity=>1,
                                    :thickness=>1, # symbol outline thickness
                                    :filled=>true,
                                    :fill=>"null",
                                    :fillcolor=> :white,
                                    :size=>50,
                                    :symbol=>"circle",
                                    :symbolresponse=>nothing,
                                    :angle=>0,
                                    :angleresponse=>nothing,
                                    :color=>"#4682b4",
                                    :colorresponse => nothing,
                                    :colormodel=>["#2f6790", "#bed8ec"],
                                    :legend => nothing , #user must give a name to this if further customisation is needed for the legend
                                    :jitter=>[0,0] # jitter strength, the first one is the horizontal strength and the second number is the vertical strength
                                    )
mutable struct Scatter <: SGMarks
    opts
    function Scatter(;opts...)
        optsd = val_opts(opts)
        cp_SCATTER_DEFAULT = update_default_opts!(deepcopy(SCATTER_DEFAULT), optsd)
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
function _push_plots!(vspec, plt::Scatter, all_args; idx = 1)
    # check if the required arguments are passed
    _check_and_normalize!(plt, all_args)
    _add_legends!(plt, all_args, idx)
    opts = plt.opts
    # we should filter out invalid data
    filter_data = Dict{Symbol, Any}()
    filter_data[:name] = "source_0_$idx"
    filter_data[:source] = "source_0"
    filter_data[:transform] = [Dict{Symbol, Any}(:type=>:filter, :expr=>"isValid(datum['$(opts[:x])']) && isValid(datum['$(opts[:y])'])")]
    push!(vspec[:data], filter_data)

    s_spec = Dict{Symbol,Any}()
    s_spec[:type] = "group"
    s_spec_marks = Dict{Symbol,Any}()
    s_spec_marks[:type] = "symbol"
    s_spec_marks[:style] = ["point"]
    s_spec_marks[:from] = Dict(:data => "source_0_$idx")
    s_spec_marks[:encode] = Dict{Symbol,Any}()
    s_spec_marks[:encode][:enter] = Dict{Symbol,Any}()
    s_spec_marks[:encode][:enter][:opacity] = Dict(:value => opts[:opacity])
    s_spec_marks[:encode][:enter][:strokeWidth] = Dict(:value => opts[:thickness])
    s_spec_marks[:encode][:enter][:size] = Dict(:value => opts[:size])
    s_spec_marks[:encode][:enter][:angle] = Dict(:value => opts[:angle])
    s_spec_marks[:encode][:enter][:fill] = Dict{Symbol,Any}()
    if opts[:colorresponse] === nothing
        s_spec_marks[:encode][:enter][:fill][:value] = ifelse(opts[:filled], opts[:fillcolor], "transparent")
    else
        s_spec_marks[:encode][:enter][:fill][:scale] = "color_scale_$idx"
        s_spec_marks[:encode][:enter][:fill][:field] = opts[:colorresponse]
        addto_color_scale!(vspec, "source_0", "color_scale_$idx", opts[:colorresponse], opts[:colorresponse] in all_args.nominal)
    end
    s_spec_marks[:encode][:enter][:shape] = Dict{Symbol, Any}()

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
        s_spec_marks[:encode][:enter][:stroke][:value] = opts[:color]
    else
        s_spec[:from] = Dict{Symbol,Any}()
        s_spec[:from][:facet] = Dict{Symbol,Any}()
        s_spec[:from][:facet][:name] = "group_facet_source"
        s_spec[:from][:facet][:data] = "source_0_$idx"
        s_spec[:from][:facet][:groupby] = opts[:group]
        s_spec_marks[:from][:data] = "group_facet_source"
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
        s_spec_marks[:encode][:enter][:x][:offset] = Dict{Symbol, Any}(:signal=>_addjitter(opts[:jitter][1]))
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
    if opts[:jitter][2] > 0
        s_spec_marks[:encode][:enter][:y][:offset] = Dict{Symbol, Any}(:signal=>_addjitter(opts[:jitter][2]))
    end
    s_spec[:marks] = [s_spec_marks]
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
    if opts[:colorresponse] !== nothing
        if length(IMD.index(ds)[opts[:colorresponse]]) == 1
            append!(cols, IMD.index(ds)[opts[:colorresponse]])
            opts[:colorresponse] = _colname_as_string(ds, opts[:colorresponse])
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
        _build_legen!(leg_spec_cp, leg_spec.opts, "circle", which_scale[1], "$(legend_id)_group_color_scale_legend_$idx")
        push!(all_args.out_legends, leg_spec_cp)
    elseif (which_scale[1] != which_scale[3]) && (which_scale[1] !== nothing) && (which_scale[3] === nothing)
        leg_spec_cp[:stroke] = "group_scale" 
        _build_legen!(leg_spec_cp, leg_spec.opts, "circle", which_scale[1], "$(legend_id)_group_scale_legend_$idx")
        push!(all_args.out_legends, leg_spec_cp)
    elseif (which_scale[1] != which_scale[3]) && (which_scale[3] !== nothing) && (which_scale[1] === nothing)
        leg_spec_cp[:shape] = "symbol_scale_$idx"
        leg_spec_cp[:symbolStrokeColor] = plt.opts[:color]
        _build_legen!(leg_spec_cp, leg_spec.opts, nothing, which_scale[3], "$(legend_id)_symbol_scale_legend_$idx")
        push!(all_args.out_legends, leg_spec_cp)
    elseif (which_scale[1] != which_scale[3]) && (which_scale[3] !== nothing) && (which_scale[1] !== nothing)
        leg_spec_cp[:stroke] = "group_scale"
        _build_legen!(leg_spec_cp, leg_spec.opts, "circle", which_scale[1], "$(legend_id)_group_scale_legend_$idx")
        push!(all_args.out_legends, leg_spec_cp)
        leg_spec_cp = Dict{Symbol, Any}()  
        leg_spec_cp[:shape] = "symbol_scale_$idx"
        _build_legen!(leg_spec_cp, leg_spec.opts, nothing, which_scale[1], "$(legend_id)_symbol_scale_legend_$idx")
        push!(all_args.out_legends, leg_spec_cp)
    end
    leg_spec_cp = Dict{Symbol, Any}()     
    if which_scale[2] !== nothing
        leg_spec_cp[:fill] = "color_scale_$idx"
        _build_legen!(leg_spec_cp, leg_spec.opts, nothing, which_scale[1], "$(legend_id)_color_scale_legend_$idx")
        push!(all_args.out_legends, leg_spec_cp)
    end
end   
    
