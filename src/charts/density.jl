function _compute_kde(x, ngrid; f, kernel, bw)
    min_val = IMD.minimum(f, x)
    max_val = IMD.maximum(f, x)
    any(isequal.(max_val, (missing, NaN, Inf, -Inf))) && throw(ArgumentError("x shouldn't be all missing or contains any NaN or infinite value"))
    any(isequal.(min_val, (missing, NaN, Inf, -Inf))) && throw(ArgumentError("x shouldn't be all missing or contains any NaN or infinite value"))
    min_val == max_val && throw(ArgumentError("density needs at least two different values"))
    min_val = kernel == normal_kernel ? min_val - 3.0*bw : min_val - 1.0*bw
    max_val = kernel == normal_kernel ? max_val + 3.0*bw : max_val + 1.0*bw
    gridpoints = range(min_val, max_val, length=ngrid)
    res = Vector{Float64}(undef, length(gridpoints))
    for i in eachindex(gridpoints)
        res[i] = IMD.mean(y -> (1.0 / bw * kernel((gridpoints[i] - f(y)) / bw)), x)
    end
    collect(gridpoints), res
end
function normal_kernel(x)
    0.3989422804014327 * exp(-0.5 * x * x)
end
function epan_kernel(x)
    abs(x) <= 1 ? 3.0 / 4.0 * (1.0 - x * x) : 0.0
end
epan_kernel(::Missing) = missing
function triangular_kernel(x)
    abs(x) <= 1 ? 1.0 - abs(x) : 0.0
end
triangular_kernel(::Missing) = missing
function normal_pdf(x, mu, sigma)
    0.3989422804014327/sigma * exp(-0.5*((x-mu)/sigma)*((x-mu)/sigma))
end

#scale should be a function with one positional argument (density) and can accept the following keyword arguments: midpoints, npoints, samplesize, binwidth
function fit_density(x, type, kernel, bw, f, npoints, scale)::Vector{Tuple}
    _sample_size = count(y->!ismissing(f(y)), x)
    if type==:normal 
        mu = IMD.mean(f, x)
        sigma = IMD.std(f, x)
        any(isequal.(mu, (missing, NaN, Inf, -Inf))) && throw(ArgumentError("x shouldn't be all missing or contains any NaN or infinite value"))
        any(isequal.(sigma, (missing, NaN, Inf, -Inf))) && throw(ArgumentError("x shouldn't be all missing or contains any NaN or infinite value"))
        min_val = mu - 3*sigma
        max_val = mu + 3*sigma
        gridpoints = range(min_val, max_val, length = npoints)
       
        tuple.(collect(gridpoints), scale(normal_pdf.(gridpoints, mu, sigma); midpoints=collect(gridpoints), npoints=npoints, samplesize=_sample_size, binwidth = gridpoints[2]-gridpoints[1]))

    elseif type == :kernel
        bw = something(bw, 1.06*IMD.std(f, x)*_sample_size^(-0.2))
        kernel_type = kernel == :gaussian ? normal_kernel : kernel == :epanechnikov ? epan_kernel : kernel == :triangular ? triangular_kernel : throw(ArgumentError("only :gaussian, :epanechnikov and :triangular kernels are supported"))
        res = _compute_kde(x, npoints; f=f, kernel = kernel_type, bw=bw)
      
        tuple.(res[1],  scale(res[2]; midpoints=res[1], npoints=npoints, samplesize=_sample_size, binwidth = res[1][2]-res[1][1]))
    else
        throw(ArgumentError("type can be either :normal or :kernel"))
    end
end


DENSITY_DEFAULT = Dict{Symbol,Any}(:x => 0, :y => 0, :group => nothing,
    :x2axis => false,
    :y2axis => false,
    :interpolate => :linear,

    :type => :normal, # :normal or :kernel
    :weights => :gaussian,
    :bw => nothing, # automatically calculate
    :scale => :pdf, # user can pass any function to this option, the function must be in the form of fun(density; midpoints, npoints, samplesize, binwidth) , for :pdf the function is defined as f(x; args...) = x, for :count we compute the expected counts, f(x; args...) = x .* binwidth .* npoints , :cdf (x; binwidth, args...) -> cumsum(x .* binwidth)
    :baseline => 0.0,

    :opacity => 1,
    :fillopacity=>0.5,

    :filled => true,
    :fillcolor => nothing, # derive from :color

    :color =>nothing,

    :thickness=>1,
    
    :npoints=>100, # the grid number of points

   
    :legend => nothing,

    :clip => nothing
)
mutable struct Density <: SGMarks
    opts
    function Density(; opts...)
        optsd = val_opts(opts)
        cp_DENSITY_DEFAULT = update_default_opts!(deepcopy(DENSITY_DEFAULT), optsd)
        if (cp_DENSITY_DEFAULT[:x] == 0 && cp_DENSITY_DEFAULT[:y] == 0)
            throw(ArgumentError("Density plot needs one of x and y keyword arguments"))
        end
        new(cp_DENSITY_DEFAULT)
    end
