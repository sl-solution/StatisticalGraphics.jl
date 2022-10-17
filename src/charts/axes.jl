AXES_DEFAULT = Dict{Symbol, Any}(:type => :linear,
                                 :show => true, # if it is false, domain, ticks, labels and title are set to false
                                 :values => nothing, # manually put ticks
                                 :color => :black,
                               
                                 :reverse=>false,
                                 :order => :data, # we support :ascending, and :descending too
                                 :domain=>true,
                                 :offset => 1,
                                 :grid=>false,
                                 :title => nothing,
                                 :ticks => true,
                                 :ticksize => 5,
                                 :angle => 0,
                                 :baseline=>nothing,
                                 :align => nothing,
                                 :griddash=>[0],
                                 :gridthickness=>0.5,
                                 :gridcolor=>"lightgray",
                                 :tickcount=>nothing,
                                 :nice => true,
                                 :d3format => nothing, # allow users to directly pass an axis format - it must be consistent with d3.format()
                                 :labeloverlap => true,

                                 :font=>nothing,
                                 :italic=>nothing,
                                 :fontweight=>nothing,
                                 :titlefont=>nothing,
                                 :titleitalic=>nothing,
                                 :titlefontweight=>900,
                                 :labelfont=>nothing,
                                 :labelitalic=>nothing,
                                 :labelfontweight=>400,                             
                                )


struct Axis
    opts
    function Axis(; opts...)
        optsd = val_opts(opts)
        cp_AXES_DEFAULT = update_default_opts!(deepcopy(AXES_DEFAULT), optsd)
        # :date and :time are the same
        if cp_AXES_DEFAULT[:type] == :date
            cp_AXES_DEFAULT[:type] = :time
        end
        new(cp_AXES_DEFAULT)
    end
end
