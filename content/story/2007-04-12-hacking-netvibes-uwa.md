---
date: 2007-04-12
title: Hacking Netvibes UWA
tags:
  - javascript
  - netvibes

image: /images/stories/archived.jpg
---

>UWA is the new Netvibes API. Through it, your Netvibes widgets will be available on every widget platforms or blog systems: Netvibes of course, but also Google IG, Apple Dashboard and many more...

Cool, but there is a little problem. UWA API don't support window and document object. No way it can't be ... aha! there is a solution :)

Script tag:

```js
onLoadPlus = function(window) {
  var content = "URL: "+window.document.URL;
  content += "Location: "+window.location;
  content += "Title: "+window.document.title;
  widget.setBody(content);
}

widget.onLoad = function() {
  widget.body.getElementsByTagName("a")[0].onclick()
}
```

Body tag:

```html
<a style="display:none" onclick="onLoadPlus(window)"></a>
```
This example works only with netvibes, with google window point to iframe :/

Check out example module [here](http://www.netvibes.com/subscribe.php?module=UWA&amp;moduleUrl=http%3A%2F%2Ffazibear.googlepages.com%2Fuwahack.html).
