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
          coffee.compile data, filename: src
      when canCompile '.js', '.coffee.md', '.litcoffee'
        setResponse 'application/javascript',
          coffee.compile data, filename: src, literate: true
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

watchDir = (dir, cb) -> # recursive directory watcher
  fs.stat dir, (err, stats) ->
    if not err and stats.isDirectory()
      fs.watch dir, (event, file) ->
        cb event, path.join(dir, file)
      fs.readdir dir, (err, files) ->
        unless err
          watchDir path.join(dir, f), cb  for f in files

app = connect()
app.use connect.logger 'dev'
app.use connect.static APP_DIR, redirect: false
app.use connect.static './bower_components', redirect: false
app.use connect.static './node_modules', redirect: false
app.use serveCompiled APP_DIR
app.use connect.errorHandler()

app.config = { port: 3333, transformer: 'engine.io', plugin: {} }

app.config.plugin.live =
  server: (primus) ->
    # This is special logic to force a reload of each client when the server
    # comes back up after a restart due to code changes. We only want this to
    # happen for exisiting clients - new clients should not start off with a
    # refresh. Note the "once" setup, else we'd get an repeated reload loop.
    forceReload = (spark) -> primus.write true
    primus.once 'connection', forceReload
    setTimeout ->
      primus.removeListener 'connection', forceReload
    , 5000 # new clients connecting after 5s no longer get a reload signal

    watchDir APP_DIR, (event, file) ->
      if /\.(js|coffee|coffee\.md|litcoffee)$/.test file
        console.info 'exit due to code change:', file
        return process.exit 0
      reload = not /\.(css|styl)$/.test file
      console.info 'reload:', reload, '-', event, file
      primus.write reload  # broadcast true or false

  client: (primus) ->
    primus.on 'data', (data) ->
      if data is true
        window.location.reload true
      else if data is false
        for e in document.getElementsByTagName 'link'
          if e.href and /stylesheet/i.test e.rel
            e.href = "#{e.href.replace /\?.*/, ''}?#{Date.now()}"

# Try to load a module via CommonJS, or return undefined otherwise
loadIfFileExists = (fileRoot) ->
  try
    require fileRoot
  catch err
    throw err  unless err.code is 'MODULE_NOT_FOUND'

# Execute the launch script if present
launch = loadIfFileExists path.resolve(APP_DIR, 'launch')
launch? app

loadPlugin = (name) ->
  pluginPath = path.resolve(APP_DIR, name)
  if fs.statSync(pluginPath).isDirectory()
    plugin = {}
    for ext in ['.js', '.coffee', '.coffee.md', '.litcoffee']
      modulePath = path.join pluginPath, 'client' + ext
      try
        plugin.library = fs.readFileSync modulePath, 'utf8'
      if plugin.library
        unless ext is '.js'
          plugin.library = coffee.compile plugin.library,
            filename: modulePath
            literate: ext isnt '.coffee'
        break
    host = loadIfFileExists path.join(pluginPath, 'host')
    host? app, plugin
    if host or Object.keys(plugin).length
      plugin.client ?= -> # need some function, else Primus will complain
      app.config.plugin[name] = plugin

# Allow loading certain modules before the rest
for plugin in app.config.loadFirst or []
  loadPlugin plugin

# Scan through all the app subfolders to define plugins when 'client' and/or
# 'server' modules are found inside. Server plugins are loaded right away, but
# their main code should be in an exported function which is called by Primus.
# Don't reload any preloaded plugins.
fs.readdirSync(APP_DIR).forEach (name) ->
  unless app.config.plugin[name] 
    loadPlugin name

app.emit 'setup'

server = http.createServer app
primus = new Primus server, app.config
server.listen app.config.port

app.emit 'running', primus
