module.exports = (app) ->

  app.config.plugin.tick =
    server: (primus) ->
      setInterval ->
        primus.write Date.now()
      , 1000
    client: (primus) ->
      primus.transform 'incoming', (packet) ->
        if typeof packet.data is 'number'
          console.log 'tick', packet.data

  console.info "starting server on port :#{app.config.port}"
