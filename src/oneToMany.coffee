assert = require 'assert'
should = require 'should'
async = require 'async'
_ = require 'underscore'
core = require './core'

noErr = (cb) ->
  (err, args...) ->
    should.not.exist err
    cb(args...) if cb

promise = core.promise

exports.runTests = (manikin, dropDatabase, connectionData) ->

  describe 'One-to-Many manikin', ->

    beforeEach (done) ->
      dropDatabase(connectionData, done)

    after (done) ->
      dropDatabase(connectionData, done)






    it "should be possible to save hasOne-values", (done) ->
      api = manikin.create()
      model =

        devices:
          fields:
            name: 'string'

        answers:
          fields:
            option: 'number'
            device:
              type: 'hasOne'
              model: 'devices'

      saved = {}
      api.connect connectionData, model, noErr ->
        api.post 'devices', { name: 'd1' }, noErr (device) ->
          api.post 'answers', { option: 1, device: device.id }, noErr (answer) ->
            answer.device.should.eql device.id
            api.close(done)



    it "can initialize a hasOne to null", (done) ->
      api = manikin.create()
      model =

        devices:
          fields:
            name: 'string'

        answers:
          fields:
            option: 'number'
            device:
              type: 'hasOne'
              model: 'devices'

      saved = {}
      api.connect connectionData, model, noErr ->
        api.post 'devices', { name: 'd1' }, noErr (device) ->
          api.post 'answers', { option: 1, device: null }, noErr (answer) ->
            should.not.exist answer.device
            api.close(done)



    it "can overwrite a hasOne with null", (done) ->
      api = manikin.create()
      model =

        devices:
          fields:
            name: 'string'

        answers:
          fields:
            option: 'number'
            device:
              type: 'hasOne'
              model: 'devices'

      saved = {}
      api.connect connectionData, model, noErr ->
        api.post 'devices', { name: 'd1' }, noErr (device) ->
          api.post 'answers', { option: 1, device: device.id }, noErr (answer) ->
            api.putOne 'answers', { device: null }, answer, noErr (answer2) ->
              should.not.exist answer2.device
              api.close(done)



    it "can update it to another key", (done) ->
      api = manikin.create()
      model =

        devices:
          fields:
            name: 'string'

        answers:
          fields:
            option: 'number'
            device:
              type: 'hasOne'
              model: 'devices'

      saved = {}
      api.connect connectionData, model, noErr ->
        api.post 'devices', { name: 'd1' }, noErr (device) ->
          api.post 'devices', { name: 'd2' }, noErr (device2) ->
            api.post 'answers', { option: 1, device: device.id }, noErr (answer) ->
              api.putOne 'answers', { device: device2.id }, answer, noErr (answer2) ->
                answer2.device.should.eql device2.id
                api.close(done)



    it "resets the relation to null if the entry pointed to is deleted", (done) ->
      api = manikin.create()
      model =

        devices:
          fields:
            name: 'string'

        answers:
          fields:
            option: 'number'
            device:
              type: 'hasOne'
              model: 'devices'

      saved = {}
      api.connect connectionData, model, noErr ->
        api.post 'devices', { name: 'd1' }, noErr (device) ->
          api.post 'answers', { option: 1, device: device.id }, noErr (answer) ->
            api.delOne 'devices', device, noErr ->
              api.getOne 'answers', { id: answer.id }, noErr (answer) ->
                should.not.exist answer.device
                api.close(done)



    it "cant update it to something that is not a key", (done) ->
      api = manikin.create()
      model =

        devices:
          fields:
            name: 'string'

        answers:
          fields:
            option: 'number'
            device:
              type: 'hasOne'
              model: 'devices'

      saved = {}
      api.connect connectionData, model, noErr ->
        api.post 'devices', { name: 'd1' }, noErr (device) ->
          api.post 'answers', { option: 1, device: device.id }, noErr (answer) ->
            api.putOne 'answers', { device: 'hellow-there' }, answer, (err, answer2) ->
              should.exist err
              should.not.exist answer2
              api.close(done)



    it "cant update it to an id of an entry belonging to another collection", (done) ->
      api = manikin.create()
      model =

        devices:
          fields:
            name: 'string'

        answers:
          fields:
            option: 'number'
            device:
              type: 'hasOne'
              model: 'devices'

      saved = {}
      api.connect connectionData, model, noErr ->
        api.post 'devices', { name: 'd1' }, noErr (device) ->
          api.post 'answers', { option: 1, device: device.id }, noErr (answer) ->
            api.post 'answers', { option: 1, device: device.id }, noErr (answer2) ->
              api.putOne 'answers', { device: answer2.id }, answer, (err, answer3) ->
                err.should.eql new Error()
                err.toString().should.eql "Error: Invalid hasOne-key for 'device'"
                should.not.exist answer3
                api.close(done)



    it "can filter one-to-manys using a list", (done) ->
      api = manikin.create()
      model =

        devices:
          fields:
            name: 'string'

        answers:
          fields:
            option: 'number'
            device:
              type: 'hasOne'
              model: 'devices'

      saved = {}
      api.connect connectionData, model, noErr ->
        api.post 'devices', { name: 'd1' }, noErr (d1) ->
          api.post 'devices', { name: 'd2' }, noErr (d2) ->
            api.post 'devices', { name: 'd3' }, noErr (d3) ->
              api.post 'answers', { option: 1, device: d1.id }, noErr (a1) ->
                api.post 'answers', { option: 2, device: d2.id }, noErr (a2) ->
                  api.post 'answers', { option: 3, device: d3.id }, noErr (a3) ->
                    api.list 'answers', { filter: { device: [d1.id, d2.id] } }, noErr (result) ->
                      _(result).pluck('option').sort().should.eql [1,2]
                      api.close(done)
