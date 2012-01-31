Annotator.Plugin.Offline = class Offline extends Annotator.Plugin
  _t = Annotator._t

  constructor: (element, options) ->
    super
    @store = null

  pluginInit: ->
    