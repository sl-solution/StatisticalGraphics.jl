################ HISTOGRAM preprocess #######################
# TODO what we should do for vectors which contains only one number or a repeat of a single number?
function _histogram_counts(x::AbstractVector{Union{T,Missing}}, k, _f) where {T<:Real}
    max_val = IMD.maximum(_f, x)
    min_val = IMD.minimum(_f, x)
    any(isequal.(max_val, (missing, NaN, Inf, -Inf))) && throw(ArgumentError("x shouldn't be all missing or contains any NaN or infinite value"))
    any(isequal.(min_val, (missing, NaN, Inf, -Inf))) && throw(ArgumentError("x shouldn't be all missing or contains any NaN or infinite value"))
    isequal(max_val, min_val) && throw(ArgumentError("at least two different values are needed"))
    min_val_act = min(min_val, max_val)
    max_val_act = max(min_val, max_val)

    if k isa Integer
        bins = range(min_val_act, max_val_act, length=k)
        counts = zeros(Int, k)
        # if k is a vector, it must contains the beginning of hist intervals
    elseif k isa AbstractVector
        bins = float.(collect(k))
        if bins[firstindex(bins)] > min_val_act
            pushfirst!(bins, min_val_act)
        end
        if bins[lastindex(bins)] < max_val_act
            push!(bins, max_val_act)
        end
        counts = zeros(Int, length(bins))
    else
        throw(ArgumentError("bins must be a number or an abstract vector"))
    end
    
    for val in x
        if !ismissing(val)
            counts[searchsortedfirst(bins, _f(val))] += 1
        end
    end
    # the first bin contain the number of x==min_val and must be added to the second bin
    counts[2] += counts[1]
    counts[1] = 0
    # bins contains the start of the hist intevals - the last one is the end of the last interval
    @assert sum(counts) == IMD.n(x)
    bins, counts
end

function _histogram(x::AbstractVector{Union{T, Missing}}, method::Symbol, _f) where T <: Real
    if method in (:Sturges, :sturges)
        k = max(2, Int(ceil(log2(IMD.n(x)))+1))
    else
        throw(ArgumentError("method $method is unknown"))
    end
    _histogram_counts(x, k, _f)
end
function _histogram(x::AbstractVector{Union{T,Missing}}, k::Union{<:Integer, <:AbstractVector}, _f) where {T<:Real}
    _histogram_counts(x, k, _f)
end
function histogram(x::AbstractVector{Union{T, Missing}}, bins::Union{AbstractVector, Integer, Symbol}, _f, scale = :pdf) where T <: Real
    if scale == :count
        _histogram(x, bins, _f)
    elseif scale == :pdf
        res = _histogram(x, bins, _f)
        # the firt bin count is 0 so we add 1 to h to make the size matched
        h = [1;diff(res[1])]
        (res[1], res[2]/sum(res[2] .* h))
    # we need to add :cdf, :density, :probability, ...?
    elseif scale == :cdf
          res = _histogram(x, bins, _f)
        # the firt bin count is 0 so we add 1 to h to make the size matched
        h = [1;diff(res[1])]
        (res[1], cumsum((res[2] .* h)/sum(res[2] .* h)))
    elseif scale == :probability
        res = _histogram(x, bins, _f)
        # the firt bin count is 0 so we add 1 to h to make the size matched
        h = [1;diff(res[1])]
        (res[1], (res[2] .* h)/sum(res[2] .* h))
    end
end

# _f is the format of column 
# TODO we should check if the formatted value is in supported type
function fit_hist(x, bins, scale, _f)::Vector{Tuple}
    res = histogram(x, bins, _f, scale)
    interval = collect(res[1])
    tuple.(interval[1:end-1], interval[2:end], res[2][2:end])
end

###############################################################

HISTOGRAM_DEFAULT = Dict{Symbol, Any}(:x=>0, :y=>0, :group=>nothing,
                                    :x2axis=>false,
                                    :y2axis=>false,
                                    :opacity=>1,
                                    :outlinethickness=>1,
                                    :filled=>true,
                                    :fill=>"null",
                                    :fillcolor=> :white,
                                    :color=>"#4682b4",
                                    :colorresponse => nothing,
                                    :colormodel=>["#2f6790", "#bed8ec"],
                                    :midpoints=>:Sturges,
                                    :scale => :pdf,
                                    :space => 1,
                                    :outlinecolor=>:white,
                                    :legend=>nothing,

                                    :clip=>nothing
                                    )
