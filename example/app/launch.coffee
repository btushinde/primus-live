module.exports = (app) ->
  # specify which modules need to be loaded first, and in what order
  app.config.loadFirst = ['main']
  
  # define a "tick" plugin
  app.config.plugin.tick =
    server: (primus) ->
      setInterval ->
        primus.write Date.now()
      , 1000
    client: (primus) ->
      primus.transform 'incoming', (packet) ->
        if typeof packet.data is 'number'
          console.log 'tick', packet.data

  app.on 'running', ->
      console.log "server listening on port :#{app.config.port}"
