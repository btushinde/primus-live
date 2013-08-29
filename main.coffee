# Real-time server, using Primus to handle the WebSocket transport
# -jcw, 2013-08-26

http = require 'http'
path = require 'path'
fs = require 'fs'
jade = require 'jade'
stylus = require 'stylus'
coffee = require 'coffee-script'
marked = require 'marked'
{Server} = require 'node-static'
Primus = require 'primus'

appFiles = new Server './app'
moreFiles = new Server './bower_components'

server = http.createServer (request, response) ->

  setResponse = (mime, data) ->
    bytes = Buffer.byteLength data
    response.writeHead 200, 'Content-Type': mime, 'Content-Length': bytes
    response.end data

  serveStaticOrCompiled = (files, fail) ->
    files.serve request, response, (err) ->
      if err
        dest = files.root + request.uri.pathname
        dest += '/index.html'  if dest.substr(-1) is '/'
        src = data = undefined

        canTransform = (suffix, extensions...) ->
          if path.extname(dest) is suffix
            for ext in extensions
              src = dest.replace(suffix,'') + ext
              try
                return data = fs.readFileSync src, encoding: 'utf8'
          false

        switch
          when canTransform '.html', '.jade'
            setResponse 'text/html', do jade.compile data, filename: src
          when canTransform '.html', '.md'
            setResponse 'text/html', marked data
          when canTransform '.js', '.coffee', '.coffee.md', '.litcoffee'
            setResponse 'application/javascript', coffee.compile data
          when canTransform '.css', '.styl'
            stylus.render data, filename: src, (e, css) ->
              if e
                console.warn 'stylus error', e.message
                fail err
              else
                setResponse 'text/css', css
          else
            fail err

  request.resume()
  request.on 'end', ->
    if request.uri.pathname is '/reload/reload.js'
      return setResponse 'application/javascript', coffee.compile '''
        window.primus = new Primus
        primus.on 'data', (data) ->
          if data is true
            window.location.reload true
          else if data is false
            for e in document.getElementsByTagName 'link'
              if e.href and /stylesheet/i.test e.rel
                e.href = "#{e.href.replace /\\?.*/, ''}?#{Date.now()}"
      '''
    serveStaticOrCompiled appFiles, (err) ->
      serveStaticOrCompiled moreFiles, (err) ->
        response.writeHead err.status, err.headers
        response.end err.message

try # silently ignore missing plugins
  plugins = require "#{process.cwd()}/plugins"

primus = new Primus server, transformer: 'engine.io', plugin: plugins ? {}

# recursive directory watcher, FIXME: directories added later don't get watched
watch = (path, cb) ->
  fs.stat path, (err, stats) ->
    unless err
      if stats.isDirectory()
        fs.watch path, cb
        fs.readdir path, (err, files) ->
          unless err
            watch "#{path}/#{f}", cb  for f in files

watch appFiles.root, (event, path) ->
  reload = not /\.(css|styl)$/.test path
  console.info 'reload:', reload, '-', event, path
  primus.write reload  # broadcast true or false

server.listen 8080
console.info 'server listening on :8080'
