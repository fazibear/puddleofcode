---
date: 2007-09-17
title: Ivo Reader Script
tags:
  - ruby

image: /assets/images/stories/archived.jpg
---

This is a ruby rewrite of ivonka.sh script. This simple script read data from standard input or command line parameters using [say.expressivo.com](http://say.expressivo.com/) text to speech reader.

Features:

- english language (default)
- male and female polish voice
- romanian language
- files are player directly from internet
- mplayer as default player

Script can be downloaded from [here](http://fazibear.googlepages.com/ivo.rb).

Simple usage:

```bash
$ ivo.rb "This is simple text"
$ echo "simple text" | ivo.rb
$ cat somefile.txt | ivo.rb
```

Configuration:

- DEFAULT_LANGUAGE - default language
- PLAYER - filename of mp3 player.
- SLEEP - time between http requests in seconds (something about 0.5s)
- SLEEP_ON_FAIL - time after failed http request (it should be something about 1s)
- MAX_TEXT_LENGTH - length that can be converted at one request (for now in 200)

To change reader language, pass a language symbol as parameter while creating ivo object.

```ruby
ivo = Ivo.new :PL #for polish
ivo = Ivo.new :PLM #for polish male voice
ivo = Ivo.new :PLF #for polish female voice
ivo = Ivo.new :RO #for romanian
```
