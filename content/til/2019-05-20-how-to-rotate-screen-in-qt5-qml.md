---
section: til
date: 2019-05-20
slug: how-to-rotate-screen-in-qt5-qml
title: How to Rotate Screen in QT5 QML?
author: Michał Kalbarczyk
author_image: ../images/authors/michal.png
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
