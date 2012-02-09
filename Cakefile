fs   = require "fs"
FFI  = require "node-ffi"
libc = new FFI.Library(null, "system": ["int32", ["string"]])
run  = libc.system
pkg  = require "package"

VERSION = pkg.version
PROJECT = "annotator.offline"
OUTPUT  = "pkg/#{PROJECT}.min.js"
COFFEE  = "`npm bin`/coffee"
UGLIFY  = "`npm bin`/uglifyjs"
HEADER  = """
/*  Offline Annotator Plugin - v#{VERSION}
 *  Copyright 2012, Compendio <www.compendio.ch>
 *  Released under the MIT license
 *  More Information: http://github.com/aron/annotator.offline.js
 */
"""

task "watch", "Watch the coffee directories and output to ./lib", ->
  run "#{COFFEE} --watch --output ./lib ./src"

task "serve", "Serve the current directory", ->
  run "python -m SimpleHTTPServer 8000"

task "test", "Open the test suite in the browser", ->
  run "open http://localhost:8000/test/index.html"

option "", "--no-minify", "Do not minify build scripts with `cake build`"
task "build", "Concatenates and minifies JS", (options) ->
  MINIFY = if options['no-minify'] then "cat" else UGLIFY
  run """
  mkdir -p pkg && echo "#{HEADER}" > #{OUTPUT} && 
  cat src/offline.coffee src/offline/*.coffee | #{COFFEE} --stdio --print | 
  #{MINIFY} >> #{OUTPUT} && echo "" >> #{OUTPUT}
  """

task "pkg", "Creates a zip package with minified scripts", ->
  invoke "build"
  run "zip -jJ pkg/#{PROJECT}.#{VERSION}.zip #{OUTPUT}"
