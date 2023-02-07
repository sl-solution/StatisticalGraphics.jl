
function _write_html(vspec::Union{SGPlot, SGPanel, SGGrid})
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
        <div id="vis"></div>

        <script>
        var spec = $(json(vspec.json_spec));
        vegaEmbed('#vis', spec);
        </script>
    </body>
    </html>
    """
    write(out_html, html_out)
    out_html
end

function _write_script(io::IO, vspec::Union{SGPlot, SGPanel, SGGrid})
    divid=string(rand(UInt128), base=16)
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

function _write_json(vspec::Union{SGPlot, SGPanel, SGGrid})
    out_html = tempname() * ".json"
    write(out_html, json(vspec.json_spec))
    out_html
end

function _convert_to_svg(vspec; s = 1)
    nodejscmd = Vega.NodeJS.node_executable_path
    node_modules = joinpath(Vega.vegalite_app_path, "node_modules/vega-cli/bin/vg2svg")
    ftmp = _write_json(vspec)
    res = read(Cmd(`$nodejscmd $node_modules -s $s $ftmp`), String)
    res
end
function _convert_to_png(vspec; s = 1)
    nodejscmd = Vega.NodeJS.node_executable_path
    node_modules = joinpath(Vega.vegalite_app_path, "node_modules/vega-cli/bin/vg2png")
    ftmp = _write_json(vspec)
    res = read(Cmd(`$nodejscmd $node_modules -s $s $ftmp`), String)
    res
end
function _convert_to_pdf(vspec; s = 1)
    nodejscmd = Vega.NodeJS.node_executable_path
    node_modules = joinpath(Vega.vegalite_app_path, "node_modules/vega-cli/bin/vg2pdf")
    ftmp = _write_json(vspec)
    res = read(Cmd(`$nodejscmd $node_modules -s $s $ftmp`), String)
    res
end

function Base.display(::REPL.REPLDisplay, vspec::Union{SGPlot, SGPanel, SGGrid})
    tmppath = _write_html(vspec)
    launch_browser(tmppath) # Open the browser
end

# Base.show(io::IO, m::MIME, vspec::Union{SGPlot, SGPanel, SGGrid}) = show(io, m, Vega.VGSpec(vspec.json_spec))

Base.showable(::MIME"text/html", ::Union{SGPlot, SGPanel, SGGrid}) = isdefined(Main, :PlutoRunner)
# function Base.show(io::IO, ::MIME"text/html", vspec::Union{SGPlot, SGPanel, SGGrid})
#     # _write_script(io, vspec)
#     show(io, Vega.VGSpec(vspec.json_spec))
# end

function Base.show(io::IO, m::MIME"text/plain", v::Union{SGPlot, SGPanel, SGGrid})
    show(io, m, v)
end
function Base.show(io::IO,  v::Union{SGPlot, SGPanel, SGGrid})
    v.json_spec
end
function Base.show(io::IO, ::MIME"image/svg+xml", v::Union{SGPlot, SGPanel, SGGrid}; s = 1)
   print(io, _convert_to_svg(v, s=s))
end
function Base.show(io::IO, m::MIME"application/pdf", v::Union{SGPlot, SGPanel, SGGrid}; s = 1)
    print(io, _convert_to_pdf(v, s=s))
end
function Base.show(io::IO, m::MIME"image/png", v::Union{SGPlot, SGPanel, SGGrid}; s = 1)
    print(io, _convert_to_png(v, s=s))
end
function Base.show(io::IO, m::MIME"application/vnd.julia.fileio.htmlfile", v::Union{SGPlot, SGPanel, SGGrid})
    show(io, m, Vega.VGSpec(v.json_spec))
end
function Base.show(io::IO, m::MIME"application/prs.juno.plotpane+html", v::Union{SGPlot, SGPanel, SGGrid})
    show(io, m, Vega.VGSpec(v.json_spec))
end
function Base.show(io::IO, m::MIME"text/html", v::Union{SGPlot, SGPanel, SGGrid})
    show(io, m, Vega.VGSpec(v.json_spec))
end