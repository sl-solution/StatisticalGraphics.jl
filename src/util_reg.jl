function sweep!(A::Matrix{T}, k; tolerance=nothing) where {T}
    tolerance = something(tolerance, zero(T))
    p = size(A, 1)
    D = A[k, k]
    if D < tolerance
        A[:, k] .= zero(T)
        A[k, :] .= zero(T)
        return false
    end
    for j in 1:p
        A[k, j] /= D
    end
    for i in 1:p
        B = A[i, k]
        if i != k
            for j in 1:p
                A[i, j] -= B * A[k, j]
            end
        end
        A[i, k] = -B / D

    end
    A[k, k] = inv(D)
    true
end
function _reg_sweep_tolerance(xpx, n)
    css = Vector{Float64}(undef, size(xpx, 1) - 1)
    for i in 2:size(xpx, 1)
        css[i-1] = xpx[i, i] - (xpx[1, i])^2 / n
    end
    replace!(x -> isless(x, 0) ? 1.0 : x, css)
    css .*= 1.4901161193847656e-8 # sqrt(eps(Float64))
    [nothing; css]
end
function _reg_sweep(xpx, xpy, ypy, tols)
    A = Matrix{Float64}(undef, size(xpx, 1) + 1, size(xpx, 1) + 1) # square Matrix
    A[1:end-1, 1:end-1] .= xpx
    A[end, 1:end-1] .= xpy
    A[1:end-1, end] .= xpy
    A[end, end] = ypy
    _s_r = zeros(Bool, size(xpx, 1))
    for i in 1:length(_s_r)
        _s_r[i] = sweep!(A, i, tolerance=tols[i])
    end
    A, sum(_s_r) # A is swept, and sum(_s_r) is dof+n
end