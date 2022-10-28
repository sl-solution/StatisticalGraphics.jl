LEGEND_DEFAULT = Dict{Symbol, Any}(
                                 :name => nothing, #user can use this to modify a specific legend
                                 :title => nothing, # automatically assign this if user did not provide any value
                                 :orient => :right, # default location of the legend
                                 :symbol=>nothing,
                                 :columns=>1,
                                 :direction=>:vertical,
                                 :size => 100,
                                 :gridalign=>:each, # :each, :all
                                 :rowspace => 1, 
                                 :columnspace=>1,
                                 :values=>nothing, # allow manually insert values

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
        new(cp_LEGEND_DEFAULT)
    end
end
