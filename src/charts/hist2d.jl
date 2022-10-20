
# TODO this is a first draft - should be optimised later
function _hist2d_counts(x::AbstractVector{Union{T,Missing}}, y::AbstractVector{Union{S,Missing}}, k_x, k_y, _f_x, _f_y; default_method)::Vector{Tuple} where {T<:Real} where {S<:Real}
    if k_x === nothing || k_y === nothing
        count_missing = count(val->ismissing(coalesce(val)), zip(x,y))
        count_nonmissing = length(x) - count_missing
        k_x = something(k_x, default_method(count_nonmissing))
        k_y =something(k_y, default_method(count_nonmissing))
    end


    max_val_x = IMD.maximum(_f_x, x)
    min_val_x = IMD.minimum(_f_x, x)

    max_val_y = IMD.maximum(_f_y, y)
    min_val_y = IMD.minimum(_f_y, y)


    any(isequal.(max_val_x, (missing, NaN, Inf, -Inf))) && throw(ArgumentError("x shouldn't be all missing or contains any NaN or infinite value"))
    any(isequal.(min_val_x, (missing, NaN, Inf, -Inf))) && throw(ArgumentError("x shouldn't be all missing or contains any NaN or infinite value"))
    any(isequal.(max_val_y, (missing, NaN, Inf, -Inf))) && throw(ArgumentError("y shouldn't be all missing or contains any NaN or infinite value"))
    any(isequal.(min_val_y, (missing, NaN, Inf, -Inf))) && throw(ArgumentError("y shouldn't be all missing or contains any NaN or infinite value"))
    (isequal(max_val_x, min_val_x) || isequal(max_val_y, min_val_y)) && throw(ArgumentError("at least two different values are needed"))
    # do we need these?
    min_val_act_x = min(min_val_x, max_val_x)
    max_val_act_x = max(min_val_x, max_val_x)
    min_val_act_y = min(min_val_y, max_val_y)
    max_val_act_y = max(min_val_y, max_val_y)

    # we only support length for creating bins
    bins_x = range(min_val_act_x, max_val_act_x, length=k_x)
    bins_y = range(min_val_act_y, max_val_act_y, length=k_y)


    counts = zeros(Int, k_x, k_y)
    for (val_x, val_y) in zip(x, y)
        if !ismissing(val_x) && !ismissing(val_y)
            counts[searchsortedfirst(bins_x, _f_x(val_x)), searchsortedfirst(bins_y, _f_y(val_y))] += 1
        end
    end
    counts[2, :] += counts[1, :]
    counts[:, 2] += counts[:, 1]
    counts[1, :] .= 0
    counts[:, 1] .= 0

    bins_1 = collect(bins_x)

    bins_2 = collect(bins_y)

    binsx_start = bins_1[1:end-1]
    binsx_end = bins_1[2:end]

    binsy_start = bins_2[1:end-1]
    binsy_end = bins_2[2:end]

    lx = length(binsx_start)
    ly = length(binsy_end)


    tuple.(repeat(binsx_start, inner=ly), repeat(binsx_end, inner=ly), repeat(binsy_start, outer=lx), repeat(binsy_end, outer=lx), vec(counts[2:end, 2:end]))
end

HEAT_DEFAULT = Dict{Symbol,Any}(:x => 0, :y => 0,
    :x2axis => false,
    :y2axis => false,
    :opacity => 1,
    :tooltip=>false, #show frequency on mouseover
    # :outlinethickness => 0.1,
    :colormodel => ["#2f6790", "#bed8ec"],
    :xbincount => nothing,
    :ybincount=> nothing,
    :bincountmethod => x -> max(2, Int(ceil(log2(x)) + 1)), # x is the length - later we can change this default function 
    # :outlinecolor => :white,
    :legend => nothing, :clip => nothing
)
mutable struct Heatmap <: SGMarks
    opts
    function Heatmap(; opts...)
        optsd = val_opts(opts)
        cp_HEAT_DEFAULT = update_default_opts!(deepcopy(HEAT_DEFAULT), optsd)
        if (cp_HEAT_DEFAULT[:x] == 0 || cp_HEAT_DEFAULT[:y] == 0)
            throw(ArgumentError("Heatmap plot needs both x and y keyword arguments"))
        end
        new(cp_HEAT_DEFAULT)
    end
end

