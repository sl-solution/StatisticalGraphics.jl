function _xy_core(x, y, _f_x, _f_y; degree=1)
    s = zeros(degree+1)
    j=1
    for deg in 0:degree
        for (val_x, val_y) in zip(x, y)
            s[j] += ismissing(_f_x(val_x))||ismissing(_f_y(val_y)) ? 0.0 : _f_x(val_x)^deg * _f_y(val_y)
        end
        j += 1
    end
    s
end
# we use simple lsq - fast and memory efficient
function _reg_core(x, y, _f_x, _f_y; degree=1, intercept=true)
    init0 = 0
    xpx_elem = [IMD.sum(val -> (_f_x(val))^i, x) for i in init0:max(2, degree^2)]
    xpy = _xy_core(x, y, _f_x, _f_y, degree=degree)
    ypy = IMD.sum(val -> (_f_y(val))^2, y)
    dim = length(xpy)
    p = dim - Int(!(intercept))
    n = xpx_elem[1]
    xpx = Matrix{Float64}(undef, dim, dim)
    for i in 1:dim
        xpx[:, i] .= xpx_elem[1+(i-1):dim+(i-1)]
    end
    tols = _reg_sweep_tolerance(xpx, n)
    if !intercept
        xpx = xpx[2:end, 2:end]
        xpy = xpy[2:end]
        tols = tols[2:end]
    end
    A, dof = _reg_sweep(xpx, xpy, ypy, tols)
    if any(isnan, A)
        A = replace(A, NaN=>missing)
    end
    dof = n - dof
    beta = A[1:end-1, end]
    ssr = isless(A[end, end], 0.0) ? missing : A[end, end]
    ssreg = ypy - beta' * xpy
    n, p, xpx, beta, ypy, dof < 1 ? missing : ssr / dof, ssreg, dof, A
end

