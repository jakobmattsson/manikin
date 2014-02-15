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

  describe 'Many-to-Many manikin', ->

    beforeEach (done) ->
      dropDatabase(connectionData, done)

    after (done) ->
      dropDatabase(connectionData, done)



    it "should be possible to post a many-to-many relation", (done) ->
      api = manikin.create()

      model =
        people:
          owners: {}
          fields:
            name: { type: 'string', default: '' }
            boundDevices: { type: 'hasMany', model: 'devices', inverseName: 'boundPeople' }

        devices:
          owners: {}
          fields:
            name: { type: 'string', default: '' }

      api.connect connectionData, noErr ->
        api.load model, noErr ->
          api.post 'people', { name: 'q1' }, noErr (q1) ->
            api.post 'devices', { name: 'q1' }, noErr (d1) ->
              api.postMany 'people', q1.id, 'boundDevices', d1.id, noErr ->
                api.close(done)



    it "should be possible to query a many-to-many relation", (done) ->
      api = manikin.create()

      model =
        people:
          owners: {}
          fields:
            name: { type: 'string', default: '' }
            boundDevices: { type: 'hasMany', model: 'devices', inverseName: 'boundPeople' }

        devices:
          owners: {}
          fields:
            name: { type: 'string', default: '' }

      api.connect connectionData, noErr ->
        api.load model, noErr ->
          api.post 'people', { name: 'q1' }, noErr (q1) ->
            api.post 'devices', { name: 'q1' }, noErr (d1) ->
              api.postMany 'people', q1.id, 'boundDevices', d1.id, noErr ->
                api.getMany 'people', q1.id, 'boundDevices', noErr (boundDevices) ->
                  boundDevices.should.eql [{
                    name: q1.name
                    boundPeople: [q1.id]
                    id: d1.id
                  }]
                  api.close(done)



    it "should be possible to delete a many-to-many relation", (done) ->
      api = manikin.create()

      model =
        people:
          owners: {}
          fields:
            name: { type: 'string', default: '' }
            boundDevices: { type: 'hasMany', model: 'devices', inverseName: 'boundPeople' }

        devices:
          owners: {}
          fields:
            name: { type: 'string', default: '' }

      api.connect connectionData, noErr ->
        api.load model, noErr ->
          api.post 'people', { name: 'q1' }, noErr (q1) ->
            api.post 'devices', { name: 'q1' }, noErr (d1) ->
              api.postMany 'people', q1.id, 'boundDevices', d1.id, noErr ->
                api.delMany 'people', q1.id, 'boundDevices', d1.id, noErr ->
                  api.getMany 'people', q1.id, 'boundDevices', noErr (boundDevices) ->
                    boundDevices.should.have.length 0
                    api.close(done)



    it "should create an inverse relation when posting a many-to-many", (done) ->
      api = manikin.create()

      model =
        people:
          owners: {}
          fields:
            name: { type: 'string', default: '' }
            boundDevices: { type: 'hasMany', model: 'devices', inverseName: 'boundPeople' }

        devices:
          owners: {}
          fields:
            name: { type: 'string', default: '' }

      api.connect connectionData, noErr ->
        api.load model, noErr ->
          api.post 'people', { name: 'q1' }, noErr (q1) ->
            api.post 'devices', { name: 'q1' }, noErr (d1) ->
              api.postMany 'people', q1.id, 'boundDevices', d1.id, noErr ->
                api.getMany 'devices', d1.id, 'boundPeople', noErr (boundPeople) ->
                  boundPeople.should.eql [{
                    name: d1.name
                    boundDevices: [d1.id]
                    id: q1.id
                  }]
                  api.close(done)



    it "should be possible to filter results for getMany and get some matches", (done) ->
      api = manikin.create()

      model =
        people:
          owners: {}
          fields:
            name: { type: 'string', default: '' }
            boundDevices: { type: 'hasMany', model: 'devices', inverseName: 'boundPeople' }

        devices:
          owners: {}
          fields:
            name: { type: 'string', default: '' }

      api.connect connectionData, noErr ->
        api.load model, noErr ->
          api.post 'people', { name: 'q1' }, noErr (q1) ->
            api.post 'devices', { name: 'q1' }, noErr (d1) ->
              api.postMany 'people', q1.id, 'boundDevices', d1.id, noErr ->
                api.getMany 'devices', d1.id, 'boundPeople', { name: d1.name }, noErr (boundPeople) ->
                  boundPeople.should.have.length 1
                  api.close(done)



    it "should be possible to filter results for getMany and get no matches", (done) ->
      api = manikin.create()

      model =
        people:
          owners: {}
          fields:
            name: { type: 'string', default: '' }
            boundDevices: { type: 'hasMany', model: 'devices', inverseName: 'boundPeople' }

        devices:
          owners: {}
          fields:
            name: { type: 'string', default: '' }

      api.connect connectionData, noErr ->
        api.load model, noErr ->
          api.post 'people', { name: 'q1' }, noErr (q1) ->
            api.post 'devices', { name: 'q1' }, noErr (d1) ->
              api.postMany 'people', q1.id, 'boundDevices', d1.id, noErr ->
                api.getMany 'devices', d1.id, 'boundPeople', { name: 'unused' }, noErr (boundPeople) ->
                  boundPeople.should.have.length 0
                  api.close(done)



    it "should return an empty array for unused many-to-many relations", (done) ->
      api = manikin.create()

      model =
        people:
          owners: {}
          fields:
            name: { type: 'string', default: '' }
            boundDevices: { type: 'hasMany', model: 'devices', inverseName: 'boundPeople' }

        devices:
          owners: {}
          fields:
            name: { type: 'string', default: '' }

      api.connect connectionData, noErr ->
        api.load model, noErr ->
          api.post 'people', { name: 'q1' }, noErr (q1) ->
            q1.boundDevices.should.eql []
            api.close(done)



    it "should return an empty array for unused reversed many-to-many relations", (done) ->
      api = manikin.create()

      model =
        people:
          owners: {}
          fields:
            name: { type: 'string', default: '' }
            boundDevices: { type: 'hasMany', model: 'devices', inverseName: 'boundPeople' }

        devices:
          owners: {}
          fields:
            name: { type: 'string', default: '' }

      api.connect connectionData, noErr ->
        api.load model, noErr ->
          api.post 'devices', { name: 'q1' }, noErr (q1) ->
            q1.boundPeople.should.eql []
            api.close(done)



    it "should delete reverse manyToMany when the base one is deleted", (done) ->
      api = manikin.create()

      model =
        people:
          owners: {}
          fields:
            name: { type: 'string', default: '' }
            boundDevices: { type: 'hasMany', model: 'devices', inverseName: 'boundPeople' }

        devices:
          owners: {}
          fields:
            name: { type: 'string', default: '' }

      api.connect connectionData, noErr ->
        api.load model, noErr ->
          api.post 'people', { name: 'q1' }, noErr (q1) ->
            api.post 'devices', { name: 'q1' }, noErr (d1) ->
              api.postMany 'people', q1.id, 'boundDevices', d1.id, noErr ->
                api.delMany 'people', q1.id, 'boundDevices', d1.id, noErr ->
                  api.getMany 'devices', d1.id, 'boundPeople', noErr (boundPeople) ->
                    boundPeople.should.have.length 0
                    api.close(done)



    it "should delete manyToMany when the reverse one is deleted", (done) ->
      api = manikin.create()

      model =
        people:
          owners: {}
          fields:
            name: { type: 'string', default: '' }
            boundDevices: { type: 'hasMany', model: 'devices', inverseName: 'boundPeople' }

        devices:
          owners: {}
          fields:
            name: { type: 'string', default: '' }

      api.connect connectionData, noErr ->
        api.load model, noErr ->
          api.post 'people', { name: 'q1' }, noErr (q1) ->
            api.post 'devices', { name: 'q1' }, noErr (d1) ->
              api.postMany 'people', q1.id, 'boundDevices', d1.id, noErr ->
                api.delMany 'devices', d1.id, 'boundPeople', q1.id, noErr ->
                  api.getMany 'people', q1.id, 'boundDevices', noErr (boundDevices) ->
                    boundDevices.should.have.length 0
                    api.close(done)



    it "should be possible to query many-to-many-relationships (2)", (done) ->
      api = manikin.create()

      model =
        people:
          owners: {}
          fields:
            name: { type: 'string', default: '' }
            boundDevices: { type: 'hasMany', model: 'devices', inverseName: 'boundPeople' }

        devices:
          owners: {}
          fields:
            name: { type: 'string', default: '' }

      saved = {}

      promise(api).connect(connectionData, model, noErr())
      .post('people', { name: 'q1' }, noErr (q1) ->
        saved.q1 = q1
      ).post('people', { name: 'q2' }, noErr (q2) ->
        saved.q2 = q2
      ).post('devices', { name: 'd1' }, noErr (d1) ->
        saved.d1 = d1
      ).post('devices', { name: 'd2' }, noErr (d2) ->
        saved.d2 = d2
      ).then 'postMany', -> @('people',  saved.q1.id, 'boundDevices', saved.d1.id, noErr())
      .then 'postMany', -> @('people',  saved.q1.id, 'boundDevices', saved.d2.id, noErr())
      .then 'getMany',  -> @('people',  saved.q1.id, 'boundDevices', noErr((data) -> data.length.should.eql 2))
      .then 'getMany',  -> @('people',  saved.q1.id, 'boundDevices', { name: 'd1' }, noErr((data) -> data.length.should.eql 1))
      .then 'getMany',  -> @('people',  saved.q1.id, 'boundDevices', { name: 'd2' }, noErr((data) -> data.length.should.eql 1))
      .then 'getMany',  -> @('people',  saved.q1.id, 'boundDevices', { name: 'd3' }, noErr((data) -> data.length.should.eql 0))
      .then 'getMany',  -> @('people',  saved.q2.id, 'boundDevices', noErr((data) -> data.length.should.eql 0))
      .then 'getMany',  -> @('devices', saved.d1.id, 'boundPeople',  noErr((data) -> data.length.should.eql 1))
      .then 'getMany',  -> @('devices', saved.d2.id, 'boundPeople',  noErr((data) -> data.length.should.eql 1))
      .then 'delMany',  -> @('people',  saved.q1.id, 'boundDevices', saved.d1.id, noErr())
      .then 'getMany',  -> @('people',  saved.q1.id, 'boundDevices', noErr((data) -> data.length.should.eql 1))
      .then 'getMany',  -> @('people',  saved.q2.id, 'boundDevices', noErr((data) -> data.length.should.eql 0))
      .then 'getMany',  -> @('devices', saved.d1.id, 'boundPeople',  noErr((data) -> data.length.should.eql 0))
      .then 'getMany',  -> @('devices', saved.d2.id, 'boundPeople',  noErr((data) -> data.length.should.eql 1))

      .then -> api.close(done)



    it "should delete many-to-many-relations when objects are deleted", (done) ->
      api = manikin.create()

      model =
        petsY:
          fields:
            name: 'string'

        foodsY:
          fields:
            name: 'string'
            eatenBy: { type: 'hasMany', model: 'petsY', inverseName: 'eats' }

      saved = {}

      promise(api).connect(connectionData, model, noErr())
      .then('post', -> @('petsY', { name: 'pet1' }, noErr (res) -> saved.pet1 = res))
      .then('post', -> @('foodsY', { name: 'food1' }, noErr (res) -> saved.food1 = res))
      .then('postMany', -> @('foodsY', saved.food1.id, 'eatenBy', saved.pet1.id, noErr()))
      .then('delOne', -> @('petsY', { id: saved.pet1.id }, noErr()))
      .then('list', -> @('petsY', { }, noErr((data) -> data.length.should.eql 0)))
      .then('list', -> @('foodsY', { }, noErr (data) -> data.should.eql [
        id: saved.food1.id
        name: 'food1'
        eatenBy: []
      ]))
      .then -> api.close(done)



    it "should delete many-to-many-relations even when owners of the related objects are deleted", (done) ->
      api = manikin.create()

      model =
        peopleX:
          fields:
            name: 'string'

        petsX:
          owners: { person: 'peopleX' }
          fields:
            name: 'string'

        foodsX:
          owners: {}
          fields:
            name: 'string'
            eatenBy: { type: 'hasMany', model: 'petsX', inverseName: 'eats' }

      saved = {}

      promise(api).connect(connectionData, model, noErr())
      .post('peopleX', { name: 'p1' }, noErr (res) ->
        saved.person = res
      ).then 'post', -> @('petsX', { person: saved.person.id, name: 'pet1' }, noErr (res) -> saved.pet1 = res)
      .then 'post', -> @('foodsX', { name: 'food1' }, noErr (res) -> saved.food1 = res)
      .then 'postMany', -> @('foodsX',  saved.food1.id, 'eatenBy', saved.pet1.id, noErr())
      .then 'getMany',  -> @('petsX', saved.pet1.id, 'eats', noErr((data) -> data.length.should.eql 1))
      .then 'delOne',  -> @('peopleX', { id: saved.person.id }, noErr())
      .then 'list',  -> @('peopleX', { }, noErr((data) -> data.length.should.eql 0))
      .then 'list',  -> @('petsX', { }, noErr((data) -> data.length.should.eql 0))
      .then 'list',  -> @('foodsX', { }, noErr (data) -> data.should.eql [
        id: saved.food1.id
        name: 'food1'
        eatenBy: []
      ])
      .then -> api.close(done)



    it "should prevent duplicate many-to-many values, even when data is posted in parallel", (done) ->
      api = manikin.create()

      model =
        typeA:
          fields:
            name: 'string'

        typeB:
          fields:
            name: 'string'
            belongsTo: { type: 'hasMany', model: 'typeA', inverseName: 'belongsTo2' }

      saved = {}
      resultStatuses = {}

      api.connect connectionData, model, noErr ->
        api.post 'typeA', { name: 'a1' }, noErr (a1) ->
          api.post 'typeB', { name: 'b1' }, noErr (b1) ->
            async.forEach [1,2,3], (item, callback) ->
              api.postMany 'typeB', b1.id, 'belongsTo', a1.id, noErr (result) ->
                resultStatuses[result.status] = resultStatuses[result.status] || 0
                resultStatuses[result.status]++
                callback()
            , ->
              resultStatuses['inserted'].should.eql 1
              resultStatuses['insert already in progress'].should.eql 2
              api.list 'typeA', {}, noErr (x) ->
                x[0].belongsTo2.length.should.eql 1
                api.close(done)



    it "should prevent duplicate many-to-many values, even when data is posted in parallel, to both end-points", (done) ->
      api = manikin.create()

      model =
        typeC:
          fields:
            name: 'string'

        typeD:
          fields:
            name: 'string'
            belongsTo: { type: 'hasMany', model: 'typeC', inverseName: 'belongsTo2' }

      saved = {}
      resultStatuses = {}

      api.connect connectionData, model, noErr ->
        api.post 'typeC', { name: 'c1' }, noErr (c1) ->
          api.post 'typeD', { name: 'd1' }, noErr (d1) ->
            async.forEach [['typeC', c1.id, 'belongsTo2', d1.id], ['typeD', d1.id, 'belongsTo', c1.id]], (item, callback) ->
              f = noErr (result) ->
                resultStatuses[result.status] = resultStatuses[result.status] || 0
                resultStatuses[result.status]++
                callback()
              api.postMany.apply(api, item.concat([f]))
            , ->
              resultStatuses['inserted'].should.eql 1
              resultStatuses['insert already in progress'].should.eql 1
              api.list 'typeC', {}, noErr (x) ->
                x[0].belongsTo2.length.should.eql 1
                api.close(done)



    it "should allow adding back a manyToMany relation after deleting it", (done) ->
      api = manikin.create()

      model =
        people:
          owners: {}
          fields:
            name: { type: 'string', default: '' }
            boundDevices: { type: 'hasMany', model: 'devices', inverseName: 'boundPeople' }

        devices:
          owners: {}
          fields:
            name: { type: 'string', default: '' }

      api.connect connectionData, noErr ->
        api.load model, noErr ->
          api.post 'people', { name: 'q1' }, noErr (q1) ->
            api.post 'devices', { name: 'q1' }, noErr (d1) ->
              api.postMany 'people', q1.id, 'boundDevices', d1.id, noErr ->
                api.delMany 'devices', d1.id, 'boundPeople', q1.id, noErr ->
                  api.getMany 'people', q1.id, 'boundDevices', noErr (boundDevices) ->
                    boundDevices.should.have.length 0
                    api.postMany 'people', q1.id, 'boundDevices', d1.id, noErr ({ status }) ->
                      status.should.eql 'inserted'
                      api.getMany 'people', q1.id, 'boundDevices', noErr (boundDevices) ->
                        boundDevices.should.have.length 1
                        api.close(done)



    it "should raise an error on posts to invalid many to many-properties", (done) ->
      api = manikin.create()

      model =
        typeA:
          fields:
            name: 'string'

        typeB:
          fields:
            name: 'string'
            belongsTo: { type: 'hasMany', model: 'typeA' }

      saved = {}
      api.connect connectionData, model, noErr ->
        api.post 'typeA', { name: 'a' }, noErr (a) ->
          api.post 'typeB', { name: 'b' }, noErr (b) ->
            api.postMany 'typeA', a.id, 'relation-that-does-not-exist', b.id, (err) ->
              err.should.eql new Error()
              err.toString().should.eql 'Error: Invalid many-to-many property'
              api.close(done)



    it "should raise an error on deletes to invalid many to many-properties", (done) ->
      api = manikin.create()

      model =
        typeA:
          fields:
            name: 'string'

        typeB:
          fields:
            name: 'string'
            belongsTo: { type: 'hasMany', model: 'typeA' }

      saved = {}
      api.connect connectionData, model, noErr ->
        api.post 'typeA', { name: 'a' }, noErr (a) ->
          api.post 'typeB', { name: 'b' }, noErr (b) ->
            api.delMany 'typeA', a.id, 'relation-that-does-not-exist', b.id, (err) ->
              err.should.eql new Error()
              err.toString().should.eql 'Error: Invalid many-to-many property'
              api.close(done)



    it "should raise an error on gets to invalid many to many-properties", (done) ->
      api = manikin.create()

      model =
        typeA:
          fields:
            name: 'string'

        typeB:
          fields:
            name: 'string'
            belongsTo: { type: 'hasMany', model: 'typeA' }

      saved = {}
      api.connect connectionData, model, noErr ->
        api.post 'typeA', { name: 'a' }, noErr (a) ->
          api.post 'typeB', { name: 'b' }, noErr (b) ->
            api.getMany 'typeA', a.id, 'relation-that-does-not-exist', b.id, (err) ->
              err.should.eql new Error()
              err.toString().should.eql 'Error: Invalid many-to-many property'
              api.close(done)



    it "should raise an error on getMany with invalid model id", (done) ->
      api = manikin.create()

      model =
        typeA:
          fields:
            name: 'string'

        typeB:
          fields:
            name: 'string'
            belongsTo: { type: 'hasMany', model: 'typeA' }

      saved = {}
      api.connect connectionData, model, noErr ->
        api.post 'typeA', { name: 'a' }, noErr (a) ->
          api.post 'typeB', { name: 'b' }, noErr (b) ->
            api.getMany 'typeA', 'invalid-id', 'belongsTo', b.id, (err) ->
              err.should.eql new Error()
              err.toString().should.eql "Error: Could not find an instance of 'typeA' with id 'invalid-id'"
              api.close(done)



    it "should raise an error on delMany with invalid model id", (done) ->
      api = manikin.create()

      model =
        typeA:
          fields:
            name: 'string'

        typeB:
          fields:
            name: 'string'
            belongsTo: { type: 'hasMany', model: 'typeA' }

      saved = {}
      api.connect connectionData, model, noErr ->
        api.post 'typeA', { name: 'a' }, noErr (a) ->
          api.post 'typeB', { name: 'b' }, noErr (b) ->
            api.delMany 'typeA', 'invalid-id', 'belongsTo', b.id, (err) ->
              err.should.eql new Error()
              err.toString().should.eql "Error: Could not find an instance of 'typeA' with id 'invalid-id'"
              api.close(done)



    it "should raise an error on delMany with invalid secondary model id", (done) ->
      api = manikin.create()

      model =
        typeA:
          fields:
            name: 'string'

        typeB:
          fields:
            name: 'string'
            belongsTo: { type: 'hasMany', model: 'typeA' }

      saved = {}
      api.connect connectionData, model, noErr ->
        api.post 'typeA', { name: 'a' }, noErr (a) ->
          api.post 'typeB', { name: 'b' }, noErr (b) ->
            api.delMany 'typeA', a.id, 'belongsTo', 'invalid-id', (err) ->
              err.should.eql new Error()
              err.toString().should.eql "Error: Could not find an instance of 'typeB' with id 'invalid-id'"
              api.close(done)



    it "should raise an error on postMany with invalid model id", (done) ->
      api = manikin.create()

      model =
        typeA:
          fields:
            name: 'string'

        typeB:
          fields:
            name: 'string'
            belongsTo: { type: 'hasMany', model: 'typeA' }

      saved = {}
      api.connect connectionData, model, noErr ->
        api.post 'typeA', { name: 'a' }, noErr (a) ->
          api.post 'typeB', { name: 'b' }, noErr (b) ->
            api.postMany 'typeA', 'invalid-id', 'belongsTo', b.id, (err) ->
              err.should.eql new Error()
              err.toString().should.eql "Error: Could not find an instance of 'typeA' with id 'invalid-id'"
              api.close(done)



    it "should raise an error on postMany with invalid secondary model id", (done) ->
      api = manikin.create()

      model =
        typeA:
          fields:
            name: 'string'

        typeB:
          fields:
            name: 'string'
            belongsTo: { type: 'hasMany', model: 'typeA' }

      saved = {}
      api.connect connectionData, model, noErr ->
        api.post 'typeA', { name: 'a' }, noErr (a) ->
          api.post 'typeB', { name: 'b' }, noErr (b) ->
            api.postMany 'typeA', a.id, 'belongsTo', 'invalid-id', (err) ->
              err.should.eql new Error()
              err.toString().should.eql "Error: Could not find an instance of 'typeB' with id 'invalid-id'"
              api.close(done)



    it "should never insert duplicates of manyToMany-relations", (done) ->
      api = manikin.create()

      model =
        typeA:
          fields:
            name: 'string'

        typeB:
          fields:
            name: 'string'
            belongsTo: { type: 'hasMany', model: 'typeA' }

      saved = {}
      api.connect connectionData, model, noErr ->
        api.post 'typeA', { name: 'a' }, noErr (a) ->
          api.post 'typeB', { name: 'b' }, noErr (b) ->
            api.postMany 'typeA', a.id, 'belongsTo', b.id, noErr ({ status }) ->
              status.should.eql 'inserted'
              api.postMany 'typeA', a.id, 'belongsTo', b.id, noErr ({ status }) ->
                status.should.eql 'already inserted'
                api.getMany 'typeA', a.id, 'belongsTo', noErr (result) ->
                  result.should.have.length 1
                  api.list 'typeA', {}, noErr (aList) ->
                    aList.should.eql [{
                      id: a.id
                      name: a.name
                      belongsTo: [b.id]
                    }]
                    api.list 'typeB', {}, noErr (bList) ->
                      bList.should.eql [{
                        id: b.id
                        name: b.name
                        belongsTo: [a.id]
                      }]
                      api.close(done)



    it "can filter many-to-manys using a list", (done) ->
      api = manikin.create()
      model =
        typeA:
          fields:
            name: 'string'

        typeB:
          fields:
            name: 'string'
            belongsTo: { type: 'hasMany', model: 'typeA' }

      saved = {}
      api.connect connectionData, model, noErr ->
        api.post 'typeA', { name: 'a1' }, noErr (a1) ->
          api.post 'typeA', { name: 'a2' }, noErr (a2) ->
            api.post 'typeA', { name: 'a3' }, noErr (a3) ->
              api.post 'typeB', { name: 'b1' }, noErr (b1) ->
                api.post 'typeB', { name: 'b2' }, noErr (b2) ->
                  api.post 'typeB', { name: 'b3' }, noErr (b3) ->
                    api.postMany 'typeA', a1.id, 'belongsTo', b1.id, noErr ->
                      api.postMany 'typeA', a1.id, 'belongsTo', b2.id, noErr ->
                        api.postMany 'typeA', a2.id, 'belongsTo', b1.id, noErr ->
                          api.list 'typeB', { filter: { belongsTo: [a1.id, a2.id] } }, noErr (result) ->
                            _(result).pluck('name').sort().should.eql ['b1', 'b2']
                            api.close(done)
