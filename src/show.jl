
function _write_html(vspec::Union{SGPlot, SGPanel})
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

function _write_script(io::IO, vspec::Union{SGPlot, SGPanel})
    divid=string(DLMReader.UUIDs.uuid1().value, base=16)
    write(io, 
    """
    <div id="$divid"></div>
    <script src="https://cdn.jsdelivr.net/npm/vega@5"></script>
    <script src="https://cdn.jsdelivr.net/npm/vega-lite@5"></script>
    <script src="https://cdn.jsdelivr.net/npm/vega-embed@6"></script>
    <script>
        var spec = $(json(vspec.json_spec));
        vegaEmbed('#$divid', spec);
    </script>
    """
    )
    nothing
end


function Base.display(::REPL.REPLDisplay, vspec::Union{SGPlot, SGPanel})
    tmppath = _write_html(vspec)
    launch_browser(tmppath) # Open the browser
end

Base.showable(::MIME"text/html", ::Union{SGPlot, SGPanel}) = isdefined(Main, :PlutoRunner)
function Base.show(io::IO, ::MIME"text/html", vspec::Union{SGPlot, SGPanel})
    _write_script(io, vspec)
end
