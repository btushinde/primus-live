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

plugins.angular =

  server: (primus) ->
    primus.on 'connection', (spark) ->
      spark.on 'data', (arg) ->
        switch
          when arg.constructor is String
            console.info 'primus', spark.id, ':', arg
          when Array.isArray arg
            primus.emit arg...
          when arg instanceof Object
            primus.emit 'client', spark, arg

  client: (primus) ->
    # define an Angular module which injects incoming events The Angular Way
    # this module must be added as dependency in the main Angular application
    ng = angular.module 'primus', []
    ng.run [
      '$rootScope',
      ($rootScope) ->

        # TODO 'open' event fails regularly in 1.4.0, use private event for now
        primus.on 'incoming::open', (arg) ->
          $rootScope.$apply -> $rootScope.serverConnection = 'open'
        primus.on 'end', (arg) ->
          $rootScope.$apply -> $rootScope.serverConnection = 'closed'
        primus.on 'reconnect', (arg) ->
          $rootScope.$apply -> $rootScope.serverConnection = 'lost'

        primus.on 'data', (arg) ->
          $rootScope.$apply ->
            switch
              when arg.constructor is String
                $rootScope.serverMessage = arg
              when typeof arg is 'number'
                $rootScope.serverTick = arg
              when Array.isArray arg
                $rootScope.$broadcast arg...
              when arg instanceof Object
                $rootScope.$broadcast 'server', arg
    ]

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
      info.server = require pluginPath + '/plugin'
    for ext in ['.js', '.coffee', '.coffee.md', '.litcoffee']
      modulePath = pluginPath + '/module' + ext
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
