module.exports = (app, plugin) ->  
  app.on 'setup', ->
  	console.log('Main Plugin Setup')