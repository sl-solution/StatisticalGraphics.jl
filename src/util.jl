# we use this name prefix for internal column names to minimise the risk of duplicate names
sg_col_prefix = "__sg__129834__"

function freq(f, x)
    length(x)
end

function val_opts(opts)
    d = Dict{Symbol,Any}()
    for (opt_name, opt_val) in opts
        d[opt_name] = opt_val
    end
    return d
end

function update_default_opts!(default, vals)
    for (opt_name, opt_val) in vals
        default[opt_name] = opt_val
    end
    default
end

# show an html file
function launch_browser(tmppath::String)
    if Sys.isapple()
        run(`open $tmppath`)
    elseif Sys.iswindows()
        run(`cmd /c start $tmppath`)
    elseif Sys.islinux()
        run(`xdg-open $tmppath`)
    end
end

function _colname_as_string(ds, col)
    if col != 0
        first(names(ds, IMD.index(ds)[col]))
    else
        ""
    end
end

# apply the default fonts for axes 
function _apply_fontstyling_for_axes!(axes, all_args)
    for axis in axes
        axis.opts[:titlefont] = something(axis.opts[:titlefont], axis.opts[:font], all_args.opts[:font])
        axis.opts[:titleitalic] = something(axis.opts[:titleitalic], axis.opts[:italic], all_args.opts[:italic])
        axis.opts[:titlefontweight] = something(axis.opts[:titlefontweight], axis.opts[:fontweight], all_args.opts[:fontweight])
        axis.opts[:labelfont] = something(axis.opts[:labelfont], axis.opts[:font], all_args.opts[:font])
        axis.opts[:labelitalic] = something(axis.opts[:labelitalic], axis.opts[:italic], all_args.opts[:italic])
        axis.opts[:labelfontweight] = something(axis.opts[:labelfontweight], axis.opts[:fontweight], all_args.opts[:fontweight])
    end
end

# creates a new scale for each single plot
function addto_color_scale!(vspec, source, name, col, isnominal; color_model = nothing)
    new_scale = Dict{Symbol,Any}()
    new_scale[:domain] = Dict{Symbol,Any}()
    new_scale[:domain][:fields] = Dict{Symbol,Any}[]
    push!(new_scale[:domain][:fields], Dict{Symbol,Any}(:data => source, :field => col))
    # we support two types :point and :linear
    new_scale[:type] = isnominal ? "ordinal" : "linear"
    new_scale[:range] = color_model !== nothing ? color_model : isnominal ? "category" : "diverging"
    new_scale[:name] = name
    push!(vspec[:scales], new_scale)
end

function addto_symbol_scale!(vspec, source, name, col)
    new_scale = Dict{Symbol,Any}()
    new_scale[:domain] = Dict{Symbol,Any}()
    new_scale[:domain][:fields] = Dict{Symbol,Any}[]
    push!(new_scale[:domain][:fields], Dict{Symbol,Any}(:data => source, :field => col))
    #symbol only supports "ordinal" scale
    new_scale[:type] = "ordinal"
    new_scale[:range] = "symbol"
    new_scale[:name] = name
    push!(vspec[:scales], new_scale)
end
# function addto_opacity_scale!(vspec, source, name, col)
#     new_scale = Dict{Symbol,Any}()
#     new_scale[:domain] = Dict{Symbol,Any}()
#     new_scale[:domain][:fields] = Dict{Symbol,Any}[]
#     push!(new_scale[:domain][:fields], Dict{Symbol,Any}(:data => source, :field => col))
#     new_scale[:type] = "linear"
#     new_scale[:range] = [0,1]
#     new_scale[:name] = name
#     push!(vspec[:scales], new_scale)
# end

# identity scale defines both domains and range as the [min, max]
# useful for angleresponse, opacityresponse...
# user must make sure that the response are valid
function addto_identity_scale!(vspec, source, name, col)
    new_scale = Dict{Symbol,Any}()
    new_scale[:domain] = Dict{Symbol,Any}()
    new_scale[:domain][:fields] = Dict{Symbol,Any}[]
    push!(new_scale[:domain][:fields], Dict{Symbol,Any}(:data => source, :field => col))
    # we trick vega to find range for angle scale based on domain of dummy scale
    new_scale[:name] = "dummy_$name"
    push!(vspec[:scales], new_scale)

    new_scale = Dict{Symbol,Any}()
    new_scale[:domain] = Dict{Symbol,Any}(:signal => "domain('dummy_$name')")
    new_scale[:type] = "linear"
    new_scale[:range] = Dict{Symbol,Any}(:signal => "domain('dummy_$name')")
    new_scale[:name] = name
    push!(vspec[:scales], new_scale)
end

function addto_size_scale!(vspec, source, name, col, minsize, maxsize)
    new_scale = Dict{Symbol,Any}()
    new_scale[:domain] = Dict{Symbol,Any}()
    new_scale[:domain][:fields] = Dict{Symbol,Any}[]
    push!(new_scale[:domain][:fields], Dict{Symbol,Any}(:data => source, :field => col))
    new_scale[:type] = "linear"
    new_scale[:range] = [minsize^2, maxsize^2]
    new_scale[:name] = name
    push!(vspec[:scales], new_scale)
end

function addto_group_scale!(group_scale, source, col, all_args)
    if haskey(group_scale, :type) # it has been initialised
        push!(group_scale[:domain][:fields], Dict{Symbol,Any}(:data => source, :field => col))
    else # we should initial the scale first
        group_scale[:type] = col in all_args.nominal ? "ordinal" : "linear"
        group_scale[:domain] = Dict{Symbol,Any}()
        group_scale[:domain][:fields] = Dict{Symbol,Any}[]
        push!(group_scale[:domain][:fields], Dict{Symbol,Any}(:data => source, :field => col))
        group_scale[:range] = all_args.opts[:groupcolormodel]
    end
end

# the following function is to convert some specific types before sending to js
_convert_values_for_js(x::Union{Date, DateTime}) = datetime2unix(DateTime(x)) * 1000 # JS cannot read Julia datetime
_convert_values_for_js(x::Bool) = x ? 1 : 0 # filewrite writes bools as 0/1
_convert_values_for_js(x) = x