end

# Density graphic produce a density (normal or kernel) plot
# It requires one of x or y keyword arguments 
# It needs the input data be processed before being sent to  vega
function _push_plots!(vspec, plt::Density, all_args; idx=1)
    # check if the required arguments are passed / create a new ds and push it to out_ds
    new_ds = _check_and_normalize!(plt, all_args)
    _add_legends!(plt, all_args, idx)
    data_csv = tempname()
    filewriter(data_csv, new_ds, mapformats=all_args.mapformats, quotechar='"')
    push!(vspec[:data], Dict{Symbol,Any}(:name => "density_data_$idx", :values => read(data_csv, String), :format => Dict(:type => "csv", :delimiter => ",", :parse => _write_parse_js(new_ds, all_args))))
    opts = plt.opts

    s_spec = Dict{Symbol,Any}()
    s_spec[:type] = "group"
    s_spec[:clip] = something(opts[:clip], all_args.opts[:clip])
    s_spec_marks = Dict{Symbol,Any}()
    s_spec_marks[:type] = "area"
    s_spec_marks[:from] = Dict(:data => "density_data_$idx")
    s_spec_marks[:encode] = Dict{Symbol,Any}()
    s_spec_marks[:encode][:enter] = Dict{Symbol,Any}()
    s_spec_marks[:encode][:enter][:interpolate] = Dict{Symbol,Any}(:value => opts[:interpolate])
    s_spec_marks[:encode][:enter][:opacity] = Dict{Symbol,Any}(:value => opts[:opacity])
    s_spec_marks[:encode][:enter][:fillOpacity] = Dict{Symbol,Any}(:value => opts[:fillopacity])
    # s_spec_marks[:encode][:enter][:stroke] = Dict{Symbol, Any}(:value => opts[:color])
    s_spec_marks[:encode][:enter][:strokeWidth] = Dict{Symbol,Any}(:value => opts[:thickness])

    s_spec_marks[:encode][:enter][:stroke] = Dict{Symbol,Any}()
    # group in all plots uses the same scale
    if opts[:filled]
        s_spec_marks[:encode][:enter][:fill] = Dict{Symbol,Any}()
    end
    if opts[:group] === nothing
        if opts[:filled]
            s_spec_marks[:encode][:enter][:fill][:value] = something(opts[:fillcolor], opts[:color], "red")
        end
        s_spec_marks[:encode][:enter][:stroke][:value] = something(opts[:color], "red") # we allow the outline color be set
    else
        s_spec[:from] = Dict{Symbol,Any}()
        s_spec[:from][:facet] = Dict{Symbol,Any}()
        s_spec[:from][:facet][:name] = "group_facet_source"
        s_spec[:from][:facet][:data] = "density_data_$idx"
        s_spec[:from][:facet][:groupby] = opts[:group]
        s_spec_marks[:from][:data] = "group_facet_source"
        if opts[:filled]
            s_spec_marks[:encode][:enter][:fill][:scale] = "group_scale"
            s_spec_marks[:encode][:enter][:fill][:field] = opts[:group]
            # for groups, allow user to set a single color for outline when fill is given
            if opts[:color] !== nothing
                s_spec_marks[:encode][:enter][:stroke][:value] = opts[:color]
            else
                s_spec_marks[:encode][:enter][:stroke][:scale] = "group_scale"
                s_spec_marks[:encode][:enter][:stroke][:field] = opts[:group]
            end
        else
            s_spec_marks[:encode][:enter][:stroke][:scale] = "group_scale"
            s_spec_marks[:encode][:enter][:stroke][:field] = opts[:group]
        end
        # group is the 5th element of scales
        addto_group_scale!(vspec[:scales][5], "density_data_$idx", opts[:group], all_args)
    end
    if opts[:x] != 0
        if opts[:x2axis]
            _scale_ = "x2"
            which_scale = 2
        else
            _scale_ = "x1"
            which_scale = 1
        end
        if opts[:y2axis]
            _scale_2_ = "y2"
            which_scale_2 = 4
        else
            _scale_2_ = "y1"
            which_scale_2 = 3
        end
        _var_ = :x
        _var_2_ = :y
        _orient = :vertical
    else
        if opts[:y2axis]
            _scale_ = "y2"
            which_scale = 4
        else
            _scale_ = "y1"
            which_scale = 3
        end
        if opts[:x2axis]
            _scale_2_ = "x2"
            which_scale_2 = 2
        else
            _scale_2_ = "x1"
            which_scale_2 = 1
        end

        _var_ = :y
        _var_2_ = :x
        _orient = :horizontal
    end
    s_spec_marks[:encode][:enter][:orient] = Dict{Symbol,Any}(:value => _orient)
    s_spec_marks[:encode][:enter][_var_] = Dict{Symbol,Any}()
    s_spec_marks[:encode][:enter][_var_2_] = Dict{Symbol,Any}()
    s_spec_marks[:encode][:enter][Symbol(_var_2_, 2)] = Dict{Symbol,Any}()

    s_spec_marks[:encode][:enter][_var_][:scale] = _scale_
    s_spec_marks[:encode][:enter][_var_2_][:scale] = _scale_2_
    s_spec_marks[:encode][:enter][Symbol(_var_2_, 2)][:scale] = _scale_2_
    addto_scale!(all_args, which_scale, new_ds, "$(sg_col_prefix)midpoint__density")
    addto_scale!(all_args, which_scale_2, new_ds, "$(sg_col_prefix)height__density")
    addto_axis!(vspec[:axes][which_scale], all_args.axes[which_scale], opts[_var_])
    addto_axis!(vspec[:axes][which_scale_2], all_args.axes[which_scale_2], opts[:scale] in (:count, :pdf, :cdf) ? string(opts[:scale]) : string(nameof(opts[:scale])))

    vspec[:scales][which_scale_2][:zero] = true


    s_spec_marks[:encode][:enter][_var_][:field] = "$(sg_col_prefix)midpoint__density"
    s_spec_marks[:encode][:enter][_var_2_][:field] = "$(sg_col_prefix)height__density"
    s_spec_marks[:encode][:enter][Symbol(_var_2_, 2)][:value] = opts[:baseline]


    s_spec[:marks] = [s_spec_marks]
    push!(vspec[:marks], s_spec)