mutable struct Histogram <: SGMarks
    opts
    function Histogram(;opts...)
        optsd = val_opts(opts)
        cp_HISTOGRAM_DEFAULT = update_default_opts!(deepcopy(HISTOGRAM_DEFAULT), optsd)
        if (cp_HISTOGRAM_DEFAULT[:x] == 0 && cp_HISTOGRAM_DEFAULT[:y] == 0)
            throw(ArgumentError("Histogram plot needs one of x and y keyword arguments"))
        end
        new(cp_HISTOGRAM_DEFAULT)
    end
end

# Histogram graphic produce a simple Histogram plot
# It requires one of x or y keyword arguments 
# It needs the input data be processed before being sent to  vega
function _push_plots!(vspec, plt::Histogram, all_args; idx = 1)
    # check if the required arguments are passed / create a new ds and push it to out_ds
    new_ds = _check_and_normalize!(plt, all_args)
    _add_legends!(plt, all_args, idx)
    data_csv = tempname()
    filewriter(data_csv, new_ds, mapformats = all_args.mapformats, quotechar = '"')
    push!(vspec[:data], Dict{Symbol, Any}(:name => "hist_data_$idx", :values => read(data_csv, String), :format => Dict(:type => "csv", :delimiter => ",", :parse=>:auto)))
    opts = plt.opts

    s_spec = Dict{Symbol,Any}()
    s_spec[:type] = "group"
    s_spec[:clip] = something(opts[:clip], all_args.opts[:clip])
    s_spec_marks = Dict{Symbol,Any}()
    s_spec_marks[:type] = "rect"
    s_spec_marks[:from] = Dict(:data => "hist_data_$idx")
    s_spec_marks[:encode] = Dict{Symbol,Any}()
    s_spec_marks[:encode][:enter] = Dict{Symbol,Any}()
    s_spec_marks[:encode][:enter][:opacity] = Dict(:value => opts[:opacity])
    s_spec_marks[:encode][:enter][:stroke] = Dict(:value => opts[:outlinecolor])
    s_spec_marks[:encode][:enter][:strokeWidth] = Dict(:value => opts[:outlinethickness])
    s_spec_marks[:encode][:enter][:fill] = Dict{Symbol,Any}()
    # group in all plots uses the same scale
    if opts[:group] === nothing
        s_spec_marks[:encode][:enter][:fill][:value] = opts[:color]
    else
        s_spec[:from] = Dict{Symbol,Any}()
        s_spec[:from][:facet] = Dict{Symbol,Any}()
        s_spec[:from][:facet][:name] = "group_facet_source"
        s_spec[:from][:facet][:data] = "hist_data_$idx"
        s_spec[:from][:facet][:groupby] = opts[:group]
        s_spec_marks[:from][:data] = "group_facet_source"
        s_spec_marks[:encode][:enter][:fill][:scale] = "group_scale"
        s_spec_marks[:encode][:enter][:fill][:field] = opts[:group]
        # group is the 5th element of scales
        addto_group_scale!(vspec[:scales][5], "hist_data_$idx", opts[:group], all_args)
    end
    s_spec_marks[:encode][:enter][:x] = Dict{Symbol,Any}()
    s_spec_marks[:encode][:enter][:x2] = Dict{Symbol, Any}()
    if opts[:x] != 0
        if opts[:x2axis]
            s_spec_marks[:encode][:enter][:x][:scale] = "x2"
            s_spec_marks[:encode][:enter][:x2][:scale] = "x2"
            addto_scale!(all_args, 2, new_ds, "__bin_start")
            addto_scale!(all_args, 2, new_ds, "__bin_end")
            addto_axis!(vspec[:axes][2], all_args.axes[2], opts[:x])
        else
            s_spec_marks[:encode][:enter][:x][:scale] = "x1"
            s_spec_marks[:encode][:enter][:x2][:scale] = "x1"
            addto_scale!(all_args, 1, new_ds, "__bin_start")
            addto_scale!(all_args, 1, new_ds, "__bin_end")
            addto_axis!(vspec[:axes][1], all_args.axes[1], opts[:x])
        end
        s_spec_marks[:encode][:enter][:y] = Dict{Symbol,Any}()
        s_spec_marks[:encode][:enter][:y2] = Dict{Symbol, Any}()
        if opts[:y2axis]
            s_spec_marks[:encode][:enter][:y][:scale] = "y2"
            s_spec_marks[:encode][:enter][:y2][:scale] = "y2"
            s_spec_marks[:encode][:enter][:y2][:value] = 0
            addto_scale!(all_args, 4, new_ds, "__weight")
            addto_axis!(vspec[:axes][4], all_args.axes[4], string(opts[:scale]))
            vspec[:scales][4][:zero] = true
        else
            s_spec_marks[:encode][:enter][:y][:scale] = "y1"
            s_spec_marks[:encode][:enter][:y2][:scale] = "y1"
            s_spec_marks[:encode][:enter][:y2][:value] = 0
            addto_scale!(all_args, 3, new_ds, "__weight")
            addto_axis!(vspec[:axes][3], all_args.axes[3], string(opts[:scale]))
            vspec[:scales][3][:zero] = true
        end
        s_spec_marks[:encode][:enter][:x][:offset] = opts[:space]
        s_spec_marks[:encode][:enter][:x][:field] = "__bin_start"
        s_spec_marks[:encode][:enter][:x2][:field] = "__bin_end"
        s_spec_marks[:encode][:enter][:y][:field] = "__weight"
    else
        s_spec_marks[:encode][:enter][:y] = Dict{Symbol,Any}()
        s_spec_marks[:encode][:enter][:y2] = Dict{Symbol,Any}()
        if opts[:y2axis]
            s_spec_marks[:encode][:enter][:y][:scale] = "y2"
            s_spec_marks[:encode][:enter][:y2][:scale] = "y2"
            addto_scale!(all_args, 4, new_ds, "__bin_start")
            addto_scale!(all_args, 4, new_ds, "__bin_end")
            addto_axis!(vspec[:axes][4], all_args.axes[4], opts[:y])
        else
            s_spec_marks[:encode][:enter][:y][:scale] = "y1"
            s_spec_marks[:encode][:enter][:y2][:scale] = "y1"
            addto_scale!(all_args, 3, new_ds, "__bin_start")
            addto_scale!(all_args, 3, new_ds, "__bin_end")
            addto_axis!(vspec[:axes][3], all_args.axes[3], opts[:y])
        end
        s_spec_marks[:encode][:enter][:x] = Dict{Symbol,Any}()
        s_spec_marks[:encode][:enter][:x2] = Dict{Symbol,Any}()
        if opts[:x2axis]
            s_spec_marks[:encode][:enter][:x][:scale] = "x2"
            s_spec_marks[:encode][:enter][:x2][:scale] = "x2"
            s_spec_marks[:encode][:enter][:x2][:value] = 0
            addto_scale!(all_args, 2, new_ds, "__weight")
            addto_axis!(vspec[:axes][2], all_args.axes[2], string(opts[:scale]))
            vspec[:scales][2][:zero] = true
        else
            s_spec_marks[:encode][:enter][:x][:scale] = "x1"
            s_spec_marks[:encode][:enter][:x2][:scale] = "x1"
            s_spec_marks[:encode][:enter][:x2][:value] = 0
            addto_scale!(all_args, 1, new_ds, "__weight")
            addto_axis!(vspec[:axes][1], all_args.axes[1], string(opts[:scale]))
            vspec[:scales][1][:zero] = true
        end
        s_spec_marks[:encode][:enter][:y2][:offset] = opts[:space]
        s_spec_marks[:encode][:enter][:y][:field] = "__bin_start"
        s_spec_marks[:encode][:enter][:y2][:field] = "__bin_end"
        s_spec_marks[:encode][:enter][:x][:field] = "__weight"
    end
    s_spec[:marks] = [s_spec_marks]
    push!(vspec[:marks], s_spec)
