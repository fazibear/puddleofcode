---
date: 2008-03-29
slug: gedit-with-multi-terminal
title: GEdit With Multi Terminal
tags:
  - gedit
  - python

section: story
image: /assets/images/stories/archived.jpg
author: Michał Kalbarczyk
author_image: ../images/authors/michal.png
---

[GEdit](http://www.gnome.org/projects/gedit/) is nice developer editor for [GNOME](http://www.gnome.org/). [Textmate](http://macromates.com/) like snippets, file browser and embedded terminal. Last one is a nice feature, but default plugin gives you only one terminal. But wait, plugins are written in python. This is my third attempt to modify python code... It was not so bad, after few `print()`, `dir()`, and `id()` I can add and remove terminal windows within gedit :)

How to install ? Copy all files to `~/.gnome2/gedit/plugins`, disable terminal plugin, restart gedit and enable mterminal plugin.

How to use it ? To add new terminal right-click on terminal window and choose 'New Terminal'. If you want to remove it, right-click and choose 'Remove Terminal'.

<del>Plugin/Sources are located [here](http://fazibear.googlepages.com/mterminal.tar.gz)</del>.

I hope you like it.

This plugin is now on [github](http://github.com/fazibear/gedit-mterminal).
