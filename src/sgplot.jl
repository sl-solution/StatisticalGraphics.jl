# abstract type which includes every type of plots
abstract type SGPlots end

# SGPlot is a single multi layer plot
mutable struct SGPlot <: SGPlots
    json_spec
    scale_ds::Vector{Dataset}
end

mutable struct SGPlot_Args
    ds
    scale_ds::Vector{Dataset}
    scale_type::Vector{Any}
    referred_cols::Vector{Int}
    plts::Vector
    axes::Vector{Axis}
    legends::Union{Bool, Vector{Legend}}
    out_legends::Vector{Dict{Symbol, Any}}
    mapformats::Bool
    nominal::Vector{String}
    threads::Bool
    panelby::Vector{String} # panelby column names / _extra_col_for_panel are column index - TODO _extra_col_for_panel is redundant
    _extra_col_for_panel::Vector{Int} # do computation for each panel
    uniscale_col # if uniscal is needed the scale data set must be ready
    independent_axes::Vector{Int} # one of [1,2], [3,4], [] - i.e. x axes are independent, y axes are independent, none are independent
    opts
end

# include default value for global sgplot specification
SGPLOT_DEFAULT = Dict(:width => 600,
                      :height => 400,
                      
                      # the global font specification
                      :font => "sans-serif",
                      :italic=>false,
                      :fontweight=>400,

                      :groupcolormodel => "category",
                      :autolegend => true
                      )

function sgplot(ds::Union{AbstractDataset, IMD.GroupBy, IMD.GatherBy}, plts::Vector{<:SGMarks}; mapformats=true, nominal::Union{Nothing,IMD.ColumnIndex, IMD.MultiColumnIndex}=nothing, xaxis=Axis(), x2axis=Axis(), yaxis=Axis(), y2axis=Axis(), legend::Union{Bool, Legend, Vector{Legend}}=true, threads=nrow(ds) > 10^6, opts...)
    if nominal === nothing
        nominal = String[]
    else
        nominal = names(ds)[IMD.index(ds)[nominal]]
    end
    if !(nominal isa AbstractVector)
        nominal = [nominal]
    end
    if ds isa AbstractDataset && !IMD.isgrouped(ds)
        _sgplot(ds, plts; mapformats = mapformats, nominal = nominal, xaxis = xaxis, x2axis = x2axis, yaxis=yaxis, y2axis = y2axis, legend = legend, threads = threads, opts...)
    else
        _sgpanel(ds, IMD._groupcols(ds), plts ; mapformats = mapformats, nominal = nominal, xaxis = xaxis, x2axis = x2axis, yaxis=yaxis, y2axis = y2axis, legend = legend, threads = threads, opts...)
    end
end


# generate the plot specification based on passed argument
function _sgplot(ds::AbstractDataset, plts::Vector{<:SGMarks}; mapformats=true, nominal::Union{Nothing,IMD.MultiColumnIndex}=nothing, xaxis=Axis(), x2axis=Axis(), yaxis=Axis(), y2axis=Axis(), legend::Union{Bool, Legend, Vector{Legend}}=true, threads=nrow(ds) > 10^6, opts...)
    

    # read opts
    optsd = val_opts(opts)
    global_opts = update_default_opts!(deepcopy(SGPLOT_DEFAULT), optsd)
    
    scale_ds = [Dataset("$(sg_col_prefix)__scale_col__"=>Any[]), Dataset("$(sg_col_prefix)__scale_col__"=>Any[]), Dataset("$(sg_col_prefix)__scale_col__"=>Any[]), Dataset("$(sg_col_prefix)__scale_col__"=>Any[])]
    # some type of plots will produce new data sets - we put all of them in out_ds
    # referred_cols_in_ds used to track which columns of input ds should be written in vspec
    referred_cols_in_ds = Int[]
    scale_type = Any[nothing, nothing, nothing, nothing]
    all_args = SGPlot_Args(ds, scale_ds, scale_type, referred_cols_in_ds, plts, [xaxis, x2axis, yaxis, y2axis], legend isa Legend ? [legend] : legend, Dict{Symbol, Any}[], mapformats, nominal, threads, String[], Int[], nothing, Int[], global_opts)
    # vspec is a dictionary which holds the specification of the passed plots
    # vspec will be passed around to be updated
   _sgplot!(all_args)
end


