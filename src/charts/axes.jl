AXES_DEFAULT = Dict{Symbol, Any}(:type => :linear,
                                 :show => true, # if it is false, domain, ticks, labels and title are set to false
                                 :values => nothing, # manually put ticks

                                 :color=>:black, # default color
                                 
                                 :range=>nothing, #manually specifying axis domain - no effect when linkaxis is something rather than :both

                                 :reverse=>false,
                                 :order => :data, # we support :ascending, and :descending too
                                 
                                 :offset => 1,

                                 :domaincolor => nothing,
                                 :domain=>true,
                                 :domainthickness=>1.01, #FIXME probably a bug in safari
                                 :domaindash=>[0],
                                
                                 :title => nothing,
                                 :titlecolor=>nothing,
                                 :titleloc=>:middle, #:middle, :end, :start
                                 :titlealign=>nothing,
                                 :titleangle=>nothing,
                                 :titlebaseline=>nothing,
                                 :titlepos=>nothing, # in the form of [x,y]
                                 :titlesize=>nothing,
                                 :titlepadding=>nothing,

                                 :tickcount=>nothing,
                                 :ticks => true, #due to a bug in vega, setting this to false can cause some issues-workaround ticksize=0
                                 :ticksize => 5,
                                 :tickcolor=>nothing,
                                 :tickthickness=>1.01, #FIXME probably a bug in safari
                                 :tickdash=>[0],


                                 :grid=>false,
                                 :griddash=>[0],
                                 :gridthickness=>0.5,
                                 :gridcolor=>"lightgray",
                                 
                                 :nice => true,
                                 :d3format => nothing, # allow users to directly pass an axis format - it must be consistent with d3.format()
                                 :labeloverlap => true,

                                 :angle => 0,
                                 :baseline=>nothing,
                                 :align => nothing,
                                 :showlabels=>true,
                                 :labelcolor=>nothing,
                                 :labelpadding=>nothing,
                                 :labelsize=>nothing,


                                 :font=>nothing,
                                 :italic=>nothing,
                                 :fontweight=>nothing,
                                 :titlefont=>nothing,
                                 :titleitalic=>nothing,
                                 :titlefontweight=>nothing,
                                 :labelfont=>nothing,
                                 :labelitalic=>nothing,
                                 :labelfontweight=>nothing,    
                                 
                                 :zindex=>0
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
