LINE_DEFAULT = Dict{Symbol, Any}(:x => 0, :y=>0, :group=>nothing,
                                    :x2axis=>false,
                                    :y2axis=>false,
                                    :opacity=>1,
                                    :thickness=>1,
                                    :dash => [0],
                                    :filled=>true,
                                    :fill=>"null",
                                    :fillcolor=> :white,                  
                                    :color=>"#4682b4",
                                    :interpolate => :linear,
                                    :breaks=>false, # false means remove missing values - true means create a break
                                    :legend=>nothing
                                    )
mutable struct Line <: SGMarks
    opts
    function Line(;opts...)
        optsd = val_opts(opts)
        cp_LINE_DEFAULT = update_default_opts!(deepcopy(LINE_DEFAULT), optsd)
        if cp_LINE_DEFAULT[:x] == 0 || cp_LINE_DEFAULT[:y] == 0
            throw(ArgumentError("Line plot needs both x and y keyword arguments"))
        end
        new(cp_LINE_DEFAULT)
    end
end

# Line graphic produce a simple 2D Line plot
# It requires two keyword arguments; x and y 
# It needs the input data set to be passed dirctly to vega
function _push_plots!(vspec, plt::Line, all_args; idx=1)
    # check if the required arguments are passed
    _check_and_normalize!(plt, all_args)
    _add_legends!(plt, all_args, idx)
    opts = plt.opts

    s_spec = Dict{Symbol,Any}()
    s_spec[:type] = "group"
    s_spec_marks = Dict{Symbol,Any}()
    s_spec_marks[:type] = "line"
    s_spec_marks[:from] = Dict(:data => "source_0_$idx")
    s_spec_marks[:encode] = Dict{Symbol,Any}()
    s_spec_marks[:encode][:enter] = Dict{Symbol,Any}()
    s_spec_marks[:encode][:enter][:interpolate] = Dict{Symbol,Any}(:value => opts[:interpolate])
    s_spec_marks[:encode][:enter][:opacity] = Dict(:value => opts[:opacity])
    s_spec_marks[:encode][:enter][:strokeWidth] = Dict(:value => opts[:thickness])
    s_spec_marks[:encode][:enter][:strokeDash] = Dict(:value => opts[:dash])

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


    filter_data = Dict{Symbol,Any}()
    filter_data[:name] = "source_0_$idx"
    filter_data[:source] = "source_0"
    filter_data[:transform] = [Dict{Symbol,Any}(:type => :filter, :expr => "isValid(datum['$(opts[:x])']) && isValid(datum['$(opts[:y])'])")]
    if opts[:breaks]
        s_spec_marks[:encode][:enter][:defined] = Dict{Symbol,Any}(:signal => "isValid(datum['$(opts[:x])']) && isValid(datum['$(opts[:y])'])")
        filter_data[:transform][1][:expr] = "1==1"
    end
    push!(vspec[:data], filter_data)
    s_spec[:marks] = [s_spec_marks]
    push!(vspec[:marks], s_spec)
end


# converts all column names to string, also check if the required arguments are passed
# TODO use macro to generate repeated code
function _check_and_normalize!(plt::Line, all_args)
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
    return plt
    @label argerr
    throw(ArgumentError("only a single column must be selected"))
end

function _add_legends!(plt::Line, all_args, idx)
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
        leg_spec_cp[:stroke] = "group_scale"
        _build_legen!(leg_spec_cp, leg_spec.opts, "stroke", _title, "$(legend_id)_group_scale_legend_$idx", all_args; symbolDash=plt.opts[:dash])
        push!(all_args.out_legends, leg_spec_cp)
    end
end   