function addto_scale!(all_args, which_scale, ds, col)
    if all_args.scale_type[which_scale] === nothing
        if col in all_args.nominal
            all_args.scale_type[which_scale] = :point
        else
            all_args.scale_type[which_scale] = all_args.axes[which_scale].opts[:type]
        end
    else
        # check the consitency of scale type
        if col in all_args.nominal
            if !(all_args.scale_type[which_scale] in [:band, :point])
                throw(ArgumentError("discrete and continuous axis cannot be mixed"))
            end
        end
    end

    if all_args.mapformats
        _f = getformat(ds, col)
    else
        _f = identity
    end

    _fun_ = _convert_values_for_js ∘ _f # we should this one for finding domains

    #TODO we should have option about how to handle missings
    if all_args.axes[which_scale].opts[:order] == :ascending
        _temp_fun = x -> sort(filter(!ismissing, _fun_.(unique(_fun_, x))))
    elseif all_args.axes[which_scale].opts[:order] == :descending
        _temp_fun = x -> sort(filter(!ismissing, _fun_.(unique(_fun_, x))), rev=true)
    else
        _temp_fun = x -> filter(!ismissing, _fun_.(unique(_fun_, x)))
    end

    if all_args.uniscale_col === nothing
        if all_args.scale_type[which_scale] in [:band, :point]
            append!(all_args.scale_ds[which_scale], combine(ds, col => (_temp_fun) => "$(sg_col_prefix)__scale_col__"), promote=true, cols=:union)
        else
            if all_args.axes[which_scale].opts[:range] === nothing
                append!(all_args.scale_ds[which_scale], combine(ds, col => (x -> [IMD.minimum(_fun_, x), IMD.maximum(_fun_, x)]) => "$(sg_col_prefix)__scale_col__"), promote=true, cols=:union)
            else
                _axis_limits=all_args.axes[which_scale].opts[:range]
                (!(_axis_limits isa AbstractVector) || length(_axis_limits) != 2 ) && throw(ArgumentError("axis range limits must be a vector of min and max values of the axis domain"))
                append!(all_args.scale_ds[which_scale], combine(ds, col => (x -> _convert_values_for_js.([_axis_limits[1], _axis_limits[2]])) => "$(sg_col_prefix)__scale_col__"), promote=true, cols=:union)
            end
        end
    else
        # for shared axes we do not use gatheby to keep the order of axes based on Axis.opts[:order]
        if !(which_scale in all_args.independent_axes)
             if all_args.scale_type[which_scale] in [:band, :point]
                append!(all_args.scale_ds[which_scale], combine(ds, col => (_temp_fun) => "$(sg_col_prefix)__scale_col__"), promote=true, cols=:union)
            else
                append!(all_args.scale_ds[which_scale], combine(ds, col => (x -> [IMD.minimum(_fun_, x), IMD.maximum(_fun_, x)]) => "$(sg_col_prefix)__scale_col__"), promote=true, cols=:union)
            end
        else

            if all_args.scale_type[which_scale] in [:band, :point]
                append!(all_args.scale_ds[which_scale], combine(gatherby(ds, all_args.uniscale_col, mapformats = all_args.mapformats), col => (_temp_fun) => "$(sg_col_prefix)__scale_col__"), promote=true, cols=:union)
            else
                append!(all_args.scale_ds[which_scale], combine(gatherby(ds, all_args.uniscale_col, mapformats = all_args.mapformats), col => (x -> [IMD.minimum(_fun_, x), IMD.maximum(_fun_, x)]) => "$(sg_col_prefix)__scale_col__"), promote=true, cols=:union)
            end
        end
    end


    # if haskey(in_scale, :domain)
    #     push!(in_scale[:domain][:fields], Dict{Symbol,Any}(:data => source, :field => col))
    # else
    #     in_scale[:type] = isnominal ? "point" : axis.opts[:type]
    #     if axis.opts[:type] in [:time]
    #         delete!(in_scale, :zero)
    #     end
    #     in_scale[:domain] = Dict{Symbol,Any}()
    #     in_scale[:domain][:sort] = isnominal ? true : false
    #     in_scale[:domain][:fields] = Dict{Symbol,Any}[]
    #     push!(in_scale[:domain][:fields], Dict{Symbol,Any}(:data => source, :field => col))
    #     in_scale[:nice] = axis.opts[:nice]
    #     in_scale[:reverse] = axis.opts[:reverse]
    # end
