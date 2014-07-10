Offline Annotator Plugin
========================

A plugin for the [OKFN Annotator][#annotator] that stores all created
annotations in local storage if it's supported by the current browser. The
plugin will also fire "online" and "offline" events when the browsers
connectivity changes.

There is a [demo available online][#demo].

[#demo]: http://aron.github.com/annotator.offline.js/index.html
[#annotator]: http://okfnlabs.org/annotator/

Usage
-----

The plugin requires the _annotator.js_ and _annotator.css_ to be included on the page. See the annotator [Getting Started][#ann-install] guide for instructions then simply include the _annotator.offline.js_ file in your page.
This can be downloaded from the GitHub [download page][#download].

[#download]: http://github.com/aron/annotator.offline.js/downloads

```html
<link rel="stylesheet" href="./annotator.css" />
<script src="./jquery.js"></script>
<script src="./annotator.js"></script>
<script src="./annotator.offline.js"></script>
```

Then set up the annotator as usual calling `"addPlugin"`.

```javascript
jQuery('#content').annotator().annotator("addPlugin", "Offline", {
  online: function (plugin) {
    // Do something when the browser is online.
  },
  offline: function (plugin) {
    // Do something when the browser goes offline.
  }
});
```

[#ann-install]: https://github.com/okfn/annotator/wiki/Getting-Started

Options
-------

 - `online`: A function that is called when the plugin goes online. Receives
   the offline plugin object as an argument.
 - `offline`: A function that is called when the plugin goes offline. Receives
   the plugin object as an argument.
 - `getUniqueKey`: A function that accepts an annotation and should return a
    unique value for it. By default it will return the id property (if no such
    property exists it will add one).
 - `setAnnotationData`: A function that receives an annotation. This should be
   used to add data (such as an id) to newly created annotations. It is also
   called when the annotation is loaded from the localStorage. It is the
   equivalent to subscribing to the `"beforeAnnotationCreated"` and
   `"beforeAnnotationLoaded"` events.
 - `shouldLoadAnnotation`: A function that should return true if the
   annotation should be loaded in this page. This should be used if you have
   many pages on your site being annotated to prevent the annotator trying to
   load them all each time.

Loading Annotations Conditionally
---------------------------------

If you have a single page application (such as an ebook reader) you may wish
for finer grained control over which annotations are loaded. To do this
you can use a combination of `setAnnotationData` and `shouldLoadAnnotation`
options:

```javascript
jQuery('#content').annotator().annotator("addPlugin", "Offline", {
  setAnnotationData: function (ann) {
    // Add page specific data to the annotation on creation.
    if (!ann.page) {
      ann.page = getCurrentPage(); // getCurrentPage() would return the current page number
    }
  },
  shouldLoadAnnotation: function (ann) {
    // Return true if the annotation should be loaded into the current view.
    return ann.page === getCurrentPage();
  }
});

```

API
---

There are various events available on the Offline plugin that can be used in
your own code.

### Events

Events can be subscribed to on the annotator or offline plugin object.

```javascript
// Get the annotator by calling .data() on the selector it was called on.
var annotator = $("#content").data("annotator");

// Sync with server when online.
annotator.subscribe("online", function (plugin) {
  syncAnnotationsWithServer(plugin.annotations());
});

// Convert timestamp to Date object on load.
annotator.subscribe("beforeAnnotationLoaded", function (annotation) {
  var date = new Date();
  date.setTime(Date.parse(annotation.timestamp));
  annotation.timestamp = date;
});
```

 - `"online"`: Called when the browser returns online. Receives the Offline
   plugin object as an argument.
 - `"offline"`: Called when the browser goes offline. Receives the Offline
   plugin object as an argument.
 - `"beforeAnnotationLoaded"`: Called when an annotation is extracted from
   localStorage. It can be used to de-serialise properties.
 - `"annotationLoaded"`: Called after `"beforeAnnotationLoaded"` receives the
   annotation and the Offline plugin as arguments.

Development
-----------

If you're interested in developing the plugin. You can install the developer
dependancies by running the following command in the base directory:

    $ npm install .

Development requires _node_ and _npm_ binaries to be intalled on your system.
It was developed with `node --version 0.6.6` and `npm --version 1.1.0 -beta-4`.
Details on installation can be found on the [node website][#node].

Then visit http://localhost:8000 in your browser.

There is a _Cakefile_ containing useful commands included.

    $ cake serve # serves the directory at http://localhost:8000 (requires python)
    $ cake test  # opens the test suite in your browser
    $ cake watch # compiles .coffee files into lib/*.js when they change
    $ cake build # creates a production pkg/annotator.offline.js file
    $ cake pkg   # creates a zip file of production files

[#node]: http://nodejs.org/

### Repositories

The `development` branch should always contain the latest version of the
plugin but it is not guaranteed to be in working order. The `master` branch
should always have the latest stable code and each release can be found under
an appropriately versioned tag.

### Testing

Unit tests are located in the test/ directory and can be run by visiting
http://localhost:8000/test/index.html in your browser.

### Frameworks

The plugin uses the following libraries for development:

 - [Mocha][#mocha]: As a BDD unit testing framework.
 - [Sinon][#sinon]: Provides spies, stubs and mocks for methods and functions.
 - [Chai][#chai]:   Provides all common assertions.

[#mocha]: http://visionmedia.github.com/mocha/
[#sinon]: http://chaijs.com/
[#chai]:  http://sinonjs.org/docs/

License
-------

This plugin was commissioned and open sourced by Compendio.

Copyright 2012, Compendio Bildungsmedien AG
Neunbrunnenstrasse 50
8050 Zürich
www.compendio.ch

Released under the [MIT license][#license]

[#license]: https://github.com/aron/annotator.offline.js/blob/development/README.md
