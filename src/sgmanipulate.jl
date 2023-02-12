# SGManipulate creates basic interaction
mutable struct SGManipulate
    json_spec
end

# include default value for global sgpanel specification
SGMANIPULATE_DEFAULT = Dict(
        :font=>"sans-serif",
        :width=>600,
        :height=>400,
        
        :panelborder => true,
        :panelbordercolor=>"gray",
        :panelborderthickness=>0.1, 
      
        :groupcolormodel => "category", #default color model for group scale

        :backcolor => :white, # the background color for the whole graph area
        :wallcolor => :transparent, # the background of the plot area / or panel area

        :rangetype=>nothing, # user can pass the name of columns which are forced to be treated as range input

        :showheaders => false,
        :headercolname=>true,

        :headersize => 10,
        :headerfontweight=>nothing,
        :headeritalic=>nothing,
        :headerfont=>nothing,
        :headerangle=>nothing,
        :headerbaseline=>nothing,
        :headeralign=>nothing,
        :headercolor=>nothing,
        :headerloc=>nothing,
        
        :headerorient=>:top, # :top, :bottom, :left, :right,/ for lattice :topleft, :topright, :bottomleft, :bottomright
        :headeroffset=>[0,0], # [top/bottom, left/right]

        # the global font specification
        :font => "sans-serif",
        :italic=>false,
        :fontweight=>400,

        :filtertype=> "==", # NOTE: it is useful only for cases where the whole data are sent to vega - other possible values "<=","<",">=",">" - the data are filtered based on this

        :clip=>true
        )