end
function addto_axis!(in_axis, axis, title)
    if !haskey(in_axis, :domain)
        in_axis[:encode] = Dict{Symbol, Any}()
        # domain
        in_axis[:domain] = axis.opts[:show] ? axis.opts[:domain] : false
        in_axis[:domainColor] = something(axis.opts[:domaincolor], axis.opts[:color])
        if axis.opts[:domaindash] != [0] # due to bug in vega we should check this
            in_axis[:domainDash] = axis.opts[:domaindash]
        end
        in_axis[:domainWidth] = axis.opts[:domainthickness]
        #grid
        in_axis[:grid] = axis.opts[:grid]
        in_axis[:gridWidth] = axis.opts[:gridthickness]
        in_axis[:gridDash] = axis.opts[:griddash]
        in_axis[:gridColor] = something(axis.opts[:gridcolor], axis.opts[:color])
        #ticks
        if axis.opts[:tickcount] !== nothing
            in_axis[:tickCount] = axis.opts[:tickcount]
        else
            signal_text = contains(in_axis[:scale], "y") ? "ceil(height/40)" : "ceil(width/40)"
            in_axis[:tickCount] = Dict{Symbol,Any}(:signal => signal_text)
        end
        in_axis[:ticks] = axis.opts[:show] ? axis.opts[:ticks] : false
        in_axis[:tickSize] = axis.opts[:ticksize]
        in_axis[:tickColor] = something(axis.opts[:tickcolor], axis.opts[:color])
        in_axis[:tickWidth] =axis.opts[:tickthickness]
        if axis.opts[:tickdash] !=[0] # due to bug in safari (latest version)
            in_axis[:tickDash] = axis.opts[:tickdash]
        end
        #title
        if in_axis[:title] === nothing
            in_axis[:title] = title
        end
        if !axis.opts[:show]
            delete!(in_axis, :title)
        end

        in_axis[:titleColor] = something(axis.opts[:titlecolor], axis.opts[:color])
        in_axis[:titleAnchor] = axis.opts[:titleloc]
        axis.opts[:titlealign] !== nothing ? in_axis[:titleAlign] = axis.opts[:titlealign] : nothing
        axis.opts[:titleangle] !== nothing ? in_axis[:titleAngle] = axis.opts[:titleangle] : nothing
        axis.opts[:titlebaseline] !== nothing ? in_axis[:titleBaseline] = axis.opts[:titlebaseline] : nothing
        if axis.opts[:titlepos] !== nothing 
            in_axis[:titleX] = axis.opts[:titlepos][1]
            in_axis[:titleY] = axis.opts[:titlepos][2]
        end
        if axis.opts[:titlesize] !== nothing
            in_axis[:titleFontSize] = axis.opts[:titlesize]
        end
        if axis.opts[:titlepadding] !== nothing
            in_axis[:titlePadding] = axis.opts[:titlepadding]
        end


        #offset
        in_axis[:offset] = axis.opts[:offset]
        
        #labels
        
        if axis.opts[:show]
            in_axis[:labels] = axis.opts[:showlabels]
        else
            in_axis[:labels] = false
        end
        in_axis[:labelAngle] = axis.opts[:angle]
        if axis.opts[:baseline] !== nothing
            in_axis[:labelBaseline] = axis.opts[:baseline]
        end
        if axis.opts[:align] !== nothing
            in_axis[:labelAlign] = axis.opts[:align]
        end
        in_axis[:labelOverlap] = axis.opts[:labeloverlap]
        in_axis[:labelColor] = something(axis.opts[:labelcolor], axis.opts[:color])
        if axis.opts[:labelpadding] !== nothing
            in_axis[:labelPadding] = axis.opts[:labelpadding]
        end
        if axis.opts[:labelsize] !== nothing
            in_axis[:labelFontSize] = axis.opts[:labelsize]
        end

        if axis.opts[:d3format] !== nothing
            in_axis[:format] = axis.opts[:d3format]
        end

        if axis.opts[:values] !== nothing && axis.opts[:label_scale] === nothing
            !(axis.opts[:values] isa AbstractVector) && throw(ArgumentError("Axis values must be a vector of values"))
            in_axis[:values] = _convert_values_for_js.(axis.opts[:values])
        elseif axis.opts[:values] !== nothing && axis.opts[:label_scale] !== nothing
            in_axis[:values] = Dict{Symbol, Any}(:signal => "domain('$(axis.opts[:label_scale])')")
            in_axis[:encode][:labels] =Dict{Symbol, Any}()
            in_axis[:encode][:labels][:update] =Dict{Symbol, Any}()
            in_axis[:encode][:labels][:update][:text] = Dict{Symbol, Any}(:signal=>"scale('$(axis.opts[:label_scale])', datum.value)")
        end

        #fonts
       in_axis[:titleFont]=axis.opts[:titlefont]
       in_axis[:titleFontStyle]=axis.opts[:titleitalic] ? "italic" : "normal"
       in_axis[:titleFontWeight]=axis.opts[:titlefontweight]
       in_axis[:labelFont]=axis.opts[:labelfont]
       in_axis[:labelFontStyle]=axis.opts[:labelitalic] ? "italic" : "normal"
       in_axis[:labelFontWeight]=axis.opts[:labelfontweight]
        #misc
       in_axis[:zindex] = axis.opts[:zindex]
       if axis.opts[:translate] !== nothing
            in_axis[:translate] = axis.opts[:translate]
       end

    end
end

# apply default values for legend option in the case that user does not have any preference
function _build_legen!(out_leg, leg_opts, _symbol, _title, _id, all_args; opts...)
    out_leg[:name] = _id
    if leg_opts[:title] === nothing
        out_leg[:title] = _title
    else
        out_leg[:title] = leg_opts[:title]
    end
    if leg_opts[:symbol] === nothing 
        if  _symbol !== nothing
            out_leg[:symbolType] = _symbol
        end
    else
        out_leg[:symbolType] = leg_opts[:symbol]
    end
    out_leg[:orient] = leg_opts[:orient]
    out_leg[:columns] = leg_opts[:columns]
    out_leg[:direction] = leg_opts[:direction]
    out_leg[:symbolSize] = leg_opts[:size]
    for opt in opts
        push!(out_leg, opt)
    end
    out_leg[:gridAlign] = leg_opts[:gridalign]
    out_leg[:rowPadding] = leg_opts[:rowspace]
    out_leg[:columnPadding] = leg_opts[:columnspace]
    if leg_opts[:values] !== nothing && leg_opts[:values] isa AbstractVector
        out_leg[:values] = leg_opts[:values]
    end


    out_leg[:titleFont] = something(leg_opts[:titlefont], leg_opts[:font], all_args.opts[:font])
    out_leg[:titleFontStyle] = something(leg_opts[:titleitalic], leg_opts[:italic], all_args.opts[:italic]) ? "italic" : "normal"
    out_leg[:titleFontWeight] = something(leg_opts[:titlefontweight], leg_opts[:fontweight], all_args.opts[:fontweight])
    if leg_opts[:titlesize] !== nothing 
        out_leg[:titleFontSize] = leg_opts[:titlesize]
    end
    if leg_opts[:labelsize] !== nothing 
        out_leg[:labelFontSize] = leg_opts[:labelsize]
    end 
    out_leg[:labelFont] = something(leg_opts[:labelfont], leg_opts[:font], all_args.opts[:font])
    out_leg[:labelFontStyle] = something(leg_opts[:labelitalic], leg_opts[:italic], all_args.opts[:italic]) ? "italic" : "normal"
    out_leg[:labelFontWeight] = something(leg_opts[:labelfontweight], leg_opts[:fontweight], all_args.opts[:fontweight])
end

