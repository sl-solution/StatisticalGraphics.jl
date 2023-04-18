"""
    Legend(args...)

Represent a Legend with given arguments.

$(print_doc(LEGEND_DEFAULT))
"""
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