# Heatmap graphic produce a heatmap plot
# It requires both x or y keyword arguments 
# It needs the input data be processed before being sent to  vega
function _push_plots!(vspec, plt::Heatmap, all_args; idx=1)
    # check if the required arguments are passed / create a new ds and push it to out_ds
    new_ds = _check_and_normalize!(plt, all_args)
    _add_legends!(plt, all_args, idx)
    data_csv = tempname()
    filewriter(data_csv, new_ds, mapformats=all_args.mapformats, quotechar='"')
    push!(vspec[:data], Dict{Symbol,Any}(:name => "heatmap_data_$idx", :values => read(data_csv, String), :format => Dict(:type => "csv", :delimiter => ",", :parse => :auto)))
    opts = plt.opts

    s_spec = Dict{Symbol,Any}()
    s_spec[:type] = "group"
    s_spec[:clip] = something(opts[:clip], all_args.opts[:clip])
    s_spec_marks = Dict{Symbol,Any}()
    s_spec_marks[:type] = "rect"
    s_spec_marks[:from] = Dict(:data => "heatmap_data_$idx")
    s_spec_marks[:encode] = Dict{Symbol,Any}()
    s_spec_marks[:encode][:enter] = Dict{Symbol,Any}()
    s_spec_marks[:encode][:enter][:opacity] = Dict{Symbol, Any}(:value => opts[:opacity])
    if opts[:tooltip]
        s_spec_marks[:encode][:enter][:tooltip] = Dict{Symbol, Any}(:field=>:__bin__counts__)
    end
    # s_spec_marks[:encode][:enter][:stroke] = Dict(:value => opts[:outlinecolor])
    # s_spec_marks[:encode][:enter][:strokeWidth] = Dict(:value => opts[:outlinethickness])
    s_spec_marks[:encode][:enter][:fill] = Dict{Symbol,Any}()

    s_spec_marks[:encode][:enter][:fill][:scale] = "color_scale_$idx"
    s_spec_marks[:encode][:enter][:fill][:field] = :__bin__counts__
    addto_color_scale!(vspec, "heatmap_data_$idx", "color_scale_$idx", :__bin__counts__, false; color_model=opts[:colormodel])

    if opts[:x2axis]
        _scale_x = "x2"
        _which_ax = 2
    else
        _scale_x = "x1"
        _which_ax = 1
    end
    if opts[:y2axis]
        _scale_y = "y2"
        _which_ay = 4
    else
        _scale_y = "y1"
        _which_ay = 3
    end

    s_spec_marks[:encode][:enter][:x] = Dict{Symbol,Any}()
    s_spec_marks[:encode][:enter][:x2] = Dict{Symbol,Any}()
    s_spec_marks[:encode][:enter][:x][:scale] = _scale_x
    s_spec_marks[:encode][:enter][:x2][:scale] = _scale_x

    addto_scale!(all_args, _which_ax, new_ds, "__bin__x__start__")
    addto_scale!(all_args, _which_ax, new_ds, "__bin__x__end__")

    addto_axis!(vspec[:axes][_which_ax], all_args.axes[_which_ax], opts[:x])

    s_spec_marks[:encode][:enter][:y] = Dict{Symbol,Any}()
    s_spec_marks[:encode][:enter][:y2] = Dict{Symbol,Any}()

    s_spec_marks[:encode][:enter][:y][:scale] = _scale_y
    s_spec_marks[:encode][:enter][:y2][:scale] = _scale_y
    addto_scale!(all_args, _which_ay, new_ds, "__bin__y__start__")
    addto_scale!(all_args, _which_ay, new_ds, "__bin__y__end__")
    addto_axis!(vspec[:axes][_which_ay], all_args.axes[_which_ay], opts[:y])


    s_spec_marks[:encode][:enter][:x][:field] = "__bin__x__start__"
    s_spec_marks[:encode][:enter][:x2][:field] = "__bin__x__end__"

    s_spec_marks[:encode][:enter][:y][:field] = "__bin__y__start__"
    s_spec_marks[:encode][:enter][:y2][:field] = "__bin__y__end__"




    s_spec[:marks] = [s_spec_marks]
    push!(vspec[:marks], s_spec)
end


# converts all column names to string, also check if the required arguments are passed
# TODO use macro to generate repeated code
function _check_and_normalize!(plt::Heatmap, all_args)

    opts = plt.opts
    ds = all_args.ds
    threads = all_args.threads
    _extra_col_for_panel = all_args._extra_col_for_panel

    if opts[:x] != 0 && length(IMD.index(ds)[opts[:x]]) == 1
        opts[:x] = _colname_as_string(ds, opts[:x])
    elseif opts[:x] != 0
        @goto argerr
    end
    if opts[:y] != 0 && length(IMD.index(ds)[opts[:y]]) == 1
        opts[:y] = _colname_as_string(ds, opts[:y])
    elseif opts[:y] != 0
        @goto argerr
    end
    if all_args.mapformats
        _f_x = getformat(ds, opts[:x])
        _f_y = getformat(ds, opts[:y])
    else
        _f_x = identity
        _f_y = identity
    end

    g_col = _extra_col_for_panel

    heatmap_ds = combine(gatherby(ds, g_col, threads=threads, mapformats=all_args.mapformats), (opts[:x], opts[:y]) => ((x, y) -> _hist2d_counts(x, y, opts[:xbincount], opts[:ybincount], _f_x, _f_y; default_method = opts[:bincountmethod])) => :__bin__information__, threads=threads)

    modify!(heatmap_ds, :__bin__information__ => splitter => [:__bin__x__start__, :__bin__x__end__, :__bin__y__start__, :__bin__y__end__, :__bin__counts__], threads=threads)
    filter!(heatmap_ds, :__bin__counts__, by=(>(0)))

    return heatmap_ds
    @label argerr
    throw(ArgumentError("only a single column must be selected"))
end

function _add_legends!(plt::Heatmap, all_args, idx)
    opts = plt.opts
    # find the suitable scales for the legend
    # group, color, symbol, angle, ...
    
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
  
    _title = "Frequency"
    leg_spec_cp[:fill] = "color_scale_$idx"
    _build_legen!(leg_spec_cp, leg_spec.opts, nothing, _title, "$(legend_id)_color_scale_legend_$idx", all_args)
    push!(all_args.out_legends, leg_spec_cp)
end   