function _fill_scales!(vspec, all_args)
    independent_axes = all_args.independent_axes
    shared_axes = setdiff([1, 2, 3, 4], independent_axes)
    for i in 1:4
        if all_args.scale_type[i] !== nothing
            in_scale = vspec[:scales][i]
            in_scale[:type] = all_args.scale_type[i]
            if all_args.axes[i].opts[:exponent] !== nothing && in_scale[:type] == :pow
                in_scale[:exponent] = all_args.axes[i].opts[:exponent]
            end
            # some marks like Histogram, set :zero to true
            if !(in_scale[:type] in [:time, :band, :point]) && !haskey(in_scale, :zero)
                in_scale[:zero] = false
            end
            if !(in_scale[:type] in [:point, :band])
                in_scale[:nice] = all_args.axes[i].opts[:nice]
            end
            in_scale[:reverse] = all_args.axes[i].opts[:reverse]
            if all_args.axes[i].opts[:padding] !== nothing
                if (in_scale[:type] in [:point, :band, :discrete])
                    in_scale[:paddingOuter] = all_args.axes[i].opts[:padding]
                else
                    in_scale[:padding] = all_args.axes[i].opts[:padding]
                end
            end
        end
    end
    for i in shared_axes
        in_scale = vspec[:scales][i]
        if !isempty(all_args.scale_ds[i]) && all_args.scale_type[i] !== nothing
            if in_scale[:type] in [:band, :point]
                all_args.scale_ds[i] = combine(all_args.scale_ds[i], "$(sg_col_prefix)__scale_col__" => (x -> unique(vcat(x...))) => "$(sg_col_prefix)__scale_col__")
                in_scale[:domain] = all_args.scale_ds[i][:, "$(sg_col_prefix)__scale_col__"][1]
                # fix the issue when domain is singlton
                if !(in_scale[:domain] isa Vector)
                    in_scale[:domain] = [in_scale[:domain]]
                end
            else
                all_args.scale_ds[i] = combine(all_args.scale_ds[i], "$(sg_col_prefix)__scale_col__" => (x -> [[IMD.minimum(vcat(x...)), IMD.maximum(vcat(x...))]]) => "$(sg_col_prefix)__scale_col__")
                # in_scale[:domain] = combine(all_args.scale_ds[i], "$(sg_col_prefix)__scale_col__" => (x -> [IMD.minimum(vcat(x...)), IMD.maximum(vcat(x...))]) => "$(sg_col_prefix)__scale_col__")[:, "$(sg_col_prefix)__scale_col__"]
                in_scale[:domain] = all_args.scale_ds[i][:, "$(sg_col_prefix)__scale_col__"][1]
            end
        end
        
    end
    if !isempty(independent_axes)
        uniscale_col = all_args.uniscale_col
    end
    for i in independent_axes
        in_scale = vspec[:scales][i]
        if !isempty(all_args.scale_ds[i]) && all_args.scale_type[i] !== nothing
            if in_scale[:type] in [:band, :point]
                all_args.scale_ds[i] = combine(gatherby(all_args.scale_ds[i], uniscale_col, mapformats = all_args.mapformats), "$(sg_col_prefix)__scale_col__" => (x -> unique(vcat(x...))) => "$(sg_col_prefix)__scale_col__")
            else
                all_args.scale_ds[i] = in_scale[:domain] = combine(gatherby(all_args.scale_ds[i], uniscale_col, mapformats = all_args.mapformats), "$(sg_col_prefix)__scale_col__" => (x -> [[IMD.minimum(x), IMD.maximum(x)]]) => "$(sg_col_prefix)__scale_col__")
            end
            setformat!(all_args.scale_ds[i], uniscale_col => getformat(all_args.ds, uniscale_col))
        end
    end
end

function _crossprod(ds1, ds2)
    res = repeat(ds1, outer=nrow(ds2))
    IMD.hcat!(res, repeat(ds2, inner=nrow(ds1)))
    res
end


function _find_timetype_cols(ds, mapformats)
    if !mapformats
        names(ds, TimeType)
    else
        res = String[]
        for i in 1:ncol(ds)
            if Core.Compiler.return_type(getformat(ds, i), Tuple{eltype(IMD._columns(ds)[i])}) <: Union{Missing,TimeType}
                push!(res, names(ds)[i])
            end
        end
        res
    end
end

function add_dummy_col!(all_args)
    for i in 1:4
        if !isempty(all_args.scale_ds[i])
            insertcols!(all_args.scale_ds[i], 1, "$(sg_col_prefix)__dummy_column_for_join__" => true)
        end
    end
end

function join_scale_info!(ds, all_args)
    for i in 1:4
        if !isempty(all_args.scale_ds[i])
            leftjoin!(ds, all_args.scale_ds[i], on=intersect(names(ds), names(all_args.scale_ds[i])), mapformats = all_args.mapformats)
            rename!(ds, "$(sg_col_prefix)__scale_col__" => Symbol("$(sg_col_prefix)__scale__$(i)__"))
            # we should make sure domain is passed as a vector
            modify!(ds, Symbol("$(sg_col_prefix)__scale__$(i)__") => byrow(x -> x isa Vector ? x : [x]))

        end
    end
    # for proportional scales we support step size, at this point we set them as false
    insertcols!(ds, "$(sg_col_prefix)x_step" => false)
    insertcols!(ds, "$(sg_col_prefix)y_step" => false)
end

function add_height_width_x_y!(panel_info, all_args)
    if all_args.opts[:layout] == :column
        column_add_height_width_x_y!(panel_info, all_args)
    elseif all_args.opts[:layout] == :row
        row_add_height_width_x_y!(panel_info, all_args)
    elseif all_args.opts[:layout] == :lattice
        lattice_add_height_width_x_y!(panel_info, all_args)
    elseif all_args.opts[:layout] == :panel
        panel_add_height_width_x_y!(panel_info, all_args)
    end
end

