describe "Annotator.Plugin.Offline", ->
  plugin = null

  beforeEach ->
    plugin = new Annotator.Plugin.Offline()

  afterEach ->
    localStorage.clear()

  it "should be an instance of Annotator.Plugin", ->
    expect(plugin).to.be.an.instanceof(Annotator.Plugin)