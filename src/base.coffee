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

  it "should have the right methods", ->
    manikin.should.have.keys [
      'create'
    ]

    api = manikin.create()
    api.should.have.keys [
      # support-methods
      'connect'
      'close'
      'load'
      'connectionData'

      # model operations
      'post'
      'list'
      'getOne'
      'delOne'
      'putOne'
      'getMany'
      'delMany'
      'postMany'
    ]



  describe 'Basic manikin', ->

    beforeEach (done) ->
      dropDatabase(connectionData, done)

    after (done) ->
      dropDatabase(connectionData, done)



    it "should be able to connect even if no models have been defined", (done) ->
      api = manikin.create()
      promise(api).connect connectionData, {}, noErr ->
        api.close(done)



    it "should raise an error if an invalid connection string is given", (done) ->
      api = manikin.create()
      api.connect "invalid-connection-string", {}, (err) ->
        should.exist err
        done()



    it "should be possible to load after connecting without a model", (done) ->
      api = manikin.create()
      mad = {
        apa:
          fields:
            v1: 'string'
      }

      api.connect connectionData, noErr ->
        api.load mad, noErr ->
          api.post 'apa', { v1: '2' }, noErr ->
            api.close(done)


    it "should be possible to load first and then connect without a model", (done) ->
      api = manikin.create()
      mad = {
        apa:
          fields:
            v1: 'string'
      }

      api.load mad, noErr ->
        api.connect connectionData, noErr ->
          api.post 'apa', { v1: '2' }, noErr ->
            api.close(done)


    it "connecting without a model and never loading will throw errors when used", (done) ->
      api = manikin.create()
      mad = {
        apa:
          fields:
            v1: 'string'
      }

      # expecta att post throwar
      api.connect connectionData, noErr ->
        f = -> api.post('apa', { v2: '1', v1: '2' }, noErr)
        f.should.throw()
        api.close(done)


    describe 'connectionData', ->

      it "returns the data used to connect to the database", (done) ->
        api = manikin.create()
        mad = {
          apa:
            fields:
              v1: 'string'
        }

        api.connect connectionData, noErr ->
          api.connectionData().should.eql connectionData
          done()


    describe 'should not save configuration between test runs', ->
      commonModelName = 'stuffzz'

      it "stores things for the first test run", (done) ->
        api = manikin.create()
        model = _.object([[commonModelName,
          fields:
            v1: 'string'
        ]])
        promise(api).connect(connectionData, model, noErr())
        .post(commonModelName, { v1: '2' }, noErr())
        .list commonModelName, {}, noErr (list) ->
          list.length.should.eql 1
          list[0].should.have.keys ['v1', 'id']
          list[0].v1.should.eql '2'
          api.close(done)

      it "stores different things for the second test run", (done) ->
        api = manikin.create()
        model = _.object([[commonModelName,
          fields:
            v2: 'string'
        ]])
        promise(api).connect(connectionData, model, noErr())
        .post(commonModelName, { v2: '3' }, noErr())
        .list commonModelName, {}, noErr (list) ->
          list.length.should.eql 1
          list[0].should.have.keys ['v2', 'id']
          list[0].v2.should.eql '3'
          api.close(done)


    it "should have a post operation that returns a copy of the given item and adds an ID", (done) ->
      api = manikin.create()

      model =
        stuffz:
          fields:
            name: 'string'
            age: 'number'

      saved = {}
      input = { name: 'jakob', age: 28 }

      promise(api).connect(connectionData, model, noErr())
      .post('stuffz', input, noErr (obj) ->
        obj.should.have.keys ['id', 'name', 'age']
        obj.id.should.be.a 'string'
        obj.name.should.eql 'jakob'
        obj.age.should.eql 28
        obj.should.not.eql input
      ).then ->
        api.close(done)



    it "should have post for creating and list for showing what has been created", (done) ->
      api = manikin.create()

      model =
        stuffz:
          fields:
            name: 'string'
            age: 'number'

      saved = {}

      promise(api).connect(connectionData, model, noErr())
      .post('stuffz', { name: 'jakob', age: 28 }, noErr())
      .post('stuffz', { name: 'julia', age: 27 }, noErr())
      .list('stuffz', {}, noErr (list) ->
        list.map((x) -> _(x).omit('id')).should.eql [
          name: 'jakob'
          age: 28
        ,
          name: 'julia'
          age: 27
        ]
      ).then ->
        api.close(done)



    it "creates unique ids for all items posted", (done) ->
      api = manikin.create()

      model =
        stuffz:
          fields:
            name: 'string'
            age: 'number'

      saved = {}

      promise(api).connect(connectionData, model, noErr())
      .post('stuffz', { name: 'jakob', age: 28 }, noErr())
      .post('stuffz', { name: 'julia', age: 27 }, noErr())
      .list('stuffz', {}, noErr (list) ->
        list.should.have.length 2
        list[0].should.have.keys ['name', 'age', 'id']
        list[0].id.should.be.a.string
        list[1].should.have.keys ['name', 'age', 'id']
        list[1].id.should.be.a.string
        list[0].id.should.not.eql list[1].id
      ).then ->
        api.close(done)



    it "can list objects from their ID", (done) ->
      api = manikin.create()

      model =
        stuffz:
          fields:
            name: 'string'
            age: 'number'

      saved = {}

      promise(api).connect(connectionData, model, noErr())
      .post('stuffz', { name: 'jakob', age: 28 }, noErr())
      .post('stuffz', { name: 'julia', age: 27 }, noErr (x) ->
        saved.id = x.id
      ).then('list', -> @ 'stuffz', { filter: { id: saved.id } }, noErr (x) ->
        x.should.have.length 1
        x[0].should.eql {
          id: saved.id
          name: 'julia'
          age: 27
        }
      ).then ->
        api.close(done)



    it "can list objects from any of its properties", (done) ->
      api = manikin.create()

      model =
        stuffz:
          fields:
            name: 'string'
            age: 'number'

      saved = {}

      promise(api).connect(connectionData, model, noErr())
      .post('stuffz', { name: 'jakob', age: 28 }, noErr())
      .post('stuffz', { name: 'jakob', age: 42 }, noErr())
      .post('stuffz', { name: 'julia', age: 27 }, noErr())
      .list('stuffz', { filter: { name: 'jakob' } }, noErr (x) ->
        x.should.have.length 2
        x[0].name.should.eql 'jakob'
        x[0].age.should.eql 28
        x[1].name.should.eql 'jakob'
        x[1].age.should.eql 42
      ).then ->
        api.close(done)



    it "can list objects from any combination of their properties", (done) ->
      api = manikin.create()

      model =
        stuffz:
          fields:
            name: 'string'
            age: 'number'
            city: 'string'

      saved = {}

      promise(api).connect(connectionData, model, noErr())
      .post('stuffz', { name: 'jakob', age: 28, city: 'gbg' }, noErr())
      .post('stuffz', { name: 'julia', age: 27, city: 'gbg' }, noErr())
      .post('stuffz', { name: 'jakob', age: 28, city: 'sthlm' }, noErr())
      .post('stuffz', { name: 'julia', age: 27, city: 'sthlm' }, noErr())
      .list('stuffz', { filter: { name: 'jakob', city: 'sthlm' } }, noErr (x) ->
        x.should.have.length 1
        x[0].name.should.eql 'jakob'
        x[0].age.should.eql 28
        x[0].city.should.eql 'sthlm'
      ).then ->
        api.close(done)



    it "can sort objects", (done) ->
      api = manikin.create()

      model =
        stuffz:
          fields:
            name: 'string'
            age: 'number'

      saved = {}

      promise(api).connect(connectionData, model, noErr())
      .post('stuffz', { name: 'jakob', age: 28 }, noErr())
      .post('stuffz', { name: 'jakob', age: 42 }, noErr())
      .post('stuffz', { name: 'julia', age: 27 }, noErr())
      .list('stuffz', { sort: { age: 'asc' } }, noErr (x) ->
        x.should.have.length 3
        x[0].age.should.eql 27
        x[1].age.should.eql 28
        x[2].age.should.eql 42
      ).then ->
        api.close(done)



    it "can limit number of results returned", (done) ->
      api = manikin.create()

      model =
        stuffz:
          fields:
            name: 'string'
            age: 'number'

      saved = {}

      promise(api).connect(connectionData, model, noErr())
      .post('stuffz', { name: 'jakob', age: 28 }, noErr())
      .post('stuffz', { name: 'jakob', age: 42 }, noErr())
      .post('stuffz', { name: 'julia', age: 27 }, noErr())
      .list('stuffz', { limit: 2 }, noErr (x) ->
        x.should.have.length 2
      ).then ->
        api.close(done)


    it "can skip items", (done) ->
      api = manikin.create()

      model =
        stuffz:
          fields:
            name: 'string'
            age: 'number'

      saved = {}

      promise(api).connect(connectionData, model, noErr())
      .post('stuffz', { name: 'jakob', age: 28 }, noErr())
      .post('stuffz', { name: 'jakob', age: 42 }, noErr())
      .post('stuffz', { name: 'julia', age: 27 }, noErr())
      .list('stuffz', { skip: 2 }, noErr (x) ->
        x.should.have.length 1
      ).then ->
        api.close(done)



    it "can sort objects in a descending", (done) ->
      api = manikin.create()

      model =
        stuffz:
          fields:
            name: 'string'
            age: 'number'

      saved = {}

      promise(api).connect(connectionData, model, noErr())
      .post('stuffz', { name: 'jakob', age: 28 }, noErr())
      .post('stuffz', { name: 'jakob', age: 42 }, noErr())
      .post('stuffz', { name: 'julia', age: 27 }, noErr())
      .list('stuffz', { sort: { age: 'desc' } }, noErr (x) ->
        x.should.have.length 3
        x[0].age.should.eql 42
        x[1].age.should.eql 28
        x[2].age.should.eql 27
      ).then ->
        api.close(done)



    it "can get a single object from its ID", (done) ->
      api = manikin.create()

      model =
        stuffz:
          fields:
            name: 'string'
            age: 'number'

      saved = {}

      promise(api).connect(connectionData, model, noErr())
      .post('stuffz', { name: 'jakob', age: 28 }, noErr())
      .post('stuffz', { name: 'julia', age: 27 }, noErr (x) ->
        saved.id = x.id
      ).then('getOne', -> @ 'stuffz', { filter: { id: saved.id } }, noErr (x) ->
        x.should.eql {
          id: saved.id
          name: 'julia'
          age: 27
        }
      ).then ->
        api.close(done)



    it "can get a single object from any of its properties", (done) ->
      api = manikin.create()

      model =
        stuffz:
          fields:
            name: 'string'
            age: 'number'

      saved = {}

      promise(api).connect(connectionData, model, noErr())
      .post('stuffz', { name: 'jakob', age: 28 }, noErr())
      .post('stuffz', { name: 'julia', age: 27 }, noErr())
      .getOne('stuffz', { filter: { name: 'jakob' } }, noErr (x) ->
        x.name.should.eql 'jakob'
        x.age.should.eql 28
      ).then ->
        api.close(done)



    it "can get a single object from any combination of its properties", (done) ->
      api = manikin.create()

      model =
        stuffz:
          fields:
            name: 'string'
            age: 'number'
            city: 'string'

      saved = {}

      promise(api).connect(connectionData, model, noErr())
      .post('stuffz', { name: 'jakob', age: 28, city: 'gbg' }, noErr())
      .post('stuffz', { name: 'julia', age: 27, city: 'gbg' }, noErr())
      .post('stuffz', { name: 'jakob', age: 28, city: 'sthlm' }, noErr())
      .post('stuffz', { name: 'julia', age: 27, city: 'sthlm' }, noErr())
      .getOne('stuffz', { filter: { name: 'jakob', city: 'sthlm' } }, noErr (x) ->
        x.name.should.eql 'jakob'
        x.age.should.eql 28
        x.city.should.eql 'sthlm'
      ).then ->
        api.close(done)



    it "can filter out objects using an array of valid values", (done) ->
      api = manikin.create()

      model =
        stuffz:
          fields:
            name: 'string'
            age: 'number'

      saved = {}

      promise(api).connect(connectionData, model, noErr())
      .post('stuffz', { name: 'jakob',  age: 28 }, noErr())
      .post('stuffz', { name: 'julia',  age: 27 }, noErr())
      .post('stuffz', { name: 'sixten', age: 16 }, noErr())
      .list('stuffz', { filter: { age: [28, 27] } }, noErr (x) ->
        _(x).pluck('name').sort().should.eql ['jakob', 'julia']
      ).then ->
        api.close(done)



    it "calls back with an error if no objects where found", (done) ->
      api = manikin.create()

      model =
        stuffz:
          fields:
            name: 'string'
            age: 'number'

      saved = {}

      promise(api).connect(connectionData, model, noErr())
      .post('stuffz', { name: 'jakob', age: 28 }, noErr())
      .post('stuffz', { name: 'julia', age: 27 }, noErr())
      .getOne('stuffz', { filter: { name: 'sixten' } }, (err, x) ->
        err.should.eql new Error()
        should.not.exist x
      ).then ->
        api.close(done)



    it "can update an object", (done) ->
      api = manikin.create()

      model =
        stuffz:
          fields:
            name: 'string'
            age: 'number'
            city: 'string'

      saved = {}

      promise(api).connect(connectionData, model, noErr())
      .post('stuffz', { name: 'jakob', age: 28, city: 'gbg' }, noErr())
      .post('stuffz', { name: 'julia', age: 27, city: 'gbg' }, noErr())
      .putOne('stuffz', { city: 'sthlm' }, { name: 'julia' }, noErr())
      .list('stuffz', { }, noErr (x) ->
        x.should.have.length 2
        x[0].name.should.eql 'jakob'
        x[0].age.should.eql 28
        x[0].city.should.eql 'gbg'
        x[1].name.should.eql 'julia'
        x[1].age.should.eql 27
        x[1].city.should.eql 'sthlm'
      ).then ->
        api.close(done)



    it "can delete an object", (done) ->
      api = manikin.create()

      model =
        stuffz:
          fields:
            name: 'string'
            age: 'number'
            city: 'string'

      saved = {}

      promise(api).connect(connectionData, model, noErr())
      .post('stuffz', { name: 'jakob', age: 28, city: 'gbg' }, noErr())
      .post('stuffz', { name: 'julia', age: 27, city: 'gbg' }, noErr())
      .delOne('stuffz', { name: 'julia' }, noErr())
      .list('stuffz', { }, noErr (x) ->
        x.should.have.length 1
        x[0].name.should.eql 'jakob'
        x[0].age.should.eql 28
        x[0].city.should.eql 'gbg'
      ).then ->
        api.close(done)



    it "should allow a basic set of primitive data types to be stored and retrieved", (done) ->
      api = manikin.create()

      model =
        stuffz:
          fields:
            v1: 'string'
            v2: 'number'
            v3: 'date'
            v4: 'boolean'
            v5:
              type: 'nested'
              v6: 'string'
              v7: 'number'

      saved = {}

      promise(api).connect(connectionData, model, noErr())
      .post('stuffz', { v1: 'jakob', v2: 12.5, v3: '2012-10-15', v4: true, v5: { v6: 'nest', v7: 7 } }, noErr())
      .list('stuffz', {}, noErr (list) ->
        saved.id = list[0].id
        list.map((x) -> _(x).omit('id')).should.eql [
          v1: 'jakob'
          v2: 12.5
          v3: '2012-10-15T00:00:00.000Z'
          v4: true
          v5:
            v6: 'nest'
            v7: 7
        ]
      ).then ->
        api.close(done)



    it "should allow a basic set of primitive data types to be updated", (done) ->
      api = manikin.create()

      model =
        stuffz:
          fields:
            v1: 'string'
            v2: 'number'
            v3: 'date'
            v4: 'boolean'
            v5:
              type: 'nested'
              v6: 'string'
              v7: 'number'

      saved = {}

      promise(api).connect(connectionData, model, noErr())
      .post('stuffz', { v1: 'jakob', v2: 12.5, v3: '2012-10-15', v4: true, v5: { v6: 'nest', v7: 7 } }, noErr())
      .list('stuffz', {}, noErr (list) ->
        saved.id = list[0].id
        list.map((x) -> _(x).omit('id')).should.eql [
          v1: 'jakob'
          v2: 12.5
          v3: '2012-10-15T00:00:00.000Z'
          v4: true
          v5:
            v6: 'nest'
            v7: 7
        ]
      ).then('putOne', -> @ 'stuffz', { v1: 'jakob2', v3: '2012-10-15T13:37:00', v4: false, v5: { v6: 'nest2', v7: 14 } }, { id: saved.id }, noErr (r) ->
        _(r).omit('id').should.eql
          v1: 'jakob2'
          v2: 12.5
          v3: '2012-10-15T13:37:00.000Z'
          v4: false
          v5:
            v6: 'nest2'
            v7: 14
      ).then('getOne', -> @ 'stuffz', { filter: { id: saved.id } }, noErr (r) ->
        _(r).omit('id').should.eql
          v1: 'jakob2'
          v2: 12.5
          v3: '2012-10-15T13:37:00.000Z'
          v4: false
          v5:
            v6: 'nest2'
            v7: 14
      ).then ->
        api.close(done)



    it "should allow posting to nested properties", (done) ->
      api = manikin.create()

      model =
        stuffz:
          fields:
            v1: 'string'
            v5:
              type: 'nested'
              v6: 'string'
              v7: 'number'

      saved = {}

      promise(api).connect(connectionData, model, noErr())
      .post('stuffz', { v1: 'hej', v5: { v6: 'nest', v7: 7 } }, noErr())
      .then ->
        api.close(done)


    it "should allow putting null to nested properties", (done) ->
      api = manikin.create()

      model =
        stuffz:
          fields:
            v1: 'string'
            v5:
              type: 'nested'
              v6: 'string'
              v7: 'number'

      saved = {}

      promise(api).connect(connectionData, model, noErr())
      .post('stuffz', { v1: 'hej', v5: { v6: 'nest', v7: 7 } }, noErr (v) ->
        saved.id = v.id
      ).then('putOne', -> @ 'stuffz', { v1: 'jakob2', v5: null }, { id: saved.id }, noErr (r) ->
      ).then ->
        api.close(done)



    it "should detect when an object id does not exist", (done) ->
      api = manikin.create()

      model =
        table:
          fields:
            v1: 'string'

      promise(api).connect(connectionData, model, noErr())
      .getOne 'table', { filter: { id: '123' } }, (err, data) ->
        err.should.eql new Error()
        err.toString().should.eql 'Error: No such id'
        should.not.exist data
      .delOne('table', { id: '123' }, (err, data) ->
        err.should.eql new Error()
        err.toString().should.eql 'Error: No such id'
        should.not.exist data
      ).then ->
        api.close(done)




    it "should return an error in the callback if the given model does not exist in a listing", (done) ->
      api = manikin.create()
      mad = {
        apa:
          fields:
            v1: 'string'
      }

      api.load mad, noErr ->
        api.connect connectionData, noErr ->
          api.list 'non-existing', { filter: { v2: '1', v1: '2' } }, (err) ->
            err.should.eql new Error()
            err.toString().should.eql 'Error: No model named non-existing'
            api.close(done)


    it "should allow mixed properties in models definitions", (done) ->
      api = manikin.create()

      model =
        stuffs:
          owners: {}
          fields:
            name: { type: 'string' }
            stats: { type: 'mixed' }

      api.connect connectionData, model, noErr ->
        api.post 'stuffs', { name: 'a1', stats: { s1: 's1', s2: 2 } }, noErr (survey) ->
          survey.should.have.keys ['id', 'name', 'stats']
          survey.stats.should.have.keys ['s1', 's2']
          api.putOne "stuffs", { name: 'a2', stats: { x: 1 } }, { id: survey.id }, noErr (survey) ->
            survey.should.have.keys ['id', 'name', 'stats']
            survey.stats.should.have.keys ['x']
            api.close(done)



    it "should allow default sorting orders", (done) ->
      api = manikin.create()

      model =
        warez:
          owners: {}
          defaultSort: 'name'
          fields:
            name: { type: 'string' }
            stats: { type: 'mixed' }

      promise(api).connect(connectionData, model, noErr())
      .post('warez', { name: 'jakob', stats: 1 }, noErr())
      .post('warez', { name: 'erik', stats: 2 }, noErr())
      .post('warez', { name: 'julia', stats: 3 }, noErr())
      .list('warez', {}, noErr (list) ->
        names = list.map (x) -> x.name
        names.should.eql ['erik', 'jakob', 'julia']
      ).then ->
        api.close(done)



    it "should allow simplified field declarations (specifying type only)", (done) ->
      api = manikin.create()

      model =
        leet:
          owners: {}
          fields:
            firstName: 'string'
            lastName: { type: 'string' }
            age: 'number'

      api.connect connectionData, model, noErr ->
        api.post 'leet', { firstName: 'jakob', lastName: 'mattsson', age: 27 }, noErr (survey) ->
          survey.should.have.keys ['id', 'firstName', 'lastName', 'age']
          survey.should.eql { id: survey.id, firstName: 'jakob', lastName: 'mattsson', age: 27 }
          api.close(done)



    it "should detect when an filter matches no objects on getOne", (done) ->
      api = manikin.create()

      model =
        table:
          fields:
            v1: 'string'

      promise(api).connect(connectionData, model, noErr())
      .getOne('table', { filter: { v1: '123' } }, (err, data) ->
        err.should.eql new Error()
        err.toString().should.eql 'Error: No match'
        should.not.exist data
      ).then ->
        api.close(done)


    it "should detect when an filter matches no objects on delOne", (done) ->
      api = manikin.create()

      model =
        table:
          fields:
            v1: 'string'

      promise(api).connect(connectionData, model, noErr())
      .delOne('table', { v1: '123' }, (err, data) ->
        err.should.eql new Error()
        err.toString().should.eql 'Error: No such id'
        should.not.exist data
      ).then ->
        api.close(done)



    it "should be possible to specifiy the owner together with the fields when creating an object", (done) ->
      api = manikin.create()

      model =
        accounts:
          owners: {}
          fields:
            name: { type: 'string', default: '' }

        companies:
          owners:
            account: 'accounts'
          fields:
            name: { type: 'string', default: '' }
            orgnr: { type: 'string', default: '' }

      api.connect connectionData, model, noErr ->
        api.post 'accounts', { name: 'a1' }, noErr (account) ->
          account.should.have.keys ['name', 'id']
          api.post 'companies', { name: 'n', orgnr: 'nbr', account: account.id }, noErr (company) ->
            _(company).omit('id').should.eql {
              account: account.id
              name: 'n'
              orgnr: 'nbr'
            }
            api.close(done)



    it "should not be ok to post without specifiying the owner", (done) ->
      api = manikin.create()

      model =
        accounts:
          owners: {}
          fields:
            name: { type: 'string', default: '' }

        companies:
          owners:
            account: 'accounts'
          fields:
            name: { type: 'string', default: '' }
            orgnr: { type: 'string', default: '' }

      api.connect connectionData, model, noErr ->
        api.post 'accounts', { name: 'a1' }, noErr (account) ->
          account.should.have.keys ['name', 'id']
          api.post 'companies', { name: 'n', orgnr: 'nbr' }, (err, company) ->
            should.exist err # expect something more precise...
            api.close(done)



    it "must specify an existing owner of the right type when posting", (done) ->
      api = manikin.create()

      model =
        stuff:
          fields: {}

        accounts:
          owners: {}
          fields:
            name: { type: 'string', default: '' }

        companies:
          owners:
            account: 'accounts'
          fields:
            name: { type: 'string', default: '' }
            orgnr: { type: 'string', default: '' }

      api.connect connectionData, model, noErr ->
        api.post 'stuff', { }, noErr (stuff) ->
          api.post 'accounts', { name: 'a1' }, noErr (account) ->
            account.should.have.keys ['name', 'id']
            api.post 'companies', { name: 'n', orgnr: 'nbr', account: stuff.id }, (err, company) ->
              should.exist err # expect something more precise...
              api.close(done)



    it "should introduce redundant references to all ancestors", (done) ->
      api = manikin.create()

      model =
        accounts:
          owners: {}
          fields:
            name: { type: 'string', default: '' }

        companies2:
          owners:
            account: 'accounts'
          fields:
            name: { type: 'string', default: '' }
            orgnr: { type: 'string', default: '' }

        contacts:
          owners:
            company: 'companies2'
          fields:
            email: { type: 'string', default: '' }
            phone: { type: 'string', default: '' }

        pets:
          owners:
            contact: 'contacts'
          fields:
            race: { type: 'string', default: '' }

      saved = {}

      promise(api).connect(connectionData, model, noErr())
      .post('accounts', { name: 'a1' }, noErr (account) ->
        account.should.have.keys ['name', 'id']
        saved.account = account
      ).then('post', -> @ 'companies2', { name: 'n', orgnr: 'nbr', account: saved.account.id }, noErr (company) ->
        saved.company = company
        company.should.have.keys ['id', 'name', 'orgnr', 'account']
      ).then('post', -> @ 'companies2', { name: 'n2', orgnr: 'nbr', account: saved.account.id }, noErr (company2) ->
        saved.company2 = company2
        company2.should.have.keys ['id', 'name', 'orgnr', 'account']
      ).then('post', -> @ 'contacts', { email: '@', phone: '112', company: saved.company.id }, noErr (contact) ->
        saved.contact = contact
        contact.should.have.keys ['id', 'email', 'phone', 'account', 'company']
      ).then('post', -> @ 'contacts', { email: '@2', phone: '911', company: saved.company2.id }, noErr (contact2) ->
        saved.contact2 = contact2
        contact2.should.have.keys ['id', 'email', 'phone', 'account', 'company']
      ).then('post', -> @ 'pets', { race: 'dog', contact: saved.contact.id }, noErr (pet) ->
        pet.should.have.keys ['id', 'race', 'account', 'company', 'contact']
        pet.contact.should.eql saved.contact.id
        pet.company.should.eql saved.company.id
        pet.account.should.eql saved.account.id
      ).then('post', -> @ 'pets', { race: 'dog', contact: saved.contact2.id }, noErr (pet) ->
        pet.should.have.keys ['id', 'race', 'account', 'company', 'contact']
        pet.contact.should.eql saved.contact2.id
        pet.company.should.eql saved.company2.id
        pet.account.should.eql saved.account.id

      ).list('pets', {}, noErr ((res) -> res.length.should.eql 2))
      .list('contacts', {}, noErr ((res) -> res.length.should.eql 2))
      .list('companies2', {}, noErr ((res) -> res.length.should.eql 2))
      .list('accounts', {}, noErr ((res) -> res.length.should.eql 1))

      .then -> api.close(done)



    it "should delete owned objects when deleting ancestors", (done) ->
       api = manikin.create()

       model =
         accounts:
           owners: {}
           fields:
             name: { type: 'string', default: '' }

         companies2:
           owners:
             account: 'accounts'
           fields:
             name: { type: 'string', default: '' }
             orgnr: { type: 'string', default: '' }

         contacts:
           owners:
             company: 'companies2'
           fields:
             email: { type: 'string', default: '' }
             phone: { type: 'string', default: '' }

         pets:
           owners:
             contact: 'contacts'
           fields:
             race: { type: 'string', default: '' }

       saved = {}

       promise(api).connect(connectionData, model, noErr())
       .post('accounts', { name: 'a1' }, noErr (account) ->
         saved.account = account
       ).then('post', -> @ 'companies2', { name: 'n', orgnr: 'nbr', account: saved.account.id }, noErr (company) ->
         saved.company = company
       ).then('post', -> @ 'companies2', { name: 'n2', orgnr: 'nbr', account: saved.account.id }, noErr (company2) ->
         saved.company2 = company2
       ).then('post', -> @ 'contacts', { email: '@', phone: '112', company: saved.company.id }, noErr (contact) ->
         saved.contact = contact
       ).then('post', -> @ 'contacts', { email: '@2', phone: '911', company: saved.company2.id }, noErr (contact2) ->
         saved.contact2 = contact2
       ).then('post', -> @ 'pets', { race: 'dog', contact: saved.contact.id }, noErr (pet) ->
       ).then('post', -> @ 'pets', { race: 'dog', contact: saved.contact2.id }, noErr (pet) ->
       ).list('pets', {}, noErr ((res) -> res.length.should.eql 2))
       .list('contacts', {}, noErr ((res) -> res.length.should.eql 2))
       .list('companies2', {}, noErr ((res) -> res.length.should.eql 2))
       .list('accounts', {}, noErr ((res) -> res.length.should.eql 1))
       .then('delOne', -> @ 'companies2', { id: saved.company.id }, noErr())
       .list('pets', {}, noErr ((res) -> res.length.should.eql 1))
       .list('contacts', {}, noErr ((res) -> res.length.should.eql 1))
       .list('companies2', {}, noErr ((res) -> res.length.should.eql 1))
       .list('accounts', {}, noErr ((res) -> res.length.should.eql 1))
       .then -> api.close(done)



    it "should raise an error if a putOne attempts to put using an id from another collection", (done) ->
      api = manikin.create()

      model =
        accounts:
          fields:
            name: { type: 'string', default: '' }

      api.connect connectionData, model, noErr ->
        api.post 'accounts', { name: 'a1' }, noErr (account) ->
          api.putOne 'accounts', { name: 'n1' }, { id: 1 }, (err, data) ->
            err.should.eql new Error()
            err.toString().should.eql 'Error: No such id'
            api.close(done)



    it "should allow undefined values", (done) ->
      api = manikin.create()

      model =
        pizzas:
          owners: {}
          fields:
            name:
              type: 'string'

      api.connect connectionData, model, noErr ->
        api.post 'pizzas', { name: 'jakob' }, noErr (res) ->
          api.putOne 'pizzas', { name: undefined }, { id: res.id }, noErr (res) ->
            should.not.exist res.name
            api.close(done)



    it "should allow custom validators", (done) ->
      api = manikin.create()

      model =
        pizzas:
          owners: {}
          fields:
            name:
              type: 'string'
              validate: (apiRef, value, callback) ->
                api.should.eql apiRef
                callback(value.length % 2 == 0)

      indata = [
        name: 'jakob'
        response: 'something wrong'
      ,
        name: 'tobias'
        response: null
      ]

      api.connect connectionData, model, noErr ->
        async.forEach indata, (d, callback) ->
          api.post 'pizzas', { name: d.name }, (err, res) ->
            if d.response != null
              err.message.should.match /Validation failed/i
              err.errors.name.path.should.eql 'name'
            callback()
        , ->
          api.close(done)



    it "should raise an error if a putOne attempts to put non-existing fields", (done) ->
      api = manikin.create()

      model =
        accounts:
          fields:
            name: { type: 'string', default: '' }

      api.connect connectionData, model, noErr ->
        api.post 'accounts', { name: 'a1' }, noErr (account) ->
          api.putOne 'accounts', { name: 'n1', age: 10, desc: 'test' }, { id: account.id }, (err, data) ->
            err.should.eql new Error()
            err.toString().should.eql 'Error: Invalid fields: age, desc'
            api.close(done)



    it "should raise an error if a post attempts to put nonexisting fields", (done) ->
      api = manikin.create()
      mad = {
        apa:
          fields:
            v1: 'string'
      }

      api.connect connectionData, noErr ->
        api.load mad, noErr ->
          api.post 'apa', { v1: '2', v2: '1' }, (err) ->
            err.should.eql new Error()
            err.toString().should.eql 'Error: Invalid fields: v2'
            api.close(done)



    it "should raise an error if a putOne attempts to put using an id from another collection", (done) ->
      api = manikin.create()

      model =
        accounts:
          fields:
            name: { type: 'string', default: '' }
        other:
          fields:
            name: { type: 'string', default: '' }

      api.connect connectionData, model, noErr ->
        api.post 'other', { name: 'a1' }, noErr (other) ->
          api.post 'accounts', { name: 'a1' }, noErr (account) ->
            api.putOne 'accounts', { name: 'n1' }, { id: other.id }, (err, data) ->
              err.should.eql new Error()
              err.toString().should.eql 'Error: No such id'
              api.close(done)
