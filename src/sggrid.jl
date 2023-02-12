mutable struct SGGrid <: SGPlots
    json_spec
end
SGGRID_DEFAULT = Dict{Symbol, Any}(:align => :none, # :all, :each, :none
    :columns => nothing,
    :backcolor=>nothing,
    :center=>[false, false], # for row-column
    :bounds=>:full, # :full/:flush see vega docs
    :rowspace=>0,
    :columnspace=>0,
    :bordercolor=>:transparent
)


# sggrid positions a collection of SGPlots within a grid
function sggrid(sgp...; opts...)
    optsd = val_opts(opts)
    global_opts = update_default_opts!(deepcopy(SGGRID_DEFAULT), optsd)
    if global_opts[:center] isa Bool
        global_opts[:center] = fill(global_opts[:center], 2)
    end


    vspec = Dict{Symbol,Any}()
    vspec[:signals] = Dict{Symbol, Any}[] # will contain the binding info
    vspec[:background] = something(global_opts[:backcolor], sgp[1].json_spec[:background])
    vspec[Symbol("\$schema")] = "https://vega.github.io/schema/vega/v5.json"
    vspec[:layout] = Dict{Symbol, Any}(:align => global_opts[:align], 
                                       :center => Dict{Symbol, Any}(:row=>global_opts[:center][1],
                                       :column=>global_opts[:center][2]),
                                       :bounds => global_opts[:bounds],
                                       :padding => Dict{Symbol, Any}(:row=>global_opts[:rowspace],
                                       :column=>global_opts[:columnspace]))
    if global_opts[:columns] !== nothing
        vspec[:layout][:columns] = global_opts[:columns]
    end
    vspec[:marks] = Dict{Symbol, Any}[]

    mks = [:data, :signals, :scales, :legends, :axes, :marks, :layout, :config]

    issgmanipulate = false
    for p in sgp
        !(p isa SGPlots) && !(p isa SGManipulate) && throw(ArgumentError("Only Plots or interactive Graphs can be passed as sggrid arguments"))
        if p isa SGManipulate
            issgmanipulate = true
        end
        spec = Dict{Symbol, Any}()
        spec[:type] = "group"
        spec[:encode] = Dict{Symbol, Any}()
        spec[:encode][:update] = Dict{Symbol, Any}()
        spec[:encode][:update][:stroke] = Dict(:value=>global_opts[:bordercolor])
        for mk in mks
            if haskey(p.json_spec, mk)
                spec[mk] = deepcopy(p.json_spec[mk])
            end
        end
        if !haskey(spec, :signals)
            spec[:signals] = Dict{Symbol, Any}[]
        else
            # we move the binding signals to root and
            # make sure that we remove height and with from current spec
            del_indx = Int[]
            for (i, v) in enumerate(spec[:signals])
                if get(v, :description, "") == "INTERACTION"
                    push!(del_indx, i)
                    # we push bind only if it is not a duplicate
                    if all(x->x[:name] != v[:name], vspec[:signals])
                        push!(vspec[:signals], v)
                    end
                elseif get(v, :name, "") in (:width, :height)
                    push!(del_indx, i)
                end
            end
            deleteat!(spec[:signals], del_indx)
        end
        if haskey(p.json_spec, :width) # p must have :height too
            push!(spec[:signals], Dict{Symbol, Any}(:name=>:width, :value=>p.json_spec[:width]))
            push!(spec[:signals], Dict{Symbol, Any}(:name=>:height, :value=>p.json_spec[:height]))
            spec[:encode][:update][:width] = Dict{Symbol, Any}(:value=>p.json_spec[:width])
            spec[:encode][:update][:height] = Dict{Symbol, Any}(:value=>p.json_spec[:height])
        end
        if haskey(p.json_spec, :config) && haskey(p.json_spec[:config], :group)
            # wallcolor is the only configuration we set - this may need to be revised in future
            spec[:encode][:update][:fill] = Dict{Symbol, Any}(:value => p.json_spec[:config][:group][:fill]) 
        end

        push!(vspec[:marks], spec)
    end
    if issgmanipulate
        SGManipulate(vspec)
    else
        SGGrid(vspec)
    end
end
