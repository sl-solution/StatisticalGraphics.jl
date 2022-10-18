BAND_DEFAULT = Dict{Symbol,Any}(:x => 0, :y => 0, :lower => 0, :upper => 0,
    :group => nothing,
    :x2axis => false,
    :y2axis => false,
    :opacity => 0.5,
    :color => "#4682b4",
    :colorresponse => nothing,
    :colormodel => ["#2f6790", "#bed8ec"],
    :interpolate => :linear,
    :breaks => false, # see Line
    :legend => nothing,
    :clip=>nothing
)
mutable struct Band <: SGMarks
    opts
    function Band(;opts...)
        optsd = val_opts(opts)
        cp_BAND_DEFAULT = update_default_opts!(deepcopy(BAND_DEFAULT), optsd)
        if (cp_BAND_DEFAULT[:x] == 0 && cp_BAND_DEFAULT[:y] == 0) || ((cp_BAND_DEFAULT[:lower] isa Integer && cp_BAND_DEFAULT[:lower] == 0) || (cp_BAND_DEFAULT[:upper] isa Integer && cp_BAND_DEFAULT[:upper] == 0)) || (cp_BAND_DEFAULT[:lower] isa Float64 && cp_BAND_DEFAULT[:upper] isa Float64)
            throw(ArgumentError("Band plot needs one of x and y keyword arguments and both lower and upper keyword arguments"))
        end
        new(cp_BAND_DEFAULT)
    end
end

# Band graphic produce a simple 2D Band plot
# It requires three keyword arguments; one of x and y + lower and upper 
# It needs the input data set to be passed dirctly to vega
function _push_plots!(vspec,plt::Band, all_args; idx=1)
    # check if the required arguments are passed
    _check_and_normalize!(plt, all_args)
    _add_legends!(plt, all_args, idx)
    opts = plt.opts

    s_spec = Dict{Symbol,Any}()
    s_spec[:type] = "group"
    s_spec[:clip] = something(opts[:clip], all_args.opts[:clip])
    s_spec_marks = Dict{Symbol,Any}()
    s_spec_marks[:type] = "area"
    s_spec_marks[:from] = Dict(:data => "source_0_$idx")
    s_spec_marks[:encode] = Dict{Symbol,Any}()
    s_spec_marks[:encode][:enter] = Dict{Symbol,Any}()
    s_spec_marks[:encode][:enter][:interpolate] = Dict{Symbol,Any}(:value => opts[:interpolate])
    s_spec_marks[:encode][:enter][:opacity] = Dict(:value => opts[:opacity])
    s_spec_marks[:encode][:enter][:fill] = Dict{Symbol,Any}()

    # group in all plots uses the same scale
    if opts[:group] === nothing
        s_spec_marks[:encode][:enter][:fill][:value] = opts[:color]
    else
        s_spec[:from] = Dict{Symbol,Any}()
        s_spec[:from][:facet] = Dict{Symbol,Any}()
        s_spec[:from][:facet][:name] = "group_facet_source"
        s_spec[:from][:facet][:data] = "source_0_$idx"
        s_spec[:from][:facet][:groupby] = opts[:group]
        s_spec_marks[:from][:data] = "group_facet_source"
        s_spec_marks[:encode][:enter][:fill][:scale] = "group_scale"
        s_spec_marks[:encode][:enter][:fill][:field] = opts[:group]
        # group is the 5th element of scales
        addto_group_scale!(vspec[:scales][5], "source_0_$idx", opts[:group], all_args)
    end
    if opts[:x] != 0
        # vertical
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
        s_spec_marks[:encode][:enter][:y] = Dict{Symbol,Any}()
        s_spec_marks[:encode][:enter][:y2] = Dict{Symbol,Any}()

        l_val = false
        u_val = false
        if opts[:lower] isa Float64
            lower_value = opts[:lower]
            opts[:lower] = opts[:upper]
            l_val = true
        end
        if opts[:upper] isa Float64
            upper_value = opts[:upper]
            opts[:upper] = opts[:lower]
            u_val = true
        end

        if opts[:y2axis]
            s_spec_marks[:encode][:enter][:y][:scale] = "y2"
            addto_scale!(all_args, 4, all_args.ds, opts[:lower])
            addto_axis!(vspec[:axes][4], all_args.axes[4], opts[:lower])
            s_spec_marks[:encode][:enter][:y2][:scale] = "y2"
            addto_scale!(all_args, 4, all_args.ds, opts[:upper])
        else
            s_spec_marks[:encode][:enter][:y][:scale] = "y1"
            addto_scale!(all_args, 3, all_args.ds, opts[:lower])
            addto_axis!(vspec[:axes][3], all_args.axes[3], opts[:lower])
            s_spec_marks[:encode][:enter][:y2][:scale] = "y1"
            addto_scale!(all_args, 3, all_args.ds, opts[:upper])
        end
        l_val ? s_spec_marks[:encode][:enter][:y][:value] = lower_value : s_spec_marks[:encode][:enter][:y][:field] = opts[:lower]
        u_val ? s_spec_marks[:encode][:enter][:y2][:value] = upper_value : s_spec_marks[:encode][:enter][:y2][:field] = opts[:upper]

    else
        # horizontal
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
        s_spec_marks[:encode][:enter][:x] = Dict{Symbol,Any}()
        s_spec_marks[:encode][:enter][:x2] = Dict{Symbol,Any}()
        l_val = false
        u_val = false
        if opts[:lower] isa Float64
            lower_value = opts[:lower]
            opts[:lower] = opts[:upper]
            l_val = true
        end
        if opts[:upper] isa Float64
            upper_value = opts[:upper]
            opts[:upper] = opts[:lower]
            u_val = true
        end

        if opts[:x2axis]
            s_spec_marks[:encode][:enter][:x][:scale] = "x2"
            addto_scale!(all_args, 2, all_args.ds, opts[:lower])
            addto_axis!(vspec[:axes][2], all_args.axes[2], opts[:lower])
            s_spec_marks[:encode][:enter][:x2][:scale] = "x2"
            addto_scale!(all_args, 2, all_args.ds, opts[:upper])
        else
            s_spec_marks[:encode][:enter][:x][:scale] = "x1"
            addto_scale!(all_args, 1, all_args.ds, opts[:lower])
            addto_axis!(vspec[:axes][1], all_args.axes[1], opts[:lower])
            s_spec_marks[:encode][:enter][:x2][:scale] = "x1"
            addto_scale!(all_args, 1, all_args.ds, opts[:upper])
        end
        l_val ? s_spec_marks[:encode][:enter][:x][:value] = lower_value : s_spec_marks[:encode][:enter][:x][:field] = opts[:lower]
        u_val ? s_spec_marks[:encode][:enter][:x2][:value] = upper_value : s_spec_marks[:encode][:enter][:x2][:field] = opts[:upper]
        s_spec_marks[:encode][:enter][:orient] = Dict{Symbol,Any}(:value => "horizontal")
    end
    filter_data = Dict{Symbol,Any}()
    filter_data[:name] = "source_0_$idx"
    filter_data[:source] = "source_0"
    filter_data[:transform] = [Dict{Symbol,Any}(:type => :filter, :expr => "(isValid(datum['$(opts[:x])']) || isValid(datum['$(opts[:y])'])) && isValid(datum['$(opts[:lower])']) && isValid(datum['$(opts[:upper])'])")]
    if opts[:breaks]
        s_spec_marks[:encode][:enter][:defined] = Dict{Symbol,Any}(:signal => "(isValid(datum['$(opts[:x])']) || isValid(datum['$(opts[:y])'])) && isValid(datum['$(opts[:lower])']) && isValid(datum['$(opts[:upper])'])")
        filter_data[:transform][1][:expr] = "1==1"
    end
    push!(vspec[:data], filter_data)
    s_spec[:marks] = [s_spec_marks]
    push!(vspec[:marks], s_spec)
