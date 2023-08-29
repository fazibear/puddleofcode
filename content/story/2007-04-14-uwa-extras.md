---
date: 2007-04-14
title: UWA Extras
tags:
  - javascript
  - netvibes

image: /images/stories/archived.jpg
---

Finally, i find a simple and clean way to extend UWA API. Now you can get document, window and even app object from your widget.

All you can do to add to your widget something like this:

```js
var extras = {
  document: (Function("return document;"))(),
  window: (Function("return window;"))(),
  app: (Function("return App;"))()
}
```

After this, you have access to document, window and all your netvibes settings, modules, tabs etc.
Sample code to display all loaded modules:

```js
for(var i=0; i < extras.app.moduleList.length; i++){
  alert(extras.app.moduleList[i].dataObj.title);
}
```

Or tabs:

```js
for(var i=0; i < extras.app.tabList.length; i++){
  alert(extras.app.tabList[i].dataObj.title);
}
```

Display page title and URL:

```js
alert(extras.document.URL);
alert(extras.document.title);
```

Check out working example: [here](http://www.netvibes.com/subscribe.php?module=UWA&moduleUrl=http%3A%2F%2Ffazibear.googlepages.com%2Fuwaextras.html).

Works only in Netvibes environment.
So. Now we have a lot of new options to make some interesting widget :)

You should make your module inlined by checking 'Inline this widget' in edit menu.
