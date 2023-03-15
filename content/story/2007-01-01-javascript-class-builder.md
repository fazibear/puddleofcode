---
date: 2007-01-01
slug: javascript-class-builder
title: Javascript Class Builder
tags:
  - javascript

section: story
image: /assets/images/stories/archived.jpg
author: Michał Kalbarczyk
author_image: ../images/authors/michal.png
---

Simple (yet) function that make pseudo class creation simple.

Example class:

```javascript
Class({
  clazz: {
    clazz: function( smth ){
      this.foobar = smth;
    },
    foobar: 'default',
    getFoobar: function(){
      return this.foobar;
    }
  }
})

foo = new clazz('123');
bar = new clazz();

alert( foo.getFoobar() );
alert( bar.getFoobar() );
```

Notice that constructor have same name as class name :) You can download it [here](http://fazibear.googlepages.com/classBuilder.zip).
