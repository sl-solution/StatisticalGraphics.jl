
function _write_html(vspec::Union{SGPlots, SGManipulate})
    divid="vg"*string(rand(UInt128), base=16)
    out_html = tempname() * ".html"
    html_out = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Embedding Vega-Lite</title>
        <script src="https://cdn.jsdelivr.net/npm/vega@5"></script>
        <script src="https://cdn.jsdelivr.net/npm/vega-lite@5"></script>
        <script src="https://cdn.jsdelivr.net/npm/vega-embed@6"></script>
    </head>
    <body>
        <div id="$divid"></div>

        <script>
        var spec = $(json(vspec.json_spec));
        vegaEmbed('#$divid', spec);
        </script>
    </body>
    </html>
    """
    write(out_html, html_out)
    out_html
end

function _write_script(io::IO, vspec::Union{SGPlots, SGManipulate})
    divid="vg"*string(rand(UInt128), base=16)
    write(io, 
    """
    <script src="https://cdn.jsdelivr.net/npm/vega@5"></script>
    <script src="https://cdn.jsdelivr.net/npm/vega-lite@5"></script>
    <script src="https://cdn.jsdelivr.net/npm/vega-embed@6"></script>
    <div id="$divid"></div>
    <script>
        var spec = $(json(vspec.json_spec));
        vegaEmbed('#$divid', spec);
    </script>
    """
    )
    nothing
end

function _write_json(vspec::SGPlots)
    out_html = tempname() * ".json"
    write(out_html, json(vspec.json_spec))
    out_html
end

function _convert_to_svg(vspec; s = 1)
    nodejscmd = Vega.NodeJS_18_jll.node()
    node_modules = joinpath(Vega.vegalite_app_path(), "node_modules/vega-cli/bin/vg2svg")
    ftmp = _write_json(vspec)
    res = read(Cmd(`$nodejscmd $node_modules -s $s $ftmp`), String)
    res
end
function _convert_to_png(vspec; s = 1)
    nodejscmd = Vega.NodeJS_18_jll.node()
    node_modules = joinpath(Vega.vegalite_app_path(), "node_modules/vega-cli/bin/vg2png")
    ftmp = _write_json(vspec)
    res = read(Cmd(`$nodejscmd $node_modules -s $s $ftmp`), String)
    res
end
function _convert_to_pdf(vspec; s = 1)
    nodejscmd = Vega.NodeJS_18_jll.node()
    node_modules = joinpath(Vega.vegalite_app_path(), "node_modules/vega-cli/bin/vg2pdf")
    ftmp = _write_json(vspec)
    res = read(Cmd(`$nodejscmd $node_modules -s $s $ftmp`), String)
    res
end

function Base.display(::REPL.REPLDisplay, vspec::Union{SGPlots, SGManipulate})
    tmppath = _write_html(vspec)
    launch_browser(tmppath) # Open the browser
end

# Base.show(io::IO, m::MIME, vspec::SGPlots) = show(io, m, Vega.VGSpec(vspec.json_spec))

Base.showable(::MIME"text/html", ::SGPlots) = isdefined(Main, :PlutoRunner)
# function Base.show(io::IO, ::MIME"text/html", vspec::SGPlots)
#     # _write_script(io, vspec)
#     show(io, Vega.VGSpec(vspec.json_spec))
# end

# function Base.show(io::IO, m::MIME"text/plain", v::SGPlots)
#     show(io, m, v)
# end
function Base.show(::IO,  v::SGPlots)
    v.json_spec
end
function Base.show(io::IO, ::MIME"image/svg+xml", v::SGPlots; s = 1)
   print(io, _convert_to_svg(v, s=s))
end
function Base.show(io::IO, ::MIME"application/pdf", v::SGPlots; s = 1)
    print(io, _convert_to_pdf(v, s=s))
end
function Base.show(io::IO, ::MIME"image/png", v::SGPlots; s = 1)
    print(io, _convert_to_png(v, s=s))
end
function Base.show(io::IO, m::MIME"application/vnd.julia.fileio.htmlfile", v::SGPlots)
    show(io, m, Vega.VGSpec(v.json_spec))
end
function Base.show(io::IO, m::MIME"application/prs.juno.plotpane+html", v::SGPlots)
    show(io, m, Vega.VGSpec(v.json_spec))
end
function Base.show(io::IO, m::MIME"text/html", v::SGPlots)
    show(io, m, Vega.VGSpec(v.json_spec))
end