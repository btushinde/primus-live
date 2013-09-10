# Extension plugins for Primus, used on both sides of the connection

coffee = require 'coffee-script'
fs = require 'fs'

plugins = {}

plugins.boot =
  server: (primus) ->
    console.log 'BOOT'
  client: (primus) ->
    console.log 'BOOT'
  library: coffee.compile """
                            console.log 'LIB'
                          """, bare: true

# example plugin object, as needed by Primus:
#
# admin =
#   server: require './app/admin/plugin'
#   client: (primus) ->
#   library: coffee.compile fs.readFileSync './app/admin/module.coffee', 'utf8'

for name in fs.readdirSync './app'
  pluginPath = process.cwd() + '/app/' + name
  if fs.statSync(pluginPath).isDirectory()
    info = {}
    try
      info.server = require pluginPath + '/server'
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
      plugins[name] = info

console.log "plugins: #{Object.keys(plugins)}"

module.exports = plugins