function column_add_height_width_x_y!(panel_info, all_args)
    insertcols!(panel_info, "$(sg_col_prefix)x" => 0)
    insertcols!(panel_info, "$(sg_col_prefix)width" => all_args.opts[:width])
    
    ## only row heights can be proportional
    _find_height_proportion!(panel_info, all_args)
    insertcols!(panel_info, "$(sg_col_prefix)y" => panel_info[:, "$(sg_col_prefix)height"] .+ all_args.opts[:rowspace])
    modify!(panel_info, "$(sg_col_prefix)y" => cumsum, "$(sg_col_prefix)y" => (x->lag(x,1, default=0)))
    insertcols!(panel_info, "$(sg_col_prefix)xaxis" => false)
    panel_info[nrow(panel_info), "$(sg_col_prefix)xaxis"] = true
    insertcols!(panel_info, "$(sg_col_prefix)x2axis" => false)
    panel_info[1, "$(sg_col_prefix)x2axis"] = true
    insertcols!(panel_info, "$(sg_col_prefix)yaxis" => true)
    insertcols!(panel_info, "$(sg_col_prefix)y2axis" => true)
    # if header are requested we create their values
    insertcols!(panel_info, "$(sg_col_prefix)cell_title_$(all_args.opts[:headerorient])"=>_how_to_print.(panel_info[:, "$(sg_col_prefix)__title_info_for_each_panel__"], all_args.opts[:headercolname]))

end
function row_add_height_width_x_y!(panel_info, all_args)
    insertcols!(panel_info, "$(sg_col_prefix)y" => 0)
    _find_width_proportion!(panel_info, all_args)
    insertcols!(panel_info, "$(sg_col_prefix)height" => all_args.opts[:height])
    insertcols!(panel_info, "$(sg_col_prefix)x" => panel_info[:, "$(sg_col_prefix)width"] .+ all_args.opts[:columnspace])
    modify!(panel_info, "$(sg_col_prefix)x" => cumsum, "$(sg_col_prefix)x" => (x -> lag(x, 1, default=0)))
    insertcols!(panel_info, "$(sg_col_prefix)yaxis" => false)
    panel_info[1, "$(sg_col_prefix)yaxis"] = true
    insertcols!(panel_info, "$(sg_col_prefix)y2axis" => false)
    panel_info[nrow(panel_info), "$(sg_col_prefix)y2axis"] = true
    insertcols!(panel_info, "$(sg_col_prefix)xaxis" => true)
    insertcols!(panel_info, "$(sg_col_prefix)x2axis" => true)

    # if header are requested we create their values
    insertcols!(panel_info, "$(sg_col_prefix)cell_title_$(all_args.opts[:headerorient])" => _how_to_print.(panel_info[:, "$(sg_col_prefix)__title_info_for_each_panel__"], all_args.opts[:headercolname]))
  
end

function _bool_first_true(x)
    res = zeros(Bool, length(x))
    res[1] = true
    res
end
function _bool_last_true(x)
    res = zeros(Bool, length(x))
    res[end] = true
    res
end

function _first_not_missing(x)
    res = copy(x)
    res[2:end] .= missing
    res
end
function _last_not_missing(x)
    res = copy(x)
    res[1:end-1] .= missing
    res
end

function lattice_add_height_width_x_y!(panel_info, all_args)
   
    # insertcols!(panel_info, :width => all_args.opts[:width])
    # insertcols!(panel_info, :height => all_args.opts[:height])
    _find_width_proportion!(panel_info, all_args)
    _find_height_proportion!(panel_info, all_args)
    insertcols!(panel_info, "$(sg_col_prefix)y" => panel_info[:, "$(sg_col_prefix)height"] .+ all_args.opts[:rowspace])
    insertcols!(panel_info, "$(sg_col_prefix)x" => panel_info[:, "$(sg_col_prefix)width"] .+ all_args.opts[:columnspace])
    modify!(gatherby(panel_info, 3, mapformats = all_args.mapformats, threads = false), "$(sg_col_prefix)x" => cumsum, "$(sg_col_prefix)x" =>lag)
    modify!(gatherby(panel_info, 2, mapformats = all_args.mapformats, threads = false), "$(sg_col_prefix)y" => cumsum, "$(sg_col_prefix)y" => lag)
    map!(panel_info, x->ismissing(x) ? 0 : x, ["$(sg_col_prefix)x", "$(sg_col_prefix)y"])
    modify!(gatherby(panel_info, 3, mapformats = all_args.mapformats, threads = false), 1 => _bool_first_true => "$(sg_col_prefix)yaxis")
    modify!(gatherby(panel_info, 3, mapformats = all_args.mapformats, threads = false), 1 => _bool_last_true => "$(sg_col_prefix)y2axis")
    modify!(gatherby(panel_info, 2, mapformats = all_args.mapformats, threads = false), 1 => _bool_first_true => "$(sg_col_prefix)x2axis")
    modify!(gatherby(panel_info, 2, mapformats = all_args.mapformats, threads = false), 1 => _bool_last_true => "$(sg_col_prefix)xaxis")

    if all_args.opts[:layout] == :panel
        insertcols!(panel_info, "$(sg_col_prefix)cell_title_$(all_args.opts[:headerorient])" => _how_to_print.(panel_info[:, "$(sg_col_prefix)__title_info_for_each_panel__"], all_args.opts[:headercolname]))
    else
        _cols_orient = all_args.opts[:headerorient] in (:topleft, :topright) ? :top : :bottom
        _rows_orient = all_args.opts[:headerorient] in (:topleft, :bottomleft) ? :left : :right 
        which_have_header_cols = _cols_orient == :top ? _first_not_missing : _last_not_missing
        which_have_header_rows = _rows_orient == :left ? _first_not_missing : _last_not_missing
        
        insertcols!(panel_info, "$(sg_col_prefix)cell_title_$(_cols_orient)" => _how_to_print.(panel_info[:, "$(sg_col_prefix)__title_info_for_each_panel__"], all_args.opts[:headercolname], idx=1))
        modify!(gatherby(panel_info, 2, mapformats = all_args.mapformats, threads = false), "$(sg_col_prefix)cell_title_$(_cols_orient)" => which_have_header_cols)

        insertcols!(panel_info, "$(sg_col_prefix)cell_title_$(_rows_orient)" => _how_to_print.(panel_info[:, "$(sg_col_prefix)__title_info_for_each_panel__"], all_args.opts[:headercolname], idx=2))
         modify!(gatherby(panel_info, 3, mapformats = all_args.mapformats, threads = false), "$(sg_col_prefix)cell_title_$(_rows_orient)" => which_have_header_rows)
    end
