
function savefig(filename::AbstractString, mime::AbstractString, v::SGPlots; s = 1)
    open(filename, "w") do f
        show(f, MIME(mime), v, s=s)
    end
end

function savefig(filename::AbstractString, v::SGPlots; s=1)
    file_ext = lowercase(splitext(filename)[2])
    if file_ext == ".svg"
        mime = "image/svg+xml"
    elseif file_ext == ".pdf"
        mime = "application/pdf"
    elseif file_ext == ".png"
        mime = "image/png"
    else
        throw(ArgumentError("Unknown file type."))
    end

    savefig(filename, mime, v, s=s)
end

"""
    svg(filename::AbstractString, v::SGPlots; s=1)
Save the plot ``v`` as a svg file with name ``filename``.
"""
function svg(filename::AbstractString, v::SGPlots; s=1)
    savefig(filename, "image/svg+xml", v, s=s)
end

"""
    pdf(filename::AbstractString, v::SGPlots; s=1)
Save the plot ``v`` as a pdf file with name ``filename``.
"""
function pdf(filename::AbstractString, v::SGPlots; s=1)
    savefig(filename, "application/pdf", v; s=s)
end

"""
    png(filename::AbstractString, v::SGPlots; s=1)
Save the plot ``v`` as a png file with name ``filename``.
"""
function png(filename::AbstractString, v::SGPlots; s=1)
    savefig(filename, "image/png", v, s=s)
end
