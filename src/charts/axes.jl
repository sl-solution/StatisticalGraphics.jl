"""
    Axis(args...)

Represent an Axis with given arguments.

$(print_doc(AXES_DEFAULT))
"""
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
