base = require './base'
manyToMany = require './manyToMany'
oneToMany = require './oneToMany'

exports.runTests = (manikin, dropDatabase, connectionData) ->
  base.runTests(manikin, dropDatabase, connectionData)
  manyToMany.runTests(manikin, dropDatabase, connectionData)
  oneToMany.runTests(manikin, dropDatabase, connectionData)
