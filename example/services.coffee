# Services implemented in the server

console.info 'installing services'

module.exports = (primus) ->

  ['connection', 'disconnection', 'initialised'].forEach (type) ->
    primus.on type, (socket) ->
      console.info "primus (#{type})", new Date