function _confident_mean(tval, sigmahat2, x0, invxpx, degree, init0, indiv) # set indiv = true for single observation confidence interval
    newx0 = x0 .^ (init0:degree)
    tval * sqrt(sigmahat2 * (Int(indiv) + newx0' * invxpx * newx0))
end
using Distributions
function reg_fit(x, y, _f_x, _f_y; degree=1, intercept=true, alpha=0.05, cl=false, npoints=100)::Vector{Tuple}
    min_val = IMD.minimum(_f_x, x)
    max_val = IMD.maximum(_f_x, x)

    any(isequal.(max_val, (missing, NaN, Inf, -Inf))) && throw(ArgumentError("x shouldn't be all missing or contains any NaN or infinite value"))
    any(isequal.(min_val, (missing, NaN, Inf, -Inf))) && throw(ArgumentError("x shouldn't be all missing or contains any NaN or infinite value"))

    x0 = range(min_val, max_val, length=npoints)
    reg_info = _reg_core(x, y, _f_x, _f_y, degree=degree, intercept=intercept)
    init0 = intercept ? 0 : 1
    fit = [sum(reg_info[4] .* (val_x .^ (init0:degree))) for val_x in x0]
    if cl && isless(0, reg_info[8])
        tval = quantile(TDist(reg_info[8]), 1 - alpha / 2)
        invxpx = reg_info[9][1:end-1, 1:end-1]
        upper_clm = [fit[i] + _confident_mean(tval, reg_info[6], x0[i], invxpx, degree, init0, false) for i in 1:length(x0)]
        lower_clm = [fit[i] - _confident_mean(tval, reg_info[6], x0[i], invxpx, degree, init0, false) for i in 1:length(x0)]
        upper_cli = [fit[i] + _confident_mean(tval, reg_info[6], x0[i], invxpx, degree, init0, true) for i in 1:length(x0)]
        lower_cli = [fit[i] - _confident_mean(tval, reg_info[6], x0[i], invxpx, degree, init0, true) for i in 1:length(x0)]
    else
        upper_clm = copy(fit)
        lower_clm = copy(fit)
        upper_cli = copy(fit)
        lower_cli = copy(fit)
    end
    tuple.(collect(x0), fit, lower_clm, upper_clm, lower_cli, upper_cli)
end
REG_DEFAULT = Dict{Symbol, Any}(:x => 0, :y=>0, :group=>nothing,
                                    :x2axis=>false,
                                    :y2axis=>false,
                                    :opacity=>1,
                                    :thickness=>1,
                                    :dash => [0],
                                    :color=>"#4682b4",
                                    :interpolate => :linear,

                                    :legend=>nothing,

                                    :clm => false, # confidence for mean
                                    :clmcolor=>nothing, # if user pass this, it will overwrite group color
                                    :clmopacity=>0.3,

                                    :cli => false, # confidence for individual
                                    :clicolor=>nothing,
                                    :cliopacity=>0.3,

                                    :degree=>1, # between 1 and 10
                                    :intercept=>true,
                                    :alpha=>0.05,

                                    :npoints=>100,


                                    :clip=>nothing
                                    )
mutable struct Reg <: SGMarks
    opts
    function Reg(;opts...)
        optsd = val_opts(opts)
        cp_REG_DEFAULT = update_default_opts!(deepcopy(REG_DEFAULT), optsd)
        if cp_REG_DEFAULT[:x] == 0 || cp_REG_DEFAULT[:y] == 0
            throw(ArgumentError("Reg plot needs both x and y keyword arguments"))
        end
        !(cp_REG_DEFAULT[:degree] isa Int) && throw(ArgumentError("degree must be an integer between 1 and 10"))
        !(cp_REG_DEFAULT[:degree] > 0 && cp_REG_DEFAULT[:degree] < 11) && throw(ArgumentError("degree must be an integer between 1 and 10"))

        new(cp_REG_DEFAULT)
    end
end

# Reg plot fits a regression line, i.e. y=a+b*x+b*x^2...
# It requires two keyword arguments; x and y 
# we preprocess data
function _push_plots!(vspec, plt::Reg, all_args; idx=1)
    # check if the required arguments are passed
    new_ds = _check_and_normalize!(plt, all_args)
    _add_legends!(plt, all_args, idx)
    data_csv = tempname()
    filewriter(data_csv, new_ds, mapformats=all_args.mapformats, quotechar='"')
    push!(vspec[:data], Dict{Symbol,Any}(:name => "reg_data_$idx", :values => read(data_csv, String), :format => Dict(:type => "csv", :delimiter => ",", :parse => :auto)))

    opts = plt.opts

    s_spec = Dict{Symbol,Any}()
    s_spec[:type] = "group"
    s_spec[:clip] = something(opts[:clip], all_args.opts[:clip])
    s_spec_marks = Dict{Symbol,Any}()
    s_spec_marks[:type] = "line"
    s_spec_marks[:from] = Dict(:data => "reg_data_$idx")
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
        s_spec[:from][:facet][:data] = "reg_data_$idx"
        s_spec[:from][:facet][:groupby] = opts[:group]
        s_spec_marks[:from][:data] = "group_facet_source"
        s_spec_marks[:encode][:enter][:stroke][:scale] = "group_scale"
        s_spec_marks[:encode][:enter][:stroke][:field] = opts[:group]
        # group is the 5th element of scales
        addto_group_scale!(vspec[:scales][5], "reg_data_$idx", opts[:group], all_args)
    end

    varx = opts[:x]
    vary = opts[:y]
    if opts[:x2axis]
        _scale_x = "x2"
        _scale_idx = 2
    else
        _scale_x = "x1"
        _scale_idx = 1
    end
    if opts[:y2axis]
        _scale_y = "y2"
        _scale_idx_2 = 4
    else
        _scale_y = "y1"
        _scale_idx_2 = 3
    end


    s_spec_marks[:encode][:enter][:x] = Dict{Symbol,Any}()
    s_spec_marks[:encode][:enter][:x][:scale] = _scale_x
    addto_scale!(all_args, _scale_idx, new_ds, "$(sg_col_prefix)_x0")
    addto_axis!(vspec[:axes][_scale_idx], all_args.axes[_scale_idx], varx)
    s_spec_marks[:encode][:enter][:x][:field] = "$(sg_col_prefix)_x0"
    s_spec_marks[:encode][:enter][:y] = Dict{Symbol,Any}()
    s_spec_marks[:encode][:enter][:y][:scale] = _scale_y
    addto_scale!(all_args, _scale_idx_2, new_ds, "$(sg_col_prefix)_yhat")
    addto_axis!(vspec[:axes][_scale_idx_2], all_args.axes[_scale_idx_2], vary)
    s_spec_marks[:encode][:enter][:y][:field] = "$(sg_col_prefix)_yhat"    
    s_spec[:marks] = []
    # if clm is provided
    if opts[:clm]
        s_reg_clm = deepcopy(s_spec_marks)
        delete!(s_reg_clm[:encode][:enter],:stroke)

        s_reg_clm[:encode][:enter][:y2] = Dict{Symbol,Any}()
        s_reg_clm[:type] = "area"
        s_reg_clm[:encode][:enter][:x][:field] = "$(sg_col_prefix)_x0"
        s_reg_clm[:encode][:enter][:x][:scale] = _scale_x

        s_reg_clm[:encode][:enter][:y][:field] = "$(sg_col_prefix)_l_clm"
        s_reg_clm[:encode][:enter][:y][:scale] = _scale_y
        addto_scale!(all_args, _scale_idx_2, new_ds, "$(sg_col_prefix)_l_clm")
        s_reg_clm[:encode][:enter][:y2][:field] = "$(sg_col_prefix)_u_clm"
        s_reg_clm[:encode][:enter][:y2][:scale] = _scale_y
        addto_scale!(all_args, _scale_idx_2, new_ds, "$(sg_col_prefix)_u_clm")

        s_reg_clm[:encode][:enter][:fillOpacity] = Dict{Symbol, Any}(:value => opts[:clmopacity])

         # group in all plots uses the same scale
         s_reg_clm[:encode][:enter][:fill] = Dict{Symbol, Any}()
        if opts[:group] === nothing || opts[:clmcolor] !== nothing
            s_reg_clm[:encode][:enter][:fill][:value] = something(opts[:clmcolor], :steelblue)
        else
            s_reg_clm[:encode][:enter][:fill][:scale] = "group_scale"
            s_reg_clm[:encode][:enter][:fill][:field] = opts[:group]
        end
        push!(s_spec[:marks], s_reg_clm)
    end
    if opts[:cli]
        s_reg_cli = deepcopy(s_spec_marks)
        delete!(s_reg_cli[:encode][:enter],:stroke)

        s_reg_cli[:encode][:enter][:y2] = Dict{Symbol,Any}()
        s_reg_cli[:type] = "area"
        s_reg_cli[:encode][:enter][:x][:field] = "$(sg_col_prefix)_x0"
        s_reg_cli[:encode][:enter][:x][:scale] = _scale_x

        s_reg_cli[:encode][:enter][:y][:field] = "$(sg_col_prefix)_l_cli"
        s_reg_cli[:encode][:enter][:y][:scale] = _scale_y
        addto_scale!(all_args, _scale_idx_2, new_ds, "$(sg_col_prefix)_l_cli")
        s_reg_cli[:encode][:enter][:y2][:field] = "$(sg_col_prefix)_u_cli"
        s_reg_cli[:encode][:enter][:y2][:scale] = _scale_y
        addto_scale!(all_args, _scale_idx_2, new_ds, "$(sg_col_prefix)_u_cli")

        s_reg_cli[:encode][:enter][:fillOpacity] = Dict{Symbol, Any}(:value => opts[:cliopacity])

        # group in all plots uses the same scale
        s_reg_cli[:encode][:enter][:fill] = Dict{Symbol, Any}()
       if opts[:group] === nothing || opts[:clicolor] !== nothing
           s_reg_cli[:encode][:enter][:fill][:value] = something(opts[:clicolor], :steelblue)
       else
           s_reg_cli[:encode][:enter][:fill][:scale] = "group_scale"
           s_reg_cli[:encode][:enter][:fill][:field] = opts[:group]
       end
        push!(s_spec[:marks], s_reg_cli)

    end

    # we like to put line at top of bands
    push!(s_spec[:marks], s_spec_marks)
    push!(vspec[:marks], s_spec)
       
end


# converts all column names to string, also check if the required arguments are passed
# TODO use macro to generate repeated code
function _check_and_normalize!(plt::Reg, all_args)
    opts = plt.opts
    ds = all_args.ds
    threads = all_args.threads
    _extra_col_for_panel = all_args._extra_col_for_panel

    if length(IMD.index(ds)[opts[:x]]) == 1
        opts[:x] = _colname_as_string(ds, opts[:x])
    else
        @goto argerr
    end
    if length(IMD.index(ds)[opts[:y]]) == 1
        opts[:y] = _colname_as_string(ds, opts[:y])
    else
        @goto argerr
    end
    if opts[:group] !== nothing
        if length(IMD.index(ds)[opts[:group]]) == 1
            opts[:group] = _colname_as_string(ds, opts[:group])
            g_col = unique(prepend!([IMD.index(ds)[opts[:group]]], _extra_col_for_panel))
        else
            @goto argerr
        end
    else
        g_col = _extra_col_for_panel
    end
    _f_x = identity
    _f_y = identity
    if all_args.mapformats
        _f_x = getformat(ds, opts[:x])
        _f_y = getformat(ds, opts[:y])
    end
    reg_ds = combine(gatherby(dropmissing(ds, [opts[:x], opts[:y]], mapformats=all_args.mapformats, threads=threads, view=true), g_col, threads = threads, mapformats = all_args.mapformats), (opts[:x], opts[:y])=> ((x,y)->reg_fit(x, y, _f_x, _f_y, degree = opts[:degree], intercept = opts[:intercept], alpha = opts[:alpha], cl = opts[:clm] || opts[:cli], npoints=opts[:npoints])) => "$(sg_col_prefix)reg__info__", threads = threads)

    # byrow(Float64) makes sure that all computed columns are of type Float64 (sometime they would be Missing rather than Union{Missing, Float64})
    modify!(reg_ds, "$(sg_col_prefix)reg__info__" => splitter => ["$(sg_col_prefix)_x0", "$(sg_col_prefix)_yhat", "$(sg_col_prefix)_l_clm", "$(sg_col_prefix)_u_clm", "$(sg_col_prefix)_l_cli", "$(sg_col_prefix)_u_cli"], ["$(sg_col_prefix)_yhat", "$(sg_col_prefix)_l_clm", "$(sg_col_prefix)_u_clm", "$(sg_col_prefix)_l_cli", "$(sg_col_prefix)_u_cli"] .=> byrow(Float64), threads = false)

    select!(reg_ds, Not("$(sg_col_prefix)reg__info__"))

    return reg_ds


    @label argerr
    throw(ArgumentError("only a single column must be selected"))
end

function _add_legends!(plt::Reg, all_args, idx)
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