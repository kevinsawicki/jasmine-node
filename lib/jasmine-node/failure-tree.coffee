_ = require 'underscore'

module.exports =
class FailureTree
  suites: null

  constructor: ->
    @suites = []

  isEmpty: -> @suites.length is 0

  add: (spec) ->
    for item in spec.results().items_ when item.passed_ is false
      failurePath = []
      parent = spec.suite
      while parent
        failurePath.unshift(parent)
        parent = parent.parentSuite

      parentSuite = this
      for failure in failurePath
        parentSuite.suites[failure.id] ?= {spec: failure, suites: [], specs: []}
        parentSuite = parentSuite.suites[failure.id]

      parentSuite.specs[spec.id] ?= {spec, failures:[]}
      parentSuite.specs[spec.id].failures.push(item)

  forEachSpec: ({spec, suites, specs, failures}={}, callback, depth=0) ->
    if failures?
      callback(spec, null, depth)
      callback(spec, failure, depth) for failure in failures
    else
      callback(spec, null, depth)
      depth++
      @forEachSpec(child, callback, depth) for child in _.compact(suites)
      @forEachSpec(child, callback, depth) for child in _.compact(specs)

  forEach: (callback) ->
    @forEachSpec(suite, callback) for suite in _.compact(@suites)