end


# converts all column names to string, also check if the required arguments are passed
# TODO use macro to generate repeated code
function _check_and_normalize!(plt::Density, all_args)

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

        else
            @goto argerr
        end
    else
        g_col = copy(_extra_col_for_panel)
    end
    if opts[:scale] == :pdf 
        _scale_fun = (x; args...) -> x
    elseif opts[:scale] == :count # expected count
        _scale_fun = (x; binwidth, npoints, args...) -> x .* binwidth .* npoints
    elseif opts[:scale] == :cdf
        _scale_fun = (x; binwidth, args...) -> cumsum(x .* binwidth)
    else
        _scale_fun = opts[:scale]
    end
    density_ds = combine(gatherby(ds, g_col, mapformats=all_args.mapformats, threads=threads), col => (x -> fit_density(x, opts[:type], opts[:weights], opts[:bw], _f, opts[:npoints], _scale_fun)) => "$(sg_col_prefix)density_info", threads = threads)
    modify!(density_ds, "$(sg_col_prefix)density_info" => splitter => ["$(sg_col_prefix)midpoint__density", "$(sg_col_prefix)height__density"])
    select!(density_ds, Not("$(sg_col_prefix)density_info"))

    return density_ds
    @label argerr
    throw(ArgumentError("only a single column must be selected"))
end

function _add_legends!(plt::Density, all_args, idx)
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
        leg_spec_cp[:fill] = "group_scale"
        _build_legen!(leg_spec_cp, leg_spec.opts, "square", _title, "$(legend_id)_group_scale_legend_$idx", all_args)
        push!(all_args.out_legends, leg_spec_cp)
    end
end   

