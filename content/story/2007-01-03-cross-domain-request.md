---
date: 2007-01-03
title: Cross Domain Request
tags:
  - javascript

image: /images/stories/archived.jpg
---

Using this object you can make cross domain requests. Server side php script could be placed in any domain and any server that supports curl, fopen. You can also make your own server side script in any language.

```js
crossDomainRequest.request(
  'http://ws.audioscrobbler.com/1.0/user/RJ/profile.xml',
  function(resp){
    alert(resp)
  }
);
```
Available [here](http://fazibear.googlepages.com/crossDomainRequest.zip).
