base = require './base'
relations = require './relations'
oneToMany = require './oneToMany'

exports.runTests = (manikin, dropDatabase, connectionData) ->
  base.runTests(manikin, dropDatabase, connectionData)
  relations.runTests(manikin, dropDatabase, connectionData)
  oneToMany.runTests(manikin, dropDatabase, connectionData)
