path = require 'path'

_ = require 'underscore'

module.exports =
class FailureTree
  filterStack: null
  suites: null

  constructor: (@filterStack) ->
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
      @filterStackTrace(item)

  filterStackTrace: (failure) ->
    stackTrace = @filterStack(failure.trace.stack)
    return unless stackTrace

    # Remove first line if it matches the failure message
    stackTraceLines = stackTrace.split('\n')
    [firstLine] = stackTraceLines
    {message} = failure
    if firstLine is message or firstLine is "Error: #{message}"
      stackTraceLines.shift()

    # Remove remaining line if it is from an anonymous function
    if stackTraceLines.length is 1
      [firstLine] = stackTraceLines
      if match = /^\s*at\s+null\.<anonymous>\s+\((.*):(\d+):(\d+)\)\s*$/.exec(firstLine)
        stackTraceLines.shift()
        filePath = match[1]
        relativePath = path.relative(process.cwd(), filePath)
        filePath = relativePath if relativePath[0] isnt '.'
        line = match[2]
        column = match[3]
        failure.messageLine = "#{filePath}:#{line}:#{column}"

    failure.filteredStackTrace = stackTraceLines.join('\n')

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