function _sgmanipulate(ds, panelby::IMD.MultiColumnIndex, plts::Vector{<:SGMarks}; mapformats=true, nominal::Union{Nothing,IMD.ColumnIndex,IMD.MultiColumnIndex}=nothing, xaxis=Axis(), x2axis=Axis(), yaxis=Axis(), y2axis=Axis(), legend::Union{Bool,Legend,Vector{Legend}}=true, threads=nrow(ds) > 10^6, opts...)
    IMD._get_fmt(ds) != mapformats && throw(ArgumentError("the input data set uses mapformats = $(IMD._get_fmt(ds)), but the sgplot is called with mapformats = $(mapformats)"))

    # read opts
    optsd = val_opts(opts)
    global_opts = update_default_opts!(deepcopy(SGMANIPULATE_DEFAULT), optsd)
    global_opts[:layout] = :panel
    global_opts[:columns] = 1
    global_opts[:rows] = 1
    global_opts[:proportional] = false
    global_opts[:rowspace] = 0
    global_opts[:columnspace] = 0
    
    if !(global_opts[:headeroffset] isa AbstractVector)
        global_opts[:headeroffset] = [global_opts[:headeroffset], global_opts[:headeroffset]]
    end

    starts_of_each_group = view(IMD._get_perms(ds), view(IMD._group_starts(ds), 1:IMD._ngroups(ds)))
    ds = parent(ds)
    first_unique = ds[starts_of_each_group, panelby]

    panelby = names(ds)[IMD.index(ds)[panelby]]
    
    panel_info = unique(first_unique[!, IMD.index(first_unique)[panelby]], mapformats=mapformats, threads=threads)
    
    ncol(panel_info) == 0  && throw(ArgumentError("at least one group of observations is needed"))

    rangetype = String[]
    if global_opts[:rangetype] !== nothing
        rangetype=names(ds, global_opts[:rangetype])
    end
    binds = _sgmanipulate_bindings(panel_info, mapformats, rangetype)


    # add a column to panel_info to make sure there is at least one column
    # for joining data sets, i.e. we will left join scale, panel dimensions, ... to panel_info
    insertcols!(panel_info, 1, "$(sg_col_prefix)__dummy_column_for_join__" => true)

    # for :lattice, :row and :column layout we allow row or column scales be independent
   
    uniscale_col = nothing
    independent_axes = Int[]
   

    # we can run sgplot to get information about the scale for each panel
    scale_ds = [Dataset("$(sg_col_prefix)__scale_col__" => Any[]), Dataset("$(sg_col_prefix)__scale_col__" => Any[]), Dataset("$(sg_col_prefix)__scale_col__" => Any[]), Dataset("$(sg_col_prefix)__scale_col__" => Any[])]
    referred_cols_in_ds = Int[]
    scale_type = Any[nothing, nothing, nothing, nothing]
    all_args = SGPlot_Args(ds, scale_ds, scale_type, referred_cols_in_ds, plts, [xaxis, x2axis, yaxis, y2axis], legend isa Legend ? [legend] : legend, Dict{Symbol,Any}[], mapformats, nominal, threads, names(ds)[IMD.index(ds)[panelby]], IMD.index(ds)[panelby], uniscale_col, independent_axes, global_opts)


    sgplot_result = _sgplot!(all_args).json_spec
    add_dummy_col!(all_args)
    add_filters_sgmanipulate!(panel_info, all_args; filtertype=global_opts[:filtertype])
    add_title_panel!(panel_info, all_args)
    join_scale_info!(panel_info, all_args)
    add_height_width_x_y!(panel_info, all_args)
    vspec = Dict{Symbol,Any}()
    vspec[:signals] = Dict{Symbol, Any}[]

    for bind in binds
        push!(vspec[:signals], bind)
    end

    vspec[:background] = global_opts[:backcolor]
    vspec[:data] = Dict{Symbol,Any}[]
    vspec[:scales] = Dict{Symbol,Any}[]
    vspec[:marks] = Dict{Symbol,Any}[]
    # sgpanel_marks = Dict{Symbol,Any}(:marks => Dict{Symbol,Any}[]) # we use the a layer of mark for assigning graph axes labels in the case of lattice type layouts
    # sgpanel_marks[:type] = "group"
    vspec[:axes] = Dict{Symbol,Any}[]
    # if global_opts[:wallcolor] != :transparent
        # create all panel wallcolor before doing anything else. In this way we are sure that wallcolor is at the back of everything
        # for i in 1:nrow(panel_info)
            # newmark = Dict{Symbol,Any}()
    #         newmark[:type] = :group
    #         newmark[:encode] = Dict{Symbol,Any}()
    #         newmark[:encode][:enter] = Dict{Symbol,Any}()
    #         newmark[:encode][:enter][:x] = Dict{Symbol,Any}(:value => panel_info[i, "$(sg_col_prefix)x"])
    #         newmark[:encode][:enter][:y] = Dict{Symbol,Any}(:value => panel_info[i, "$(sg_col_prefix)y"])
    #         newmark[:encode][:enter][:height] = Dict{Symbol,Any}(:value => panel_info[i, "$(sg_col_prefix)height"])
    #         newmark[:encode][:enter][:width] = Dict{Symbol,Any}(:value => panel_info[i, "$(sg_col_prefix)width"])
    #         newmark[:encode][:enter][:fill] = Dict{Symbol, Any}(:value => global_opts[:wallcolor])
    #         push!(sgpanel_marks[:marks], newmark)
    #     end
    # end
    newmark = Dict{Symbol,Any}()
    for i in 1:1
        
        newmark[:type] = :group
        # if all_args.opts[:layout] == :panel && all_args.opts[:showheaders]
        #     newmark[:title] = Dict{Symbol, Any}()
        #     _add_title_for_panel!(newmark, panel_info[i, :], all_args, sgplot_result[:axes])
        # end

        # update "height" and "width" signals within each cell
        newmark[:signals] = Dict{Symbol,Any}[]
        push!(newmark[:signals], Dict{Symbol,Any}(:name => "height", :update => string(panel_info[i, "$(sg_col_prefix)height"])))
        push!(newmark[:signals], Dict{Symbol,Any}(:name => "width", :update => string(panel_info[i, "$(sg_col_prefix)width"])))

        newmark[:encode] = Dict{Symbol,Any}()
        newmark[:encode][:enter] = Dict{Symbol,Any}()
        newmark[:encode][:enter][:x] = Dict{Symbol,Any}(:value => panel_info[i, "$(sg_col_prefix)x"])
        newmark[:encode][:enter][:y] = Dict{Symbol,Any}(:value => panel_info[i, "$(sg_col_prefix)y"])
        newmark[:encode][:enter][:height] = Dict{Symbol,Any}(:value => panel_info[i, "$(sg_col_prefix)height"])
        newmark[:encode][:enter][:width] = Dict{Symbol,Any}(:value => panel_info[i, "$(sg_col_prefix)width"])
        # we create a separate group for each panel and apply wallcolor there
        # if global_opts[:wallcolor] != :transparent
        #     newmark[:encode][:enter][:fill] = Dict{Symbol, Any}(:value => global_opts[:wallcolor])
        # end

        if all_args.opts[:panelborder]
            newmark[:encode][:enter][:stroke] = Dict{Symbol,Any}(:value => all_args.opts[:panelbordercolor])
            newmark[:encode][:enter][:strokeWidth] = Dict{Symbol,Any}(:value => all_args.opts[:panelborderthickness])

        end

        newmark[:marks] = deepcopy(sgplot_result[:marks])
        new_scales = _modify_scales_for_panel(deepcopy(sgplot_result[:scales]), panel_info[i, :])
        newmark[:scales] = new_scales[1:4]
        append!(newmark[:scales], filter(x->contains(x[:name], "fixed_radius_"), new_scales)) # pie chart used fixed_radius_ pattern
        # new_axes = _modify_axes_for_panel(all_args, deepcopy(sgplot_result[:axes]), panel_info[i, :])
        newmark[:axes] = deepcopy(sgplot_result[:axes])

        # put panel or lattice headers
        if all_args.opts[:showheaders]
            _add_title_for_sgmanipulate!(newmark, panel_info[i, :], all_args, sgplot_result[:axes])
        end
        # i is send to create unique name for filtered data
        _modify_data_for_panel!(vspec, newmark[:marks], panel_info[i, :], i)
        # push!(sgpanel_marks[:marks], newmark)
    end

   
    push!(vspec[:marks], newmark)
    if length(sgplot_result[:scales]) > 4
        vspec[:scales] = sgplot_result[:scales][5:end]
    end
    vspec[:legends] = sgplot_result[:legends]
    vspec[Symbol("\$schema")] = "https://vega.github.io/schema/vega/v5.json"
    prepend!(vspec[:data], sgplot_result[:data])

    arg_max_width = argmin(panel_info[:, "$(sg_col_prefix)x"])
    _width = panel_info[arg_max_width, "$(sg_col_prefix)x"] + panel_info[arg_max_width, "$(sg_col_prefix)width"]
    arg_max_height = argmin(panel_info[:, "$(sg_col_prefix)y"])
    _height = panel_info[arg_max_height, "$(sg_col_prefix)y"] + panel_info[arg_max_height, "$(sg_col_prefix)height"]

    vspec[:width] = _width
    vspec[:height] = _height

    SGManipulate(vspec)
