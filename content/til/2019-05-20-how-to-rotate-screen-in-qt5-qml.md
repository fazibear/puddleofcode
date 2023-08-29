---
date: 2019-05-20
title: How to Rotate Screen in QT5 QML?
---

QML Code:

```js
import QtWebEngine 1.5
import QtQuick 2.10
import QtQuick.Layouts 1.3

Item {
  rotation: 90

  StackLayout {
    width: parent.height
    height: parent.width
    x: (parent.width - parent.height) / 2
    y: -(parent.width - parent.height) / 2
    Widget {}
    Widget {}
  }
}
```
