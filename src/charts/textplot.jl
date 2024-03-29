"""
    TextPlot(args...)

Represent a Text plot with given arguments.

$(print_doc(TEXT_DEFAULT))
"""
mutable struct TextPlot <: SGMarks # we have to use TextPlot instead of Text, since Julia has a Text type already (although it is deprecated)
    opts
    function TextPlot(; opts...)
        optsd = val_opts(opts)
        cp_TEXT_DEFAULT = update_default_opts!(deepcopy(TEXT_DEFAULT), optsd)
        if cp_TEXT_DEFAULT[:text] == 0 || cp_TEXT_DEFAULT[:x] == 0 || cp_TEXT_DEFAULT[:y] == 0
            throw(ArgumentError("TextPlot needs text, x and y keyword arguments"))
        end
        if cp_TEXT_DEFAULT[:colorresponse] !== nothing && cp_TEXT_DEFAULT[:group] !== nothing
            throw(ArgumentError("only one of colorresponse or group should be passed"))
        end
        new(cp_TEXT_DEFAULT)
    end
end

# TextPlot puts a text in a plot
# It requires text, x and y keyword arguments
# It needs the input data set to be passed dirctly to vega
function _push_plots!(vspec, plt::TextPlot, all_args; idx=1)
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
    s_spec_marks[:type] = "text"
    s_spec_marks[:from] = Dict(:data => "source_0_$idx")
    s_spec_marks[:encode] = Dict{Symbol,Any}()
    s_spec_marks[:encode][:enter] = Dict{Symbol,Any}()
    if opts[:opacityresponse] === nothing
        s_spec_marks[:encode][:enter][:opacity] = Dict(:value => opts[:opacity])
    else
        s_spec_marks[:encode][:enter][:opacity] = Dict(:field => opts[:opacityresponse], :scale => "opacity_scale_$idx")
        addto_identity_scale!(vspec, "source_0", "opacity_scale_$idx", opts[:opacityresponse])
    end


    s_spec_marks[:encode][:enter][:fontSize] = Dict(:value => opts[:size])

    if opts[:angleresponse] === nothing
        s_spec_marks[:encode][:enter][:angle] = Dict(:value => opts[:angle])
    else
        s_spec_marks[:encode][:enter][:angle] = Dict(:field => opts[:angleresponse], :scale => "angle_scale_$idx")
        addto_identity_scale!(vspec, "source_0", "angle_scale_$idx", opts[:angleresponse])
    end

    s_spec_marks[:encode][:enter][:fill] = Dict{Symbol,Any}()
    if opts[:colorresponse] === nothing
        s_spec_marks[:encode][:enter][:fill][:value] = opts[:color]
    else
        s_spec_marks[:encode][:enter][:fill][:scale] = "color_scale_$idx"
        s_spec_marks[:encode][:enter][:fill][:field] = opts[:colorresponse]
        addto_color_scale!(vspec, "source_0", "color_scale_$idx", opts[:colorresponse], opts[:colorresponse] in all_args.nominal, color_model=opts[:colormodel])
    end

    # we already checked that user cannot pass both colorresponse and group
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

    s_spec_marks[:encode][:enter][:text] = Dict{Symbol,Any}(:field => opts[:text])

    s_spec_marks[:encode][:enter][:font] = Dict{Symbol,Any}(:value => something(opts[:font], all_args.opts[:font]))
    s_spec_marks[:encode][:enter][:fontStyle] = Dict{Symbol,Any}(:value => something(opts[:italic], all_args.opts[:italic]) ? "italic" : "normal")
    s_spec_marks[:encode][:enter][:fontWeight] = Dict{Symbol,Any}(:value => something(opts[:fontweight], all_args.opts[:fontweight]))
    s_spec_marks[:encode][:enter][:dir] = Dict{Symbol,Any}(:value => opts[:dir])
    s_spec_marks[:encode][:enter][:baseline] = Dict{Symbol,Any}(:value => opts[:textbaseline])
    s_spec_marks[:encode][:enter][:align] = Dict{Symbol,Any}(:value => opts[:align])
    if opts[:limit] !== nothing
        s_spec_marks[:encode][:enter][:limit] = Dict{Symbol,Any}(:value => opts[:limit])
    end

    s_spec[:marks] = [s_spec_marks]
    push!(vspec[:marks], s_spec)
end


# converts all column names to string, also check if the required arguments are passed
# TODO use macro to generate repeated code
function _check_and_normalize!(plt::TextPlot, all_args)
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
    if length(IMD.index(ds)[opts[:text]]) == 1
        append!(cols, IMD.index(ds)[opts[:text]])
        opts[:text] = _colname_as_string(ds, opts[:text])
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
    if opts[:opacityresponse] !== nothing
        if length(IMD.index(ds)[opts[:opacityresponse]]) == 1
            append!(cols, IMD.index(ds)[opts[:opacityresponse]])
            opts[:opacityresponse] = _colname_as_string(ds, opts[:opacityresponse])
        else
            @goto argerr
        end
    end
    # if opts[:alignresponse] !== nothing
    #     if length(IMD.index(ds)[opts[:alignresponse]]) == 1
    #         append!(cols, IMD.index(ds)[opts[:alignresponse]])
    #         opts[:alignresponse] = _colname_as_string(ds, opts[:alignresponse])
    #     else
    #         @goto argerr
    #     end
    # end
    return plt
    @label argerr
    throw(ArgumentError("only a single column must be selected"))
end

function _add_legends!(plt::TextPlot, all_args, idx)
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

    # currently, group and symbol can be mixed
    leg_spec_cp = Dict{Symbol,Any}()
    if which_scale[1] !== nothing
        leg_spec_cp[:fill] = "group_scale"
        _build_legen!(leg_spec_cp, leg_spec.opts, "circle", which_scale[1], "$(legend_id)_group_scale_legend_$idx", all_args)
        push!(all_args.out_legends, leg_spec_cp)
    end
    leg_spec_cp = Dict{Symbol,Any}()
    if which_scale[2] !== nothing
        leg_spec_cp[:fill] = "color_scale_$idx"
        _build_legen!(leg_spec_cp, leg_spec.opts, nothing, which_scale[2], "$(legend_id)_color_scale_legend_$idx", all_args)
        push!(all_args.out_legends, leg_spec_cp)
    end
end   
    