function _sgplot!(all_args)

    global_opts = all_args.opts
    plts = all_args.plts
    referred_cols_in_ds = all_args.referred_cols
    # apply fontstyling for axes
    _apply_fontstyling_for_axes!(all_args.axes, all_args)
    xaxis = all_args.axes[1]
    x2axis = all_args.axes[2]
    yaxis = all_args.axes[3]
    y2axis = all_args.axes[4]
    _extra_col_for_panel = all_args._extra_col_for_panel
    mapformats = all_args.mapformats

    ds = all_args.ds

    vspec = Dict{Symbol,Any}()


    # add sgplot global specification
    # every specification must be hard code - since we are not going to use the default names of options in vega/ we are using our own naming convention
    vspec[:width] = global_opts[:width]
    vspec[:height] = global_opts[:height]
    vspec[Symbol("\$schema")] = "https://vega.github.io/schema/vega/v5.json"


    # add vspec components - later we modify them accordingly
    vspec[:marks] = Dict{Symbol,Any}[]
    vspec[:data] = Dict{Symbol,Any}[]
    vspec[:scales] = Dict{Symbol,Any}[]
    vspec[:legends] = Dict{Symbol, Any}[]
    # push all possible scales
    push!(vspec[:scales], Dict{Symbol,Any}(:name => "x1", :range => "width"))             #1
    push!(vspec[:scales], Dict{Symbol,Any}(:name => "x2", :range => "width"))             #2
    push!(vspec[:scales], Dict{Symbol,Any}(:name => "y1", :range => "height"))             #3
    push!(vspec[:scales], Dict{Symbol,Any}(:name => "y2", :range => "height"))             #4
    push!(vspec[:scales], Dict{Symbol,Any}(:name => "group_scale"))                                        #5

    vspec[:axes] = Dict{Symbol,Any}[]
    # push all 4 axes
    push!(vspec[:axes], Dict{Symbol,Any}(:scale => "x1", :orient => "bottom", :title => xaxis.opts[:title]))
    push!(vspec[:axes], Dict{Symbol,Any}(:scale => "x2", :orient => "top", :title => x2axis.opts[:title]))
    push!(vspec[:axes], Dict{Symbol,Any}(:scale => "y1", :orient => "left", :title => yaxis.opts[:title]))
    push!(vspec[:axes], Dict{Symbol,Any}(:scale => "y2", :orient => "right", :title => y2axis.opts[:title]))


    # vspec[:signals] = Dict{Symbol, Any}[]
    # vspec[:transform] = Dict{Symbol, Any}[]

    for i in eachindex(plts)
        # we hard code _push_plots! for each type of plots
        _push_plots!(vspec, plts[i], all_args; idx=i)
    end
    # summarise scales data set and create vega scales
    _fill_scales!(vspec, all_args)

    if !isempty(referred_cols_in_ds)
        append!(referred_cols_in_ds, _extra_col_for_panel)
        data_csv = tempname()
        filewriter(data_csv, ds[!, unique(referred_cols_in_ds)], mapformats=mapformats, quotechar='"')
        # use parse=:auto for letting vega guess the data type
        main_data = Dict{Symbol,Any}(:name => "source_0", :values => read(data_csv, String), :format => Dict{Symbol,Any}(:type => "csv", :delimiter => ",", :parse => :auto))

        prepend!(vspec[:data], [main_data])

    end

    # remove unused axes
    filter!(x -> haskey(x, :domain), vspec[:axes])
    for ax in vspec[:axes]
        # if user pass title="" in axis then we remove :title from axis
        if haskey(ax, :title) && ax[:title] !== nothing && isempty(ax[:title])
            delete!(ax, :title)
        end
    end

    if isequal(all_args.legends, true) || all_args.legends isa Vector
        user_passed_legend = count(x->!startswith(x[:name], "__internal__name__for__legend__"), all_args.out_legends)
        if user_passed_legend > 0
            filter!(x->!startswith(x[:name], "__internal__name__for__legend__"), all_args.out_legends)
            for leg in all_args.out_legends
                delete!(leg, :name)
                push!(vspec[:legends], leg)
            end
        else # we only select the first legend to show
            if !isempty(all_args.out_legends)
                delete!(all_args.out_legends[1], :name)
                push!(vspec[:legends], all_args.out_legends[1])
            end
        end
    end
    SGPlot(vspec, all_args.scale_ds)
end

sgplot(ds, plt::SGMarks; args...) = sgplot(ds, [plt]; args...)

function Base.show(io::IO, vspec::SGPlot)
    out_html = tempname() * ".html"
    html_out = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Embedding Vega-Lite</title>
        <script src="https://cdn.jsdelivr.net/npm/vega@5"></script>
        <script src="https://cdn.jsdelivr.net/npm/vega-lite@5"></script>
        <script src="https://cdn.jsdelivr.net/npm/vega-embed@6"></script>
    </head>
    <body>
        <div id="vis"></div>

        <script>
        var spec = $(json(vspec.json_spec));
        vegaEmbed('#vis', spec);
        </script>
    </body>
    </html>
    """
    write(out_html, html_out)
    launch_browser(out_html)
    nothing
end
