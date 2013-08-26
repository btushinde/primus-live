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

file = new Server './app'

server = http.createServer (req, res) ->

  sendResult = (mime, data) ->
    res.writeHead 200,
      'Content-Type': mime
      'Content-Length': Buffer.byteLength data
    res.end data

  fail = (err) ->
    res.writeHead err.status, err.headers
    res.end err.message

  req.resume()
  req.on 'end', ->
    # if req.uri.pathname is '/primus/primus.js'
    #   return sendResult 'application/javascript', primus.library()
    if req.uri.pathname is '/reload/reload.js'
      return sendResult 'application/javascript', coffee.compile '''
        window.primus = new Primus(window.document.URL)
        primus.on 'data', (data) ->
          if data is true
            window.location.reload true
          else if data is false
            for e in document.getElementsByTagName 'link'
              if e.href and /stylesheet/i.test e.rel
                e.href = "#{e.href.replace /\\?.*/, ''}?#{Date.now()}"
      '''

    file.serve req, res, (err) ->
      if err
        dest = file.root + req.uri.pathname
        dest += '/index.html'  if dest.substr(-1) is '/'
        src = data = undefined

        canTransform = (suffix, extensions...) ->
          if path.extname(dest) is suffix
            for ext in extensions
              src = dest.replace(suffix,'') + ext
              try
                data = fs.readFileSync src, encoding: 'utf8'
                return true

        switch
          when canTransform '.html', '.jade'
            sendResult 'text/html', do jade.compile data, { filename: src }
          when canTransform '.html', '.md'
            sendResult 'text/html', marked data
          when canTransform '.js', '.coffee', '.coffee.md', '.litcoffee'
            sendResult 'application/javascript', coffee.compile data
          when canTransform '.css', '.styl'
            stylus.render data, { filename: src }, (err, css) ->
              if err
                console.log 'stylus error', err
                fail err
              else
                sendResult 'text/css', css
          else
            fail err

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

watch file.root, (event, path) ->
  reload = not /\.(css|styl)$/.test path
  console.log 'reload:', reload, '-', event, path
  primus.write reload  # broadcast true or false

server.listen 8080
console.info 'server listening on :8080'
