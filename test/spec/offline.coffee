describe "Annotator.Plugin.Offline", ->
  Offline = Annotator.Plugin.Offline
  plugin  = null

  beforeEach ->
    plugin = new Annotator.Plugin.Offline()
    plugin.annotator = new Annotator(document.createElement('div'))

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

  describe "#pluginInit()", ->
    it "should load annotations from the store", ->
      target = sinon.stub(plugin, "loadAnnotationsFromStore")
      plugin.pluginInit()
      expect(target).was.called()

  describe "#loadAnnotationsFromStore()", ->
    annotations = []

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

  describe "#updateAnnotation()", ->
    beforeEach ->
      sinon.stub(plugin.store, "set").returns(plugin.store)

    it "should store the annotation in localStorage", ->
      annotation = {id: 1}
      plugin.updateAnnotation(annotation)
      expect(plugin.store.set).was.called()
      expect(plugin.store.set).was.calledWith("annotation.1", id: 1)

    it "should remove the 'highlights' property from the annotation", ->
      annotation = {id: 1, highlights: []}
      plugin.updateAnnotation(annotation)
      expect(plugin.store.set).was.called()
      expect(plugin.store.set).was.calledWith("annotation.1", id: 1)

  describe "#removeAnnotation()", ->
    beforeEach ->
      sinon.stub(plugin.store, "remove").returns(plugin.store)

    it "should remove the annotation from localStorage", ->
      annotation = {id: 1}
      plugin.removeAnnotation(annotation)
      expect(plugin.store.remove).was.called()
      expect(plugin.store.remove).was.calledWith("annotation.1")

  describe "#keyForAnnotation()", ->
    it "should return a unique key for the annotation", ->
      annotation = {id: 1}
      target = plugin.keyForAnnotation(annotation)
      expect(target).to.equal("annotation.1")

  describe "#_onAnnotationCreated()", ->
    it "should insert the annotation into localStorage", ->
      target = sinon.stub(plugin, "updateAnnotation")
      annotation = {id: 1}
      plugin._onAnnotationCreated(annotation)
      expect(target).was.called()
      expect(target).was.calledWith(annotation)

  describe "#_onAnnotationUpdated()", ->
    it "should update the annotation into localStorage", ->
      target = sinon.stub(plugin, "updateAnnotation")
      annotation = {id: 1}
      plugin._onAnnotationUpdated(annotation)
      expect(target).was.called()
      expect(target).was.calledWith(annotation)

  describe "#_onAnnotationDeleted()", ->
    it "should remove the annotation from localStorage", ->
      target = sinon.stub(plugin, "removeAnnotation")
      annotation = {id: 1}
      plugin._onAnnotationDeleted(annotation)
      expect(target).was.called()
      expect(target).was.calledWith(annotation)
