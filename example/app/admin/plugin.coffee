# Admin plugin for Primus, i.e. on the server side

module.exports = (primus) ->
  console.log 'admin hello'
  primus.on 'ping', -> console.log 'PING!'
