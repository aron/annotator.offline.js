describe "Annotator.Plugin.Offline", ->
  Offline = Annotator.Plugin.Offline
  plugin  = null

  beforeEach ->
    element = document.createElement('div')
    plugin = new Annotator.Plugin.Offline(element)
    plugin.annotator = new Annotator(element)

  afterEach ->
    localStorage.clear()

  it "should be an instance of Annotator.Plugin", ->
    expect(plugin).to.be.an.instanceof(Annotator.Plugin)

  describe ".uuid()", ->
    it "should generate random strings", ->
      total = 0
      generated = {}

      generated[Offline.uuid()] = 1 for index in [1..1000]
      total += 1 for own key of generated

      expect(total).to.equal(1000)

  describe "#options.getUniqueKey()", ->
    it "should return the id for an annotation", ->
      target = plugin.options.getUniqueKey(id: "my-id")
      expect(target).to.equal("my-id")

    it "should assign an id to an anotation that doesn't have one", ->
      ann = {}
      target = plugin.options.getUniqueKey(ann)
      expect(ann).to.have.property("id").to.be.a("string")
      expect(target).to.equal(ann.id)

  describe "#options.shouldLoadAnnotation()", ->
    it "should return true", ->
      expect(plugin.options.shouldLoadAnnotation({})).to.equal(true)

  describe "#pluginInit()", ->
    it "should load annotations from the store", ->
      target = sinon.stub(plugin, "loadAnnotationsFromStore")
      plugin.pluginInit()
      expect(target).was.called()

    it "should listen for changes to the windows online/offline events", ->
      target = sinon.stub(jQuery.fn, "bind")
      plugin.pluginInit()
      expect(target).was.called()
      expect(target).was.calledWith(online: plugin._onOnline, offline: plugin._onOffline)
      jQuery.fn.bind.restore()

    it "should trigger the 'online' event if online", ->
      sinon.stub(plugin, "isOnline").returns(true)
      target = sinon.stub(plugin, "online")
      plugin.pluginInit()
      expect(target).was.called()

    it "should trigger the 'online' event if online", ->
      sinon.stub(plugin, "isOnline").returns(false)
      target = sinon.stub(plugin, "offline")
      plugin.pluginInit()
      expect(target).was.called()

    it "should do nothing if Annotator is not supported", ->
      sinon.stub(Annotator, "supported").returns(false)
      target = sinon.stub(plugin, "loadAnnotationsFromStore")
      plugin.pluginInit()
      expect(target).was.notCalled()

  describe "#online()", ->
    it "should publish the 'online' event", ->
      target = sinon.stub()
      plugin.on "online", target
      plugin.online()
      expect(target).was.called()
      expect(target).was.calledWith(plugin)

  describe "#offline()", ->
    it "should publish the 'offline' event", ->
      target = sinon.stub()
      plugin.on "offline", target
      plugin.offline()
      expect(target).was.called()
      expect(target).was.calledWith(plugin)

  describe "#isOnline()", ->
    nav = window.navigator

    beforeEach ->
      window.navigator = onLine: true

    afterEach ->
      window.navigator = nav

    it "should return true if the browser has connectivity", ->
      expect(plugin.isOnline()).to.equal(true)

    it "should return false if the browser has no connectivity", ->
      window.navigator.onLine = false
      expect(plugin.isOnline()).to.equal(false)

  describe "#loadAnnotationsFromStore()", ->
    annotations = [{id: 1}, {id: 2}, {id: 3}]

    beforeEach ->
      sinon.stub(plugin.store, "all").returns(annotations)
      sinon.stub(plugin.annotator, "loadAnnotations")

    it "should load all annotations from the store", ->
      plugin.loadAnnotationsFromStore()
      expect(plugin.store.all).was.called()
      expect(plugin.store.all).was.calledWith(Offline.ANNOTATION_PREFIX)

    it "should load the annotations into the annotator", ->
      plugin.loadAnnotationsFromStore()
      expect(plugin.annotator.loadAnnotations).was.called()
      expect(plugin.annotator.loadAnnotations).was.calledWith(annotations)

    it "should trigger the 'annotationLoaded' event", ->
      target = sinon.stub()
      plugin.on("annotationLoaded", target)
      plugin.loadAnnotationsFromStore()
      expect(target).was.called()
      expect(target).was.calledWith(annotations[0], plugin)
      expect(target).was.calledWith(annotations[1], plugin)
      expect(target).was.calledWith(annotations[2], plugin)

    it "should trigger the 'beforeAnnotationLoaded' event", ->
      target = sinon.stub()
      plugin.on("beforeAnnotationLoaded", target)
      plugin.loadAnnotationsFromStore()
      expect(target).was.called()
      expect(target).was.calledWith(annotations[0], plugin)
      expect(target).was.calledWith(annotations[1], plugin)
      expect(target).was.calledWith(annotations[2], plugin)

    it "should populate the cache", ->
      plugin.loadAnnotationsFromStore()
      expect(plugin.cache).to.eql(1: annotations[0], 2: annotations[1], 3: annotations[2])

    it "should skip annotations if options.shouldLoadAnnotation() returns false", ->
      plugin.options.shouldLoadAnnotation = (ann) -> ann.id isnt 2
      plugin.loadAnnotationsFromStore()
      expect(plugin.cache).to.eql(1: annotations[0], 3: annotations[2])

  describe "addAnnotation", ->
    annotation = null

    beforeEach ->
      plugin.cache = {}
      annotation =
        id: "test-id"
        text: "test text"
      sinon.stub(plugin.annotator, "setupAnnotation")
      sinon.stub(plugin, "updateStoredAnnotation")

    it "should add the annotation to the Annotator if not loaded", ->
      plugin.addAnnotation(annotation)
      expect(plugin.annotator.setupAnnotation).was.called()
      expect(plugin.annotator.setupAnnotation).was.calledWith(annotation)

    it "should silence the \"annotationCreated\" event if options.silent is true", ->
      plugin.addAnnotation(annotation, silent: true)
      expect(plugin.annotator.setupAnnotation).was.called()
      expect(plugin.annotator.setupAnnotation).was.calledWith(annotation, true)

    it "should update the stored annotation object if loaded", ->
      cached = {id: "test-id"}
      plugin.cache = {"test-id": cached}
      plugin.addAnnotation(annotation)
      expect(plugin.updateStoredAnnotation).was.called()
      expect(plugin.updateStoredAnnotation).was.calledWith(annotation)

    it "should update the stored annotation object if not required by this page", ->
      sinon.stub(plugin.options, "shouldLoadAnnotation").returns(false)
      plugin.addAnnotation(annotation)
      expect(plugin.updateStoredAnnotation).was.called()
      expect(plugin.updateStoredAnnotation).was.calledWith(annotation)

  describe "addAnnotation", ->
    annotation = null

    beforeEach ->
      plugin.cache = {}
      annotation =
        id: "test-id"
        text: "test text"
      sinon.stub(plugin.annotator, "deleteAnnotation")
      sinon.stub(plugin, "removeStoredAnnotation")

    it "should remove the annotation from the Annotator", ->
      plugin.removeAnnotation(annotation)
      expect(plugin.annotator.deleteAnnotation).was.called()
      expect(plugin.annotator.deleteAnnotation).was.calledWith(annotation)

    it "should remove the stored annotation object if not required by this page", ->
      sinon.stub(plugin.options, "shouldLoadAnnotation").returns(false)
      plugin.removeAnnotation(annotation)
      expect(plugin.removeStoredAnnotation).was.called()
      expect(plugin.removeStoredAnnotation).was.calledWith(annotation)

  describe "#updateStoredAnnotation()", ->
    beforeEach ->
      sinon.stub(plugin.store, "set").returns(plugin.store)

    it "should store the annotation in localStorage", ->
      annotation = {id: 1}
      plugin.updateStoredAnnotation(annotation)
      expect(plugin.store.set).was.called()
      expect(plugin.store.set).was.calledWith("annotation.1", id: 1)

    it "should remove the 'highlights' property from the annotation", ->
      annotation = {id: 1, highlights: []}
      plugin.updateStoredAnnotation(annotation)
      expect(plugin.store.set).was.called()
      expect(plugin.store.set).was.calledWith("annotation.1", id: 1)

    it "should add the annotation to the @cache", ->
      annotation   = id: 1
      plugin.cache = 2: {}
      plugin.updateStoredAnnotation(annotation)
      expect(plugin.cache).to.eql(1: annotation, 2: {})

    it "should updated the cached annotation object", ->
      annotation   = id: 1
      plugin.cache = 1: annotation, 2: {}
      plugin.updateStoredAnnotation(id: 1, text: "test")
      expect(plugin.cache[1]).to.equal(annotation)
      expect(plugin.cache[1]).to.eql(id: 1, text: "test")

  describe "#removeStoredAnnotation()", ->
    beforeEach ->
      sinon.stub(plugin.store, "remove").returns(plugin.store)

    it "should remove the annotation from localStorage", ->
      annotation = {id: 1}
      plugin.removeStoredAnnotation(annotation)
      expect(plugin.store.remove).was.called()
      expect(plugin.store.remove).was.calledWith("annotation.1")

    it "should remove the annotation from the @cache", ->
      annotation   = id: 1
      plugin.cache = 1: annotation, 2: {}
      plugin.removeStoredAnnotation(annotation)
      expect(plugin.cache).to.eql(2: {})

  describe "#keyForAnnotation()", ->
    it "should return a unique key for the annotation", ->
      annotation = {id: 1}
      target = plugin.keyForAnnotation(annotation)
      expect(target).to.equal(1)

  describe "#keyForStore()", ->
    it "should return a unique key for the annotation", ->
      annotation = {id: 1}
      target = plugin.keyForStore(annotation)
      expect(target).to.equal("annotation.1")

  describe "#_onOnline()", ->
    it "should set the plugin as online", ->
      target = sinon.stub(plugin, "online")
      plugin._onOnline()
      expect(target).was.called()

  describe "#_onOffline()", ->
    it "should set the plugin as offline", ->
      target = sinon.stub(plugin, "offline")
      plugin._onOffline()
      expect(target).was.called()

  describe "#_onAnnotationCreated()", ->
    it "should insert the annotation into localStorage", ->
      target = sinon.stub(plugin, "updateStoredAnnotation")
      annotation = {id: 1}
      plugin._onAnnotationCreated(annotation)
      expect(target).was.called()
      expect(target).was.calledWith(annotation)

  describe "#_onAnnotationUpdated()", ->
    it "should update the annotation into localStorage", ->
      target = sinon.stub(plugin, "updateStoredAnnotation")
      annotation = {id: 1}
      plugin._onAnnotationUpdated(annotation)
      expect(target).was.called()
      expect(target).was.calledWith(annotation)

  describe "#_onAnnotationDeleted()", ->
    it "should remove the annotation from localStorage", ->
      target = sinon.stub(plugin, "removeStoredAnnotation")
      annotation = {id: 1}
      plugin._onAnnotationDeleted(annotation)
      expect(target).was.called()
      expect(target).was.calledWith(annotation)
