base = require './base'
relations = require './relations'

exports.runTests = (manikin, dropDatabase, connectionData) ->
  base.runTests(manikin, dropDatabase, connectionData)
  relations.runTests(manikin, dropDatabase, connectionData)