end


# converts all column names to string, also check if the required arguments are passed
# TODO use macro to generate repeated code
function _check_and_normalize!(plt::Band, all_args)
    opts = plt.opts
    ds = all_args.ds
    cols = all_args.referred_cols
    if opts[:x] != 0 && length(IMD.index(ds)[opts[:x]]) == 1
        append!(cols, IMD.index(ds)[opts[:x]])
        opts[:x] = _colname_as_string(ds, opts[:x])
    elseif opts[:x] != 0
        @goto argerr
    end
    if opts[:y] != 0 && length(IMD.index(ds)[opts[:y]]) == 1
        append!(cols, IMD.index(ds)[opts[:y]])
        opts[:y] = _colname_as_string(ds, opts[:y])
    elseif opts[:y] != 0
        @goto argerr
    end
    if !isa(opts[:lower], Float64) && length(IMD.index(ds)[opts[:lower]]) == 1
        append!(cols, IMD.index(ds)[opts[:lower]])
        opts[:lower] = _colname_as_string(ds, opts[:lower])
    elseif !isa(opts[:lower], Float64)
        @goto argerr
    end
    if !isa(opts[:upper], Float64) && length(IMD.index(ds)[opts[:upper]]) == 1
        append!(cols, IMD.index(ds)[opts[:upper]])
        opts[:upper] = _colname_as_string(ds, opts[:upper])
    elseif !isa(opts[:upper], Float64)
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
    return plt
    @label argerr
    throw(ArgumentError("only a single column must be selected"))
end


function _add_legends!(plt::Band, all_args, idx)
    opts = plt.opts
    # find the suitable scales for the legend
    # group, color, symbol, angle, ...
   which_scale = [opts[:group]]

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
    
    leg_spec_cp = Dict{Symbol, Any}()   
    if which_scale[1] !== nothing
        _title = which_scale[1]
        leg_spec_cp[:fill] = "group_scale"
        _build_legen!(leg_spec_cp, leg_spec.opts, "square", _title, "$(legend_id)_group_scale_legend_$idx", all_args)
        push!(all_args.out_legends, leg_spec_cp)
    end
end   