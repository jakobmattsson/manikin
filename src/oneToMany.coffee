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

  describe 'Relational manikin', ->

    beforeEach (done) ->
      dropDatabase(connectionData, done)

    after (done) ->
      dropDatabase(connectionData, done)



    it "should provide has-one-relations", (done) ->
      api = manikin.create()
      model =

        accounts:
          defaultSort: 'name'
          fields:
            email: 'string'

        questions:
          owners: account: 'accounts'
          defaultSort: 'order'
          fields:
            text: 'string'

        devices:
          owners: account: 'accounts'
          fields:
            name: 'string'

        answers:
          owners: question: 'questions'
          fields:
            option: 'number'
            device:
              type: 'hasOne'
              model: 'devices'

      saved = {}
      promise(api).connect(connectionData, model, noErr())
      .post('accounts', { email: 'some@email.com' }, noErr (account) ->
        saved.account = account
      ).then('post', -> @ 'questions', { text: 'q1', account: saved.account.id }, noErr (question) ->
        saved.q1 = question
      ).then('post', -> @ 'questions', { text: 'q2', account: saved.account.id }, noErr (question) ->
        saved.q2 = question
      ).then('post', -> @ 'devices', { name: 'd1', account: saved.account.id }, noErr (device) ->
        saved.d1 = device
      ).then('post', -> @ 'devices', { name: 'd1', account: saved.account.id }, noErr (device) ->
        saved.d2 = device

      # Can set it to a deviceID
      ).then('post', -> @ 'answers', { option: 1, question: saved.q1.id, device: saved.d1.id }, noErr (answer) ->
        answer.device.should.eql saved.d1.id
        saved.a1 = answer

      #Can set it to null
      ).then('post', -> @ 'answers', { option: 1, question: saved.q1.id, device: null }, noErr (answer) ->
        should.not.exist answer.device
        saved.a2 = answer

      # Can update it to null
      ).then('putOne', -> @ 'answers', { device: null }, { id: saved.a1.id }, noErr (answer) ->
        should.not.exist answer.device

      # Can update it to another device
      ).then('putOne', -> @ 'answers', { device: saved.d2.id }, { id: saved.a1.id }, noErr (answer) ->
        answer.device.should.eql saved.d2.id

      # If the devices is deleted, the answers device is set to null
      ).then('delOne', -> @ 'devices', { id: saved.d2.id }, noErr () ->
        (1).should.eql 1
      ).then('getOne', -> @ 'answers', { filter: { id: saved.a1.id } }, noErr (answer) ->
        should.not.exist answer.device

      # Can't update it to something that is not a key of the correct type
      ).then('putOne', -> @ 'answers', { device: saved.a2.id }, { id: saved.a1.id }, (err, answer) ->
        err.should.eql new Error()
        err.toString().should.eql "Error: Invalid hasOne-key for 'device'"
        should.not.exist answer

      ).then(done)


    it "should be possible to add objects even when their hasOnes-collections are empty", (done) ->
      api = manikin.create()
      model =
        bananas:
          owners: {}
          fields:
            color: 'string'

        monkeys:
          owners: {}
          fields:
            name: 'string'
            banana:
              type: 'hasOne'
              model: 'bananas'

      saved = {}
      promise(api).connect(connectionData, model, noErr())
      .then('post', -> @ 'monkeys', { name: 'george' }, noErr (monkey) ->
        saved.monkey = monkey
      ).then('list', -> @ 'monkeys', {}, noErr (monkeys) ->
        monkeys.length.should.eql 1
      ).then(done)
