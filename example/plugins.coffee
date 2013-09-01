# Extension plugins for Primus, used on both sides of the connection

coffee = require 'coffee-script'
fs = require 'fs'

plugins = {}

plugins.verbose =
  server: (primus) ->
    ['connection', 'disconnection', 'initialised'].forEach (type) ->
      primus.on type, (socket) ->
        console.info "primus (#{type})", new Date
  client: (primus) ->
    # only report the first error, but do it very disruptively!
    primus.once 'error', alert

plugins.tick =
  server: (primus) ->
    setInterval ->
      primus.write Date.now()
    , 5000
  client: (primus) ->
    primus.transform 'incoming', (packet) ->
      if typeof packet.data is 'number'
        console.log 'tick', packet.data

# example plugin object, as needed by Primus:
#
# admin =
#   server: require './app/admin/plugin'
#   client: (primus) ->
#   library: coffee.compile fs.readFileSync './app/admin/module.coffee', 'utf8'

for name in fs.readdirSync './app'
  pluginPath = './app/' + name
  if fs.statSync(pluginPath).isDirectory()
    info = {}
    try
      info.server = require pluginPath + '/server'
    for ext in ['.js', '.coffee', '.coffee.md', '.litcoffee']
      modulePath = pluginPath + '/client' + ext
      try
        info.library = fs.readFileSync modulePath, 'utf8'
      if info.library
        unless ext is '.js'
          info.library = coffee.compile info.library,
            filename: modulePath
            literate: ext isnt '.coffee'
        info.client = (primus) ->
          # dummy function, needed by Primus to include the library code
        break
    if info.server or info.client
      plugins[name] = info

console.log 'plugins', Object.keys plugins

module.exports = plugins
