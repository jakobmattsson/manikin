assert = require 'assert'
should = require 'should'
async = require 'async'
_ = require 'underscore'



exports.promise = (api) ->

  obj = {}
  queue = []
  running = false
  methods = ['connect', 'close', 'post', 'list', 'getOne', 'delOne', 'putOne', 'getMany', 'delMany', 'postMany']

  invoke = (method, args, cb) ->
    method args..., ->
      cb.apply(this, arguments)
      running = false
      pop()

  pop = ->
    return if queue.length == 0

    running = true
    top = queue[0]
    queue = queue.slice(1)

    if top.name?
      top.callback.call (args..., cb) ->
        invoke api[top.name], args, cb
        obj
    else if top.method?
      invoke api[top.method], top.args, top.callback
    else
      top.callback()

  methods.forEach (method) ->
    obj[method] = (args..., callback) ->
      queue.push({ method: method, args: args, callback: callback })
      pop() if !running
      obj

  obj.then = (name, callback) ->
    if !callback?
      callback = name
      name = null

    queue.push({ name: name, callback: callback })
    pop() if !running
    obj

  obj
