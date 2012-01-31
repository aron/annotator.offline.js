# Helper methods for working with localStorage. Adds support for storing
# objects as serialized JSON, setting expiry times on stored keys and catching
# exceptions.
#
# Caught execeptions can be listened for by subscribing to the "error" event
# which will recieve the error object.
#
# Examples
#
#   store = new Store()
#
#   store.set("name", "Aron")
#   store.get("name") #=> Aron
#   store.remove("name")
#
# Returns a new instance of Store.
Annotator.Plugin.Offline.Store = class Store extends Annotator.Delegator
  # Internal: Prefix for all keys stored by the store.
  @KEY_PREFIX: "annotator.offline/"

  # Internal: Delimeter used to seperate the cache time from the value.
  @CACHE_DELIMITER: "--cache--"

  # Internal: Reference to the global localStorage object.
  @localStorage: window.localStorage

  # Public: Checks to see if the current browser supports local storage.
  #
  # Examples
  #
  #   store = new Store if Store.isSupported()
  #
  # Returns true if the browser supports local storage.
  @isSupported: ->
    try "localStorage" of window and window["localStorage"] isnt null
    catch e then false

  # Public: Get the current time as a unix timestamp in
  # milliseconds.
  #
  # Examples
  #
  #   Store.now() //=> 1325099398242
  #
  # Returns the current time in milliseconds.
  @now: -> new Date().getTime()

  # Public: Extracts all the values stored under the KEY_PREFIX. An additional
  # partial key can be provided that will be added to the prefix.
  #
  # partial - A partial database key (default: "").
  #
  # Examples
  #
  #   values = store.all()
  #   some   = store.all("user") # All keys beginning with "user"
  #
  # Returns an array of extracted keys.
  all: (partial="") ->
    values = []
    prefix = @prefixed(partial)
    for key of localStorage when key.indexOf(prefix) is 0
      value = @get(key.slice(Store.KEY_PREFIX.length))
      values.push(value)
    values

  # Public: Gets a key from localStorage. Checks the expiry of
  # the key when set, if expired returns null.
  #
  # key - The key String to lookup.
  #
  # Examples
  #
  #   store.set("api-key", "12345")
  #   store.get("api-key") #=> "12345"
  #   store.get("non-existant") #=> null
  #
  # Returns the stored value or null if not found.
  get: (key) ->
    value = Store.localStorage.getItem(@prefixed key)
    if value
      value = @checkCache(value)
      @remove(key) unless value
    JSON.parse(value)

  # Public: Sets a value for the key provided. An optional "expires" time in
  # milliseconds can be provided, the key will not be accessble via #get() after
  # this time.
  #
  # All values will be serialized with JSON.stringify() so ensure that they
  # do not have recursive properties before passing them to #set().
  #
  # key   - A key string to set.
  # value - A value to set.
  # time  - Expiry time in milliseconds (default: null).
  #
  # Examples
  #
  #   store.set("key", 12345)
  #   store.set("temporary", {user: 1}, 3000)
  #   store.get("temporary") #=> {user: 1}
  #   setTimeout ->
  #     store.get("temporary") #=> null
  #   , 3000
  #
  # Returns itself.
  set: (key, value, time) ->
    value = JSON.stringify value
    value = (Store.now() + time) + Store.CACHE_DELIMITER + value if time

    try
      Store.localStorage.setItem(@prefixed(key), value)
    catch error
      this.publish('error', [error, this])
    this

  # Public: Removes the key from the localStorage.
  #
  # key - The key to remove.
  #
  # Examples
  #
  #   store.set("name", "Aron")
  #   store.remove("key")
  #   store.get("name") #=> null
  #
  # Returns itself.
  remove: (key) ->
    Store.localStorage.removeItem(@prefixed key)
    this

  # Public: Removes all keys in local storage with the prefix.
  #
  # Examples
  #
  #   store.clear()
  #
  # Returns itself.
  clear: ->
    localStorage = Store.localStorage
    for key of localStorage when key.indexOf(Store.KEY_PREFIX) is 0
      localStorage.removeItem(key)
    this

  # Internal: Applies the KEY_PREFIX to the provided key. This is used to
  # namespace keys in localStorage.
  #
  # key - A user provided key to prefix.
  #
  # Examples
  #
  #   store.prefixed("name") #=> "annotator.readmill/name"
  #
  # Returns a prefixed key.
  prefixed: (key) ->
    Store.KEY_PREFIX + key

  # Internal: Checks the expiry period (if any) of a value extracted from
  # localStorage. Returns the value if it is still valid, otherwise returns
  # null.
  #
  # param - comment
  #
  # Examples
  #
  #   store.checkCache("1325099398242--cache--\"expired\") #=> null
  #   store.checkCache("1325199398242--cache--\"valid\") #=> "valid"
  #
  # Returns extracted value or null if expired.
  checkCache: (value) ->
    if value.indexOf(Store.CACHE_DELIMITER) > -1
      # If the expiry time has passed then return null.
      cached = value.split(Store.CACHE_DELIMITER)
      value = if Store.now() > cached.shift()
      then null else cached.join(Store.CACHE_DELIMITER)
    value
