# Real-time server, using Primus to handle the WebSocket transport
# -jcw, 2013-08-26

http = require 'http'
path = require 'path'
fs = require 'fs'
jade = require 'jade'
stylus = require 'stylus'
coffee = require 'coffee-script'
marked = require 'marked'
connect = require 'connect'
Primus = require 'primus'

APP_DIR = './app'

serveCompiled = (root) ->
  handler = (req, res, next) ->
    dest = root + req.uri.pathname
    src = data = undefined

    setResponse = (mime, data) ->
      bytes = Buffer.byteLength data
      res.writeHead 200, 'Content-Type': mime, 'Content-Length': bytes
      res.end data

    canCompile = (suffix, extensions...) ->
      if path.extname(dest) is suffix
        for ext in extensions
          src = dest.replace suffix, ext
          try
            return data = fs.readFileSync src, encoding: 'utf8'
      false

    switch
      when canCompile '.html', '.jade'
        setResponse 'text/html',
          do jade.compile data, filename: src
      when canCompile '.html', '.md'
        setResponse 'text/html',
          marked data
      when canCompile '.js', '.coffee'
        setResponse 'application/javascript',
          coffee.compile data
      when canCompile '.js', '.coffee.md', '.litcoffee'
        setResponse 'application/javascript',
          coffee.compile data, literate: true
      when canCompile '.css', '.styl'
        stylus.render data, { filename: src }, (err, css) ->
          throw err  if err
          setResponse 'text/css', css
      when req.uri.pathname isnt '/index.html'
        # perform a recursive call with the top-level index page as last resort
        # can be used to support "$locationProvider.html5Mode true" in Angular
        # TODO: it works, but will fail when a static page is present iso .jade
        handler { uri: { pathname: '/index.html' }}, res, next
      else
        next()

watchDir = (path, cb) -> # recursive directory watcher
  fs.stat path, (err, stats) ->
    if not err and stats.isDirectory()
      fs.watch path, cb
      fs.readdir path, (err, files) ->
        unless err
          watchDir "#{path}/#{f}", cb  for f in files

app = connect()
app.use connect.logger 'dev'
app.use connect.static APP_DIR, redirect: false
app.use connect.static './bower_components', redirect: false
app.use serveCompiled APP_DIR
app.use connect.errorHandler()

app.plugins = {}

app.plugins.boot =
  server: (primus) ->
    console.log 'BOOT'
  client: (primus) ->
    console.log 'BOOT'
  library: coffee.compile """
                            console.log 'LIB'
                          """, bare: true

app.plugins.live =
  server: (primus) ->
    # This is special logic to force a reload of each client when the server
    # comes back up after a restart due to code changes. We only want this to
    # happen for exisiting clients - new clients should not start off with a
    # refresh. Note the "once" setup, else we'd get an infinite reload loop.
    forceReload = (spark) -> primus.write true
    primus.once 'connection', forceReload
    setTimeout ->
      primus.removeListener 'connection', forceReload
    , 3000 # new clients connecting after 3s no longer get a reload signal

    watchDir APP_DIR, (event, path) ->
      if /\.(js|coffee|coffee\.md|litcoffee)$/.test path
        console.info 'exit due to code change:', path
        return process.exit 0
      reload = not /\.(css|styl)$/.test path
      console.info 'reload:', reload, '-', event, path
      primus.write reload  # broadcast true or false

  client: (primus) ->
    primus.on 'data', (data) ->
      if data is true
        window.location.reload true
      else if data is false
        for e in document.getElementsByTagName 'link'
          if e.href and /stylesheet/i.test e.rel
            e.href = "#{e.href.replace /\?.*/, ''}?#{Date.now()}"

# Scan through all the app subfolders to define plugins when 'client' and/or
# 'server' modules are found inside. Server plugins are loaded right away, but
# their main code should be in an exported function which is called by Primus.
fs.readdirSync('./app').forEach (name) ->
  pluginPath = process.cwd() + '/app/' + name
  if fs.statSync(pluginPath).isDirectory()
    info = {}
    try
      mod = require pluginPath + '/server'
      info.server = (primus) -> mod app, primus
    catch err
      throw err  unless err.code is 'MODULE_NOT_FOUND'
    for ext in ['.js', '.coffee', '.coffee.md', '.litcoffee']
      modulePath = pluginPath + '/client' + ext
      try
        info.library = fs.readFileSync modulePath, 'utf8'
      if info.library
        unless ext is '.js'
          info.library = coffee.compile info.library,
            filename: modulePath
            literate: ext isnt '.coffee'
        info.client = coffee.compile """
                        (primus) ->
                          console.log 'client: #{name}'
                      """, bare: true
          # dummy function, needed by Primus to include the library code
        break
    if info.server or info.client
      app.plugins[name] = info

try
  launch = require process.cwd() + '/app/launch'
catch err
  throw err  unless err.code is 'MODULE_NOT_FOUND'
launch? app

server = http.createServer app

new Primus server,
  transformer: app.transport or 'engine.io'
  plugin: app.plugins

port = app.port or 3333
server.listen port
console.info "server listening on :#{port}"
