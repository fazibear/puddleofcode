---
date: 2007-01-02
title: Cross Browser XSL Wrapper
tags:
  - javascript
  - xslt
  - xml

image: /assets/images/stories/archived.jpg
---

Simple and easy wrapper for transformation XML document with XSL on client side. Supports: Firefox, Opera and IE.

How use it ?

```js
var xml = document.getElementById('xml'); // string or DOM object
var xsl = document.getElementById('xsl'); // string or DOM object
var proc = new xslProcessor();
proc.importStylesheet( xsl );
proc.setParameter( null, 'foo', 'bar' );
document.getElementById('content').innerHTML = proc.transformText( xml );
```

You can get it [here](http://fazibear.googlepages.com/xslWrapper.zip).