end
function panel_add_height_width_x_y!(panel_info, all_args)
    if all_args.opts[:rows] === nothing
        number_of_columns = all_args.opts[:columns]
        number_of_rows = Int(ceil(nrow(panel_info) / number_of_columns))
    else
        number_of_rows = all_args.opts[:rows]
        number_of_columns = Int(ceil(nrow(panel_info) / number_of_rows))
    end
    p2 = repeat(1:number_of_rows, inner = number_of_columns)
    p1 = repeat(1:number_of_columns, outer = number_of_rows)
    insertcols!(panel_info, 2, "$(sg_col_prefix)__panel_new_group_colid__" => p1[1:nrow(panel_info)])
    insertcols!(panel_info, 3, "$(sg_col_prefix)__panel_new_group_rowid__" => p2[1:nrow(panel_info)])
    lattice_add_height_width_x_y!(panel_info, all_args)
  
end

function _modify_scales_for_panel(scales, info)
    for i in 1:4
        if haskey(scales[i], :type)
            scales[i][:domain] = info[Symbol("$(sg_col_prefix)__scale__$(i)__")]
            if i < 3
                if (scales[i][:type] in [:point, :band, :discrete]) && info["$(sg_col_prefix)x_step"]
                    scales[i][:range] = Dict{Symbol, Any}(:step => info["$(sg_col_prefix)x_step_size"])
                else
                    scales[i][:range] = [0, info["$(sg_col_prefix)width"]]
                end
            else
                if (scales[i][:type] in [:point, :band, :discrete]) &&  info["$(sg_col_prefix)y_step"]
                    scales[i][:range] = Dict{Symbol,Any}(:step => info["$(sg_col_prefix)y_step_size"])
                else
                    scales[i][:range] = [info["$(sg_col_prefix)height"], 0]
                end
            end
        end
    end
    scales
end
function _modify_axes_for_panel(all_args, axes, info)
    lattice_type = all_args.opts[:layout] != :panel # for lattice type layouts we remove axes titles and add them for all colum and rows
    x1loc = findfirst(x -> x[:scale] == "x1", axes)
    if x1loc !== nothing
        if !info["$(sg_col_prefix)xaxis"]
            delete!(axes[x1loc], :title)
            axes[x1loc][:ticks] = false
            axes[x1loc][:domain] = false
            axes[x1loc][:labels] = false
        end
        if lattice_type
            delete!(axes[x1loc], :title)
        end
        if all_args.axes[1].opts[:tickcount] === nothing
            axes[x1loc][:tickCount] = ceil(info["$(sg_col_prefix)width"] / 40)
        end
    end
    x2loc = findfirst(x -> x[:scale] == "x2", axes)
    if x2loc !== nothing
        if !info["$(sg_col_prefix)x2axis"]
            delete!(axes[x2loc], :title)
            axes[x2loc][:ticks] = false
            axes[x2loc][:domain] = false
            axes[x2loc][:labels] = false
        end
         if lattice_type
            delete!(axes[x2loc], :title)
        end
        if all_args.axes[2].opts[:tickcount] === nothing
            axes[x2loc][:tickCount] = ceil(info["$(sg_col_prefix)width"] / 40)
        end
    end
    y1loc = findfirst(x -> x[:scale] == "y1", axes)
    if y1loc !== nothing
        if !info["$(sg_col_prefix)yaxis"]
            delete!(axes[y1loc], :title)
            axes[y1loc][:ticks] = false
            axes[y1loc][:domain] = false
            axes[y1loc][:labels] = false
        end
         if lattice_type
            delete!(axes[y1loc], :title)
        end
        if all_args.axes[3].opts[:tickcount] === nothing
            axes[y1loc][:tickCount] = ceil(info["$(sg_col_prefix)height"] / 40)
        end
    end
    y2loc = findfirst(x -> x[:scale] == "y2", axes)
    if y2loc !== nothing
        if !info["$(sg_col_prefix)y2axis"]
            delete!(axes[y2loc], :title)
            axes[y2loc][:ticks] = false
            axes[y2loc][:domain] = false
            axes[y2loc][:labels] = false
        end
        if lattice_type
            delete!(axes[y2loc], :title)
        end
        if all_args.axes[4].opts[:tickcount] === nothing
            axes[y2loc][:tickCount] = ceil(info["$(sg_col_prefix)height"] / 40)
        end
    end
    # gridScale must be specified for each cell
    if x1loc !== nothing
        if y1loc !== nothing
            axes[x1loc][:gridScale] = "y1"
        else
            axes[x1loc][:gridScale] = "y2"
        end
    else
        if y1loc !== nothing
            axes[x2loc][:gridScale] = "y1"
        else
            axes[x2loc][:gridScale] = "y2"
        end
    end
    if y1loc !== nothing
        if x1loc !== nothing
            axes[y1loc][:gridScale] = "x1"
        else
            axes[y1loc][:gridScale] = "x2"
        end
    else
        if x1loc !== nothing
            axes[y2loc][:gridScale] = "x1"
        else
            axes[y2loc][:gridScale] = "x2"
        end
    end
    axes
end

function add_filters_to_panel_info_fun(val...; colname, f)
    expr  = ""
    for i in eachindex(colname)
        if ismissing(f[i](val[i]))
            expr *= " datum['$(colname[i])'] == null "
        else
            expr *= " datum['$(colname[i])'] == '$(_convert_values_for_js(f[i](val[i])))' "
        end
        if i != lastindex(colname)
            expr *= " && "
        end
    end
    expr
end


function add_filters!(panel_info, all_args)
    _f = all_args.mapformats ? getformat.(Ref(all_args.ds), all_args.panelby) : repeat([identity], length(all_args.panelby))
    modify!(panel_info, (all_args.panelby...,) => byrow((x...) -> add_filters_to_panel_info_fun(x...; colname=all_args.panelby, f = _f )) => "$(sg_col_prefix)__filtering_formula__")
end

function add_title_to_panel(val...; colname, f)
    keys = (Symbol.(colname)...,)
    vals = ([f[i](val[i]) for i in 1:length(f)]...,)
    (; zip(keys, vals)...)