end


# converts all column names to string, also check if the required arguments are passed
# TODO use macro to generate repeated code
function _check_and_normalize!(plt::Histogram, all_args)

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
    if all_args.mapformats
        _f = getformat(ds, col)
    else
        _f = identity
    end
    if opts[:group] !== nothing
        if length(IMD.index(ds)[opts[:group]]) == 1
            opts[:group] = _colname_as_string(ds, opts[:group])
            g_col = unique(prepend!([IMD.index(ds)[opts[:group]]], _extra_col_for_panel))
            hist_ds =  modify!(combine(gatherby(ds, g_col, threads=threads, mapformats = all_args.mapformats), col => (x->fit_hist(x, plt.opts[:midpoints], plt.opts[:scale], _f))=> :__bin_start, threads = threads), :__bin_start =>splitter=>[:__bin_start, :__bin_end, :__weight], threads = threads)
        else
            @goto argerr
        end
    else
        g_col = copy(_extra_col_for_panel)
        hist_ds = modify!(combine(gatherby(ds, g_col, threads = threads, mapformats = all_args.mapformats), col => (x->fit_hist(x, plt.opts[:midpoints], plt.opts[:scale], _f))=>:__bin_start, threads = threads), :__bin_start=>splitter=>[:__bin_start, :__bin_end, :__weight], threads = threads)
    end


    return hist_ds
    @label argerr
        throw(ArgumentError("only a single column must be selected"))
end

function _add_legends!(plt::Histogram, all_args, idx)
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