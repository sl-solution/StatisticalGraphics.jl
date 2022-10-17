REFLINE_DEFAULT = Dict{Symbol, Any}(:values => 0,  # the position of refline, it can be a vector of values
                                    :axis => nothing, # which axis should be used to draw refline, :xaxis, :x2axis, :yaxis, :y2axis
                                    :opacity=>1,
                                    :thickness=>1,
                                    :color=>"gray",
                                    :dash=>[0]
                                    )
mutable struct RefLine <: SGMarks
    opts
    function RefLine(;opts...)
        optsd = val_opts(opts)
        cp_REFLINE_DEFAULT = update_default_opts!(deepcopy(REFLINE_DEFAULT), optsd)
        if cp_REFLINE_DEFAULT[:axis] === nothing
            throw(ArgumentError("RefLine needs the axis keyword arguments"))
        end
        new(cp_REFLINE_DEFAULT)
    end
end

# RefLine graphic produce a reference line / if more than one value is passed, the _push_plots! function create one mark for each value
# It requires two keyword arguments; values and axis
# It does not need any data
function _push_plots!(vspec, plt::RefLine, all_args; idx=1)
    
    opts = plt.opts
    if opts[:values] isa AbstractVector
        vals = opts[:values]
    else
        vals = [opts[:values]]
    end

    for val in vals
        s_spec = Dict{Symbol,Any}()
        s_spec[:type] = "rule"
        s_spec[:encode] = Dict{Symbol,Any}()
        s_spec[:encode][:enter] = Dict{Symbol,Any}()
        
        if opts[:axis] in (:xaxis, :x2axis)
            # _convert_values_for_js is needed to properly handle TimeType , Bool, ...
            s_spec[:encode][:enter][:x] = Dict{Symbol, Any}(:scale => opts[:axis] == :xaxis ? "x1" : "x2", :value => _convert_values_for_js(val))
            s_spec[:encode][:enter][:y2] = Dict{Symbol, Any}(:signal => "height")
        elseif opts[:axis] in (:yaxis, :y2axis)
            s_spec[:encode][:enter][:y] = Dict{Symbol, Any}(:scale => opts[:axis] == :yaxis ? "y1" : "y2", :value => _convert_values_for_js(val))
            s_spec[:encode][:enter][:x2] = Dict{Symbol, Any}(:signal => "width")
        end
        s_spec[:encode][:enter][:stroke] = Dict{Symbol, Any}(:value=>opts[:color])
        s_spec[:encode][:enter][:strokeWidth]= Dict{Symbol, Any}(:value=>opts[:thickness])
        s_spec[:encode][:enter][:opacity]= Dict{Symbol, Any}(:value=>opts[:opacity])
        s_spec[:encode][:enter][:strokeDash]= Dict{Symbol, Any}(:value=>opts[:dash])
        push!(vspec[:marks], s_spec)
    end
end

      
        