end

function add_title_panel!(panel_info, all_args)
    _f = all_args.mapformats ? getformat.(Ref(all_args.ds), all_args.panelby) : repeat([identity], length(all_args.panelby))
    modify!(panel_info, (all_args.panelby...,) => byrow((x...) -> add_title_to_panel(x...; colname=all_args.panelby, f=_f)) => "$(sg_col_prefix)__title_info_for_each_panel__")
end

function _modify_data_for_panel!(vspec, marks, info, idx)
    for i in eachindex(marks)
        needchange = true
        if haskey(marks[i], :from)
            old_name = marks[i][:from][:facet][:data]
            new_name = old_name * "_$idx"
            marks[i][:from][:facet][:data] = new_name
        elseif haskey(marks[i], :marks)
            old_name = marks[i][:marks][1][:from][:data]
            new_name = old_name * "_$idx"
            marks[i][:marks][1][:from][:data] = new_name
        else
            needchange = false
        end
        if needchange
            push!(vspec[:data], Dict{Symbol, Any}(:name => new_name, :source => old_name, :transform => Dict{Symbol, Any}[Dict{Symbol, Any}(:type=>:filter, :expr => info["$(sg_col_prefix)__filtering_formula__"])]))
        end
    end
end

function _find_height_proportion!(panel_info, all_args)
    if all_args.opts[:proportional] && all_args.opts[:linkaxis] == :x
        #check we both scale 3 and 4 are discrete
        !all(all_args.scale_type[3:4] .∈ Ref([nothing, :band, :point, :discrete])) && throw(ArgumentError("propertional keyword argument only supported for discrete type axes"))
        type3 = all_args.scale_type[3]
        type4 = all_args.scale_type[4]
        # band has half of step on each side of axis
        max3 = type3 === nothing ? 0 : type3 == :point ? max(1, maximum(length, panel_info[:, "$(sg_col_prefix)__scale__3__"]) - 1) : maximum(length, panel_info[:, "$(sg_col_prefix)__scale__3__"])
        max4 = type4 === nothing ? 0 : type4 == :point ? max(1, maximum(length, panel_info[:, "$(sg_col_prefix)__scale__4__"]) - 1) : maximum(length, panel_info[:, "$(sg_col_prefix)__scale__4__"])
        max_length = max(max3, max4)
    
        # if stepsize is not given we should calculate it
        if all_args.opts[:stepsize] === nothing
            stepsize = Int(ceil(all_args.opts[:height] / max_length))
        else
            stepsize = all_args.opts[:stepsize]
        end
        map!(panel_info, x->true, "$(sg_col_prefix)y_step")
        insertcols!(panel_info, "$(sg_col_prefix)y_step_size" => stepsize)
        # we should treat point and band differently

        # modify!(panel_info, colname .=> byrow(length) .=> ["____temp4353465464_$i" for i in colname], ["____temp4353465464_$i" for i in colname] => byrow(max) => :height_step, [:height_step, :y_step_size] => byrow(prod) => :height)
        if type3 !== nothing
            modify!(panel_info, "$(sg_col_prefix)__scale__3__" => byrow(x->type3 == :point ? max(length(x)-1, 1) : length(x))=> "$(sg_col_prefix)____temp4353465464_3")
        end
        if type4 !== nothing
            modify!(panel_info, "$(sg_col_prefix)__scale__4__" => byrow(x -> type4 == :point ? max(length(x) - 1, 1) : length(x)) => "$(sg_col_prefix)____temp4353465464_4")
        end
        modify!(panel_info, r"____temp4353465464_"  => byrow(maximum) => "$(sg_col_prefix)height_step", ["$(sg_col_prefix)height_step", "$(sg_col_prefix)y_step_size"] => byrow(prod) => "$(sg_col_prefix)height")
        select!(panel_info, Not(r"____temp4353465464_"))

    
    else
        insertcols!(panel_info, "$(sg_col_prefix)height" => all_args.opts[:height])
        # map!(panel_info,x->false, :y_step)
    end
end
function _find_width_proportion!(panel_info, all_args)
    if all_args.opts[:proportional] && all_args.opts[:linkaxis] == :y
        #check we both scale 3 and 4 are discrete
        !all(all_args.scale_type[1:2] .∈ Ref([nothing, :band, :point, :discrete])) && throw(ArgumentError("propertional keyword argument only supported for discrete type axes"))
        type1 = all_args.scale_type[1]
        type2 = all_args.scale_type[2]
        # band has half of step on each side of axis
        max1 = type1 === nothing ? 0 : type1 == :point ? max(1, maximum(length, panel_info[:, "$(sg_col_prefix)__scale__1__"]) - 1) : maximum(length, panel_info[:, "$(sg_col_prefix)__scale__1__"])
        max2 = type2 === nothing ? 0 : type2 == :point ? max(1, maximum(length, panel_info[:, "$(sg_col_prefix)__scale__2__"]) - 1) : maximum(length, panel_info[:, "$(sg_col_prefix)__scale__2__"])
        max_length = max(max1, max2)
        # if stepsize is not given we should calculate it
        if all_args.opts[:stepsize] === nothing
            stepsize = Int(ceil(all_args.opts[:width] / max_length))
        else
            stepsize = all_args.opts[:stepsize]
        end
        map!(panel_info,x->true, "$(sg_col_prefix)x_step")
        insertcols!(panel_info, "$(sg_col_prefix)x_step_size" => stepsize)
        # modify!(panel_info, colname .=> byrow(length) .=> ["____temp4353465464_$i" for i in colname], ["____temp4353465464_$i" for i in colname] => byrow(max) => :width_step, [:width_step, :x_step_size] => byrow(prod) => :width)
        if type1 !== nothing
            modify!(panel_info, "$(sg_col_prefix)__scale__1__" => byrow(x -> type1 == :point ? max(length(x) - 1, 1) : length(x)) => "$(sg_col_prefix)____temp4353465464_1")
        end
        if type2 !== nothing
            modify!(panel_info, "$(sg_col_prefix)__scale__2__" => byrow(x -> type2 == :point ? max(length(x) - 1, 1) : length(x)) => "____temp4353465464_2")
        end
        modify!(panel_info, r"____temp4353465464_" => byrow(maximum) => "$(sg_col_prefix)width_step", ["$(sg_col_prefix)width_step", "$(sg_col_prefix)x_step_size"] => byrow(prod) => "$(sg_col_prefix)width")
        select!(panel_info, Not(r"____temp4353465464_"))
    
    else
        insertcols!(panel_info, "$(sg_col_prefix)width" => all_args.opts[:width])
        # map!(panel_info, x->false, :x_step)
    end
