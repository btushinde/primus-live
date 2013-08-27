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

server = http.createServer (req, res) ->

  setResponse = (mime, data) ->
    res.writeHead 200,
      'Content-Type': mime
      'Content-Length': Buffer.byteLength data
    res.end data

  serveStaticOrCompiled = (files, fail) ->
    files.serve req, res, (err) ->
      if err
        dest = files.root + req.uri.pathname
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
            setResponse 'text/html', do jade.compile data, { filename: src }
          when canTransform '.html', '.md'
            setResponse 'text/html', marked data
          when canTransform '.js', '.coffee', '.coffee.md', '.litcoffee'
            setResponse 'application/javascript', coffee.compile data
          when canTransform '.css', '.styl'
            stylus.render data, { filename: src }, (err, css) ->
              if err
                console.log 'stylus error', err
                do fail
              else
                setResponse 'text/css', css
          else
            do fail

  req.resume()
  req.on 'end', ->
    if req.uri.pathname is '/reload/reload.js'
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
    serveStaticOrCompiled appFiles, ->
      serveStaticOrCompiled moreFiles, ->
        res.writeHead err.status, err.headers
        res.end err.message

primus = new Primus server, transformer: 'engine.io'

primus.on 'connection', (socket) ->
  console.log 'new connection'
  socket.on 'data', (msg) ->
    console.log 'msg', msg
    primus.write ping: msg # broadcast (use socket.write for single reply)

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
  console.log 'reload:', reload, '-', event, path
  primus.write reload  # broadcast true or false

server.listen 8080
console.info 'server listening on :8080'
