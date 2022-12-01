# SGPanel puts multiple SGPlot in a panel like layout
mutable struct SGPanel <: SGPlots
    json_spec
end

# include default value for global sgpanel specification
SGPANEL_DEFAULT = Dict(:layout=>:panel, # it can be :panel, :lattice - panel should support arbitrary number of grouping variables, however, lattice supports max of two grouping variables - we also support :row and :column for one classification column
        :proportional=>false, # for lattice with discrete scale
        :columns=>2, # number of columns
        :rows=>nothing, # number of rows
        :linkaxis=>:both, # how to resolve the row and column axes' scales - :both, :x, :y
        :font=>"sans-serif",
        :width=>400,
        :height=>400,
        :stepsize=>nothing,
        :panelborder => true,
        :panelbordercolor=>"gray",
        :panelborderthickness=>0.1, 
        :rowspace => 30,
        :columnspace => 30,
        :groupcolormodel => "category", #default color model for groupspace

        :backcolor => :transparent, # the background color for the whole graph area
        :wallcolor => :transparent, # the background of the plot area / or panel area


        :showheaders => true,
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
        
        :headerorient=>nothing, # :top, :bottom, :left, :right,/ for lattice :topleft, :topright, :bottomleft, :bottomright
        :headeroffset=>[0,0], # [top/bottom, left/right]

        # the global font specification
        :font => "sans-serif",
        :italic=>false,
        :fontweight=>400,

        :clip=>true
        )