end

function _how_to_print(nt, colname; idx = nothing)
    k = keys(nt)
    val = values(nt)
    if colname
        if idx === nothing
            join(string.(k, "=", val), ", ")
        else
            string(k[idx], "=", val[idx])
        end
    else
        if idx === nothing
            join(string.(val), ", ")
        else
            string(val[idx])
        end
    end
end


function _add_title_for_panel!(newmark, info, all_args, all_axes)
    the_existing_orients = [haskey(IMD.index(info), "$(sg_col_prefix)cell_title_$(orient)")  for orient in [:top, :bottom, :left, :right]]
    
    
    for orient in [:top, :bottom, :left, :right][the_existing_orients]
        if orient in (:top, :bottom)
            _range = [0, info["$(sg_col_prefix)width"]]
            _limit=info["$(sg_col_prefix)width"]
        else 
            _range = [info["$(sg_col_prefix)height"],0]
            _limit=info["$(sg_col_prefix)height"]
        end
        ismissing(info["$(sg_col_prefix)cell_title_$(orient)"]) && continue


        _font = something(all_args.opts[:headerfont], all_args.opts[:font])
        _fweight = something(all_args.opts[:headerfontweight], all_args.opts[:fontweight])
        _fitalic = something(all_args.opts[:headeritalic], all_args.opts[:italic])

        dummy_scale = Dict{Symbol, Any}(:name=>"title_panel_scale_$(orient)", :range=>_range)
        dummy_axis = Dict{Symbol, Any}(:ticks => false,
                                   :labels=>false,
                                   :domain=>false,
                                   :scale => "title_panel_scale_$(orient)",
                                   :orient => orient,
                                   :title=> info["$(sg_col_prefix)cell_title_$(orient)"],
                                   :titleFontSize=>all_args.opts[:headersize],
                                   :titleFont=>_font,
                                   :titleFontStyle=>_fitalic ? "italic" : "normal",
                                   :titleFontWeight=>_fweight,
                                   :titlePadding=>orient in (:top, :bottom) ? all_args.opts[:headeroffset][1] : all_args.opts[:headeroffset][2])
        if all_args.opts[:headerangle] !== nothing
            dummy_axis[:titleAngle] = all_args.opts[:headerangle]
        else
            dummy_axis[:titleLimit] = _limit
        end
        if all_args.opts[:headerbaseline] !== nothing
            dummy_axis[:titleBaseline] = all_args.opts[:headerbaseline]
        end
        if all_args.opts[:headeralign] !== nothing
            dummy_axis[:titleAlign] = all_args.opts[:headeralign]
        end
        if all_args.opts[:headercolor] !== nothing
            dummy_axis[:titleColor] = all_args.opts[:headercolor]
        end
        if all_args.opts[:headerloc] !== nothing
            dummy_axis[:titleAnchor] = all_args.opts[:headerloc]
        end

        push!(newmark[:scales], dummy_scale)
        push!(newmark[:axes], dummy_axis)
    end
   
end
# we cannot use title marks for this, because we need to be able to add title to more than one orient
# so we create dummy scale and dummy axes for the outer group mark
function _add_axes_title_for_lattice!(inmk, panel_info, vspec, all_args)
    arg_max_width = argmax(panel_info[:, "$(sg_col_prefix)x"])
    _width = panel_info[arg_max_width, "$(sg_col_prefix)x"] + panel_info[arg_max_width, "$(sg_col_prefix)width"]
    arg_max_height = argmax(panel_info[:, "$(sg_col_prefix)y"])
    _height = panel_info[arg_max_height, "$(sg_col_prefix)y"] + panel_info[arg_max_height, "$(sg_col_prefix)height"]

    inmk[:scales] = Dict{Symbol, Any}[]
    inmk[:axes] = Dict{Symbol, Any}[]

    _titles = Any[nothing, nothing, nothing, nothing]
    for ax in vspec[:axes]
        if haskey(ax, :scale) && haskey(ax, :title)
            _titles[findfirst(isequal(ax[:scale]), ["x1", "x2", "y1", "y2"])] = ax[:title]
        end
    end

            
    push!(inmk[:scales], Dict{Symbol, Any}(:name => "xax", :range => [0, _width]))
    push!(inmk[:scales], Dict{Symbol, Any}(:name => "yax", :range => [_height, 0]))
    for i in 1:4
        _titles[i] === nothing && continue

        new_axis_mark = Dict{Symbol, Any}()
        new_axis_mark[:orient] = [:bottom, :top, :left, :right][i]
        new_axis_mark[:scale] = i < 3 ? "xax" : "yax"
        new_axis_mark[:labels] = false
        new_axis_mark[:ticks] = false
        new_axis_mark[:domain] = false
        new_axis_mark[:offset] = i == 1  ? _height : i == 4 ? _width : 0
        new_axis_mark[:offset] += 30
        new_axis_mark[:title] = _titles[i]

        #find the right axis and copy title style
        index_of_ax = findfirst(x-> isequal(x[:scale], ["x1", "x2", "y1", "y2"][i]), vspec[:axes])
        for prop in [:titleFont, :titleColor, :titleAngle, :titleBaseline, :titleAnchor, :titleAlign, :titleX, :titleY, :titleFontSize, :titleFontWeight, :titleFontStyle, :titlePadding]
            if haskey(vspec[:axes][index_of_ax], prop)
                new_axis_mark[prop] = vspec[:axes][index_of_ax][prop]
            end
        end
        push!(inmk[:axes], new_axis_mark)

    end
end

function _addjitter(x)
    "random()*$(x)-$(x/2)"
end
