# Annotator plugin that handles storing annotations locally. It also detects
# the browsers connectivity allowing you to sync annotations with an external
# persistant store.
#
# As well as the online() and offline() callbacks that can be provided when
# the plugin is initialised "online" and "offline" events are also triggered.
#
# Examples
#
#   annotator 'addPlugin', 'Offline',
#     online: (plugin) ->
#       startServerPoll()
#     offline: (plugin) ->
#       cancelServerPoll()
#
# Returns a new instance of the Offline plugin.
Annotator.Plugin.Offline = class Offline extends Annotator.Plugin
  # Export Annotator properties into the local scope.
  _t = Annotator._t
  jQuery = Annotator.$

  # Prefix for all annotation keys assigned to the store.
  @ANNOTATION_PREFIX = "annotation."

  # Public: Creates a reasonably unique identifier based on the current time
  # and a randomly generated value. This is really only suitable for local
  # deployments, if you're going to be using these ids to persist annotations
  # elsewhere it would be worth assigning a RFC4122 compatible uuid using the
  # setAnnotationData() option.
  #
  # Examples
  #
  #   Offline.uuid() #=> "92992580798454581328033163230"
  #
  # Returns a randomly generated string.
  @uuid = -> ("" + Math.random() + new Date().getTime()).slice(2)

  # Default event listeners.
  events:
    "annotationCreated": "_onAnnotationCreated"
    "annotationUpdated": "_onAnnotationUpdated"
    "annotationDeleted": "_onAnnotationDeleted"
  
  # Default options for the plugin.
  options:
    # Creates a unique key for the annotation to be stored against. This uses
    # the annotations "id" property if it has one, otherwise it will assign it
    # a randomly generated key.
    #
    # annotation - An annotation object.
    #
    # Examples
    #
    #   annotation = {id: "a-unique-id"}
    #   @getUniqueKey(annotation) #=> "a-unique-id"
    #
    # Returns a unique identifier for the annotation.
    getUniqueKey: (annotation) ->
      annotation.id = Offline.uuid() unless annotation.id
      annotation.id
  
  # Creates a new instance of the plugin and initialises instance variables.
  #
  # element - The root annotator element.
  # options - An object literal of options.
  #           online:            Function that is called when the plugin goes
  #                              online. Recieves the plugin object as an
  #                              argument.
  #           offline:           Function that is called when the plugin goes
  #                              offline. Recieves the plugin object as an
  #                              argument.
  #           getUniqueKey:      Function that accepts an annotation to return
  #                              a unique value. By default it returns the id.
  #           setAnnotationData: Accepts a newly created annotation for
  #                              modification such as adding properties.
  #
  # Returns nothing.
  constructor: ->
    super
    @store = new Offline.Store()

    handlers = {"online", "offline", "beforeAnnotationCreated": "setAnnotationData"}
    for own event, handler of handlers
      if typeof @options[handler] is "function"
        @on(event, jQuery.proxy @options, handler)

  # Internal: Initialises the plugin, called by the Annotator object once a
  # new instance of the object has been created and the @annotator property
  # attached.
  #
  # Returns nothing.
  pluginInit: ->
    @loadAnnotationsFromStore()
    if @isOnline() then @online() else @offline()
    jQuery(window).bind(online: @_onOnline, offline: @_onOffline)

  # Public: Publishes the "online" event on the plugin. All registered
  # subscribers recieve the plugin instance as the first argument.
  #
  # Examples
  #
  #   plugin.on "online", -> alert("We're now online!")
  #   plugin.online() # Alert box is displayed.
  #
  # Returns itself.
  online: ->
    @publish "online", [this]
    this

  # Public: Publishes the "offline" event on the plugin. All registered
  # subscribers recieve the plugin instance as the first argument.
  #
  # Examples
  #
  #   plugin.on "offline", -> alert("We're now offline!")
  #   plugin.offline() # Alert box is displayed.
  #
  # Returns itself.
  offline: ->
    @publish "offline", [this]
    this

  # Public: Checks to see if the browser currently has a network connection.
  #
  # Examples
  #
  #   if plugin.isOnline() then backupData()
  #
  # Returns true if the browser has connectivitiy.
  isOnline: -> window.navigator.onLine

  # Public: Loads all stored annotations into the page. This should generally
  # only be called on page load.
  #
  # Examples
  #
  #   offline.loadAnnotationsFromStore()
  #
  # Returns itself.
  loadAnnotationsFromStore: ->
    annotations = @store.all(Offline.ANNOTATION_PREFIX)
    @annotator.loadAnnotations(annotations)
    this

  # Public: Updates the locally stored copy of the annotation.
  #
  # annotation - An annotation object.
  #
  # Examples
  #
  #   onAnnotationUpdated = (ann) ->
  #     store.updateAnnotation(ann)
  #
  # Returns itself.
  updateAnnotation: (annotation) ->
    key = @keyForAnnotation(annotation)
    storable = {}
    for own prop, value of annotation when prop isnt "highlights"
      storable[prop] = value
    @store.set(key, storable)
    this

  # Public: Removes the annotation from local storage.
  #
  # annotation - An annotation object.
  #
  # Examples
  #
  #   onAnnotationDeleted = (ann) ->
  #     store.removeAnnotation(ann)
  #
  # Returns itself.
  removeAnnotation: (annotation) ->
    key = @keyForAnnotation(annotation)
    @store.remove(key)
    this

  # Internal: Retrieves a key for an annotation. This can be customised using
  # the getUniqueKey() option. By default it will use the "id" property on the
  # annotation.
  #
  # annotation - An annotation object.
  #
  # Examples
  #
  #   key = @keyForAnnotation(annotation)
  #   store.set(key, annotation)
  #
  # Returns a key to be used to store the annotation.
  keyForAnnotation: (annotation) ->
    Offline.ANNOTATION_PREFIX + @options.getUniqueKey.call(this, annotation, this)

  # Event callback for the "online" window event.
  #
  # event - A jQuery event object.
  #
  # Returns nothing.
  _onOnline:  (event) => @online()

  # Event callback for the "offline" window event.
  #
  # event - A jQuery event object.
  #
  # Returns nothing.
  _onOffline: (event) => @offline()

  # Event callback for the "annotationCreated" event.
  #
  # annotation - An annotation object.
  #
  # Returns nothing.
  _onAnnotationCreated: (annotation) ->
    @updateAnnotation(annotation)

  # Event callback for the "annotationUpdated" event.
  #
  # annotation - An annotation object.
  #
  # Returns nothing.
  _onAnnotationUpdated: (annotation) ->
    @updateAnnotation(annotation)

  # Event callback for the "annotationDeleted" event.
  #
  # annotation - An annotation object.
  #
  # Returns nothing.
  _onAnnotationDeleted: (annotation) ->
    @removeAnnotation(annotation)