end

function sgmanipulate(ds::Union{AbstractDataset, IMD.GroupBy, IMD.GatherBy}, plts::Vector{<:SGMarks}; mapformats=true, nominal::Union{Nothing,IMD.ColumnIndex, IMD.MultiColumnIndex}=nothing, xaxis=Axis(), x2axis=Axis(), yaxis=Axis(), y2axis=Axis(), legend::Union{Bool, Legend, Vector{Legend}}=true, threads=nrow(ds) > 10^6, opts...)
    
    nominal_tmp = String[]
    if nominal !== nothing
        if nominal isa IMD.ColumnIndex
            nominal = [nominal]
        end
        _all_names = names(ds)[IMD.index(ds)[nominal]]
        for col in _all_names
            push!(nominal_tmp, col)
        end
    end
    nominal = copy(nominal_tmp)
    for col in names(ds)
        _f = identity
        if mapformats
            _f = getformat(ds, col)
        end
        # strings and pooled array are assumed to be nominal
        # TODO user may want to use pa as a quantitative column, and we do not allow this here
        if Core.Compiler.return_type(_f, Tuple{eltype(parent(ds)[!,col])}) <: Union{<:AbstractString, Missing, <: AbstractChar} || IMD.DataAPI.refpool(parent(ds)[!, col]) !== nothing
            push!(nominal, col)
        end
    end 
    
    unique!(nominal)

    if !(nominal isa AbstractVector)
        nominal = [nominal]
    end
    if ds isa IMD.GroupBy || ds isa IMD.GatherBy || IMD.isgrouped(ds)
        _sgmanipulate(ds, IMD._groupcols(ds), plts ; mapformats = mapformats, nominal = nominal, xaxis = xaxis, x2axis = x2axis, yaxis=yaxis, y2axis = y2axis, legend = legend, threads = threads, opts...)
    end
end

sgmanipulate(ds, plt::SGMarks; args...) = sgmanipulate(ds, [plt]; args...)
