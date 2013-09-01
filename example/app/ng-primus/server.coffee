module.exports = (primus) ->
  primus.on 'connection', (spark) ->
    spark.on 'data', (arg) ->
      switch
        when arg.constructor is String
          console.info 'primus', spark.id, ':', arg
        when Array.isArray arg
          primus.emit arg...
        when arg instanceof Object
          primus.emit 'client', spark, arg
