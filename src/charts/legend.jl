LEGEND_DEFAULT = Dict{Symbol, Any}(
                                 :name => nothing, #user can use this to modify a specific legend
                                 :title => nothing, # automatically assign this if user did not provide any value
                                 :orient => :right, # default location of the legend, user can pass [legendX, legendY] directly
                                 :symbol=>nothing,
                                 :columns=>1,
                                 :direction=>:vertical,
                                 :size => 100,
                                 :gradientlength=>nothing,
                                 :gradientthickness=>nothing,
                                 :gridalign=>:each, # :each, :all
                                 :rowspace => 1, 
                                 :columnspace=>1,
                                 :values=>nothing, # allow manually insert values

                                 :limit=>nothing, # number of element to display in legend

                                 :d3format=>nothing,
                                 :d3formattype=>nothing,

                                 :font=>nothing,
                                 :italic=>nothing,
                                 :fontweight=>nothing,
                                 :titlefont=>nothing,
                                 :titleitalic=>nothing,
                                 :titlefontweight=>nothing,
                                 :titlesize=>nothing,
                                 :labelfont=>nothing,
                                 :labelitalic=>nothing,
                                 :labelfontweight=>nothing,
                                 :labelsize=>nothing     
                                )


struct Legend
    opts
    function Legend(; opts...)
        optsd = val_opts(opts)
        cp_LEGEND_DEFAULT = update_default_opts!(deepcopy(LEGEND_DEFAULT), optsd)
        if cp_LEGEND_DEFAULT[:orient] isa Integer
            cp_LEGEND_DEFAULT[:orient] = fill(cp_LEGEND_DEFAULT[:orient], 2)
        end
        new(cp_LEGEND_DEFAULT)
    end
end
