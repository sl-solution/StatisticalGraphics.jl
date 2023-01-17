mutable struct SGGrid <: SGPlots
    json_spec
end
SGGRID_DEFAULT = Dict{Symbol, Any}(:align => :none, # :all, :each, :none
    :columns => nothing,
    :backcolor=>nothing
)


# sggrid positions a collection of SGPlots within a grid
function sggrid(sgp::Vector{T}; opts...) where T <: SGPlots
    optsd = val_opts(opts)
    global_opts = update_default_opts!(deepcopy(SGGRID_DEFAULT), optsd)

    vspec = Dict{Symbol,Any}()
    vspec[:background] = something(global_opts[:backcolor], sgp[1].json_spec[:background])
    vspec[Symbol("\$schema")] = "https://vega.github.io/schema/vega/v5.json"
    vspec[:layout] = Dict{Symbol, Any}(:align => global_opts[:align])
    if global_opts[:columns] !== nothing
        vspec[:layout][:columns] = global_opts[:columns]
    end
    vspec[:marks] = Dict{Symbol, Any}[]

    mks = [:data, :signals, :scales, :legends, :axes, :marks, :layout]

    for p in sgp
        spec = Dict{Symbol, Any}()
        spec[:type] = "group"
        for mk in mks
            if haskey(p.json_spec, mk)
                spec[mk] = p.json_spec[mk]
            end
        end
        if !haskey(spec, :signals)
            spec[:signals] = Dict{Symbol, Any}[]
        end
        if haskey(p.json_spec, :width) # p must have :height too
            push!(spec[:signals], Dict{Symbol, Any}(:name=>:width, :value=>p.json_spec[:width]))
            push!(spec[:signals], Dict{Symbol, Any}(:name=>:height, :value=>p.json_spec[:height]))
            spec[:encode] = Dict{Symbol, Any}()
            spec[:encode][:update] = Dict{Symbol, Any}()
            spec[:encode][:update][:width] = Dict{Symbol, Any}(:value=>p.json_spec[:width])
            spec[:encode][:update][:height] = Dict{Symbol, Any}(:value=>p.json_spec[:height])
        end
        push!(vspec[:marks], spec)
    end
    SGGrid(vspec)
end
