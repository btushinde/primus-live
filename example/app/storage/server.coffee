level = require 'level'

module.exports = (primus) ->

  db = level './storage', {}, (err) ->
    throw err  if err
    if true
      console.log 'db opened', db.db.getProperty 'leveldb.stats'
      db.db.approximateSize ' ', '~', (err, size) ->
        throw err  if err
        console.log 'storage use ~ %d bytes', size

  # internal helper to scan a specific range of keys
  keyBoundaryFinder = (from, to, rev) ->
    (prefix, cb) ->
      result = undefined
      db.createKeyStream
        start: prefix + from
        end: prefix + to
        reverse: rev
        limit: 1
      .on 'data', (data) ->
        result = data
      .on 'end', ->
        cb result

  db.firstKey = keyBoundaryFinder '~', '~~', false
  db.lastKey = keyBoundaryFinder '~~', '~', true

  # the dumb approach of scanning all keys to find the prefixes won't work for
  # lots of keys, we nned to skip over each prefix found when filling the list
  db.getPrefixDetails = (cb) ->
    result = []

    # use a recursive function to handle the asynchronous callbacks
    iterator = (key) ->
      return cb result  unless key
      prefix = key.replace /~.*/, ''
      db.db.approximateSize prefix + '~', prefix + '~~', (err, size) ->
        throw err  if err
        result[prefix] = size
        keyBoundaryFinder(prefix + '~~', '~', false) '', iterator

    keyBoundaryFinder('', '~', false) '', iterator

  db.collectValues = (prefix, cb) ->
    result = []
    db.createValueStream
      start: prefix + '~'
      end: prefix + '~~'
      valueEncoding: 'json'
    .on 'data', (data) ->
      result.push data
    .on 'end', ->
      cb result

  primus.db = db