function _sgpanel(ds, panelby::IMD.MultiColumnIndex, plts::Vector{<:SGMarks}; mapformats=true, nominal::Union{Nothing,IMD.ColumnIndex,IMD.MultiColumnIndex}=nothing, xaxis=Axis(), x2axis=Axis(), yaxis=Axis(), y2axis=Axis(), legend::Union{Bool,Legend,Vector{Legend}}=true, threads=nrow(ds) > 10^6, opts...)
    IMD._get_fmt(ds) != mapformats && throw(ArgumentError("the input data set uses mapformats = $(IMD._get_fmt(ds)), but the sgplot is called with mapformats = $(mapformats)"))

    # read opts
    optsd = val_opts(opts)
    global_opts = update_default_opts!(deepcopy(SGPANEL_DEFAULT), optsd)
    if global_opts[:layout] == :lattice
        if global_opts[:headerorient] === nothing
            global_opts[:headerorient] = :topright
        else
            !(global_opts[:headerorient] in (:topleft, :topright, :bottomleft, :bottomright)) && throw(ArgumentError("for :lattice layout the headerorient keyword must be one of (:topleft, :topright, :bottomleft, :bottomright)"))
        end
    elseif global_opts[:layout] == :column
        if global_opts[:headerorient] === nothing
            global_opts[:headerorient] = :right 
        else
            !(global_opts[:headerorient] in (:top, :bottom, :right, :left)) && throw(ArgumentError("for :column layout the headerorient keyword must be one of (:top, :bottom, :right, :left)"))
        end
    elseif global_opts[:layout] in (:row, :panel)
        if global_opts[:headerorient] === nothing
            global_opts[:headerorient] = :top 
        else
            !(global_opts[:headerorient] in (:top, :bottom, :right, :left)) && throw(ArgumentError("for :panel or :row layout the headerorient must be one of (:top, :bottom, :right, :left)"))
        end
    else
        throw(ArgumentError("layout is unknown"))
    end
    if !(global_opts[:headeroffset] isa AbstractVector)
        global_opts[:headeroffset] = [global_opts[:headeroffset], global_opts[:headeroffset]]
    end

    starts_of_each_group = view(IMD._get_perms(ds), view(IMD._group_starts(ds), 1:IMD._ngroups(ds)))
    ds = parent(ds)
    first_unique = ds[starts_of_each_group, panelby]

    panelby = names(ds)[IMD.index(ds)[panelby]]
    if global_opts[:layout] == :lattice
        length(panelby) != 2 && throw(ArgumentError(":lattice layout needs exactly two classification columns"))
        columns_id = unique(first_unique[!, [panelby[2]]], mapformats=mapformats, threads=threads)
        rows_id = unique(first_unique[!, [panelby[1]]], mapformats=mapformats, threads=threads)
        panel_info = _crossprod(rows_id, columns_id)
    elseif global_opts[:layout] == :panel
        panel_info = unique(first_unique[!, IMD.index(first_unique)[panelby]], mapformats=mapformats, threads=threads)
    else
        panel_info = unique(first_unique[!, panelby], mapformats=mapformats, threads=threads)
    end



    # add a column to panel_info to make sure there is at least one column
    # for joining data sets, i.e. we will left join scale, panel dimensions, ... to panel_info
    insertcols!(panel_info, 1, "$(sg_col_prefix)__dummy_column_for_join__" => true)

    # for :lattice, :row and :column layout we allow row or column scales be independent
    if global_opts[:layout] == :panel && global_opts[:linkaxis] != :both
        throw(ArgumentError("having independent axis for panel layout is not allowed"))
    end
    uniscale_col = nothing
    if global_opts[:linkaxis] == :y && global_opts[:layout] != :panel
        uniscale_col = panelby[1]
        independent_axes = [1, 2]
    elseif global_opts[:linkaxis] == :x && global_opts[:layout] != :panel
        uniscale_col = length(panelby) == 2 ? panelby[2] : panelby[1]
        independent_axes = [3, 4]
    else
        uniscale_col = nothing
        independent_axes = Int[]
    end


    # we can run sgplot to get information about the scale for each panel
    scale_ds = [Dataset("$(sg_col_prefix)__scale_col__" => Any[]), Dataset("$(sg_col_prefix)__scale_col__" => Any[]), Dataset("$(sg_col_prefix)__scale_col__" => Any[]), Dataset("$(sg_col_prefix)__scale_col__" => Any[])]
    referred_cols_in_ds = Int[]
    scale_type = Any[nothing, nothing, nothing, nothing]
    all_args = SGPlot_Args(ds, scale_ds, scale_type, referred_cols_in_ds, plts, [xaxis, x2axis, yaxis, y2axis], legend isa Legend ? [legend] : legend, Dict{Symbol,Any}[], mapformats, nominal, threads, names(ds)[IMD.index(ds)[panelby]], IMD.index(ds)[panelby], uniscale_col, independent_axes, global_opts)


    sgplot_result = _sgplot!(all_args).json_spec
    add_dummy_col!(all_args)
    add_filters!(panel_info, all_args)
    add_title_panel!(panel_info, all_args)
    join_scale_info!(panel_info, all_args)
    add_height_width_x_y!(panel_info, all_args)
    vspec = Dict{Symbol,Any}()
    vspec[:background] = global_opts[:backcolor]
    vspec[:data] = Dict{Symbol,Any}[]
    # vspec[:scales] = Dict{Symbol,Any}[]
    vspec[:marks] = Dict{Symbol,Any}[]
    sgpanel_marks = Dict{Symbol,Any}(:marks => Dict{Symbol,Any}[]) # we use the a layer of mark for assigning graph axes labels in the case of lattice type layouts
    sgpanel_marks[:type] = "group"
    # vspec[:axes] = Dict{Symbol,Any}[]
    if global_opts[:wallcolor] != :transparent
        # create all panel wallcolor before doing anything else. In this way we are sure that wallcolor is at the back of everything
        for i in 1:nrow(panel_info)
            newmark = Dict{Symbol,Any}()
            newmark[:type] = :group
            newmark[:encode] = Dict{Symbol,Any}()
            newmark[:encode][:enter] = Dict{Symbol,Any}()
            newmark[:encode][:enter][:x] = Dict{Symbol,Any}(:value => panel_info[i, "$(sg_col_prefix)x"])
            newmark[:encode][:enter][:y] = Dict{Symbol,Any}(:value => panel_info[i, "$(sg_col_prefix)y"])
            newmark[:encode][:enter][:height] = Dict{Symbol,Any}(:value => panel_info[i, "$(sg_col_prefix)height"])
            newmark[:encode][:enter][:width] = Dict{Symbol,Any}(:value => panel_info[i, "$(sg_col_prefix)width"])
            newmark[:encode][:enter][:fill] = Dict{Symbol, Any}(:value => global_opts[:wallcolor])
            push!(sgpanel_marks[:marks], newmark)
        end
    end
    for i in 1:nrow(panel_info)
        newmark = Dict{Symbol,Any}()
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
        new_axes = _modify_axes_for_panel(all_args, deepcopy(sgplot_result[:axes]), panel_info[i, :])
        newmark[:axes] = new_axes

        # put panel or lattice headers
        if all_args.opts[:showheaders]
            _add_title_for_panel!(newmark, panel_info[i, :], all_args, sgplot_result[:axes])
        end
        # i is send to create unique name for filtered data
        _modify_data_for_panel!(vspec, newmark[:marks], panel_info[i, :], i)
        push!(sgpanel_marks[:marks], newmark)
    end

    if all_args.opts[:layout] in (:row, :column, :lattice)
    #     # add axes title once for the whole graph
        _add_axes_title_for_lattice!(sgpanel_marks, panel_info, sgplot_result, all_args)
    end

    push!(vspec[:marks], sgpanel_marks)
    if length(sgplot_result[:scales]) > 4
        vspec[:scales] = sgplot_result[:scales][5:end]
    end
    vspec[:legends] = sgplot_result[:legends]
    vspec[Symbol("\$schema")] = "https://vega.github.io/schema/vega/v5.json"
    prepend!(vspec[:data], sgplot_result[:data])

    SGPanel(vspec)
end

