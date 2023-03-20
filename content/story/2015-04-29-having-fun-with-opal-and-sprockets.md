---
date: 2015-04-29
title: Having fun with opal and sprockets
tags:
  - javascript
  - opal
  - ruby
  - sprockets
crosspost_to_medium: true
medium_link: https://medium.com/@fazibear/3c17e0958694

image: /assets/images/stories/opal.png
---

Let's try [Opal](http://opalrb.org). I don't want to setup a Rails application. Just static html with javascript written in Opal, stylesheets in SASS, and HTML in Slim. Also we want to use JQuery like methods to select DOM elements.
We use [sprockets](https://github.com/sstephenson/sprockets), an assets pipeline from rails, and [rails-assets](https://rails-assets.org) to manage javascript libraries.

Let's set this thing up!

```bash
$ mkdir opal-playground
$ cd opal-playground
$ bundle init
```

Bundler initialized, lets add some gems, edit `Gemfile`:

```ruby
source "https://rubygems.org"

source 'https://rails-assets.org' do
  gem 'rails-assets-jquery'
end

gem 'opal'
gem 'opal-jquery'
gem 'slim'
gem 'sass'
```

and install gems

```bash
$ bundle
```

We need to create four folders:

- app - for opal files (compiled to javascript)
- views - for slim templates
- styles - for sass stylesheets

Sprockets uses rack to serve compiled assets, lets make a `config.ru` for that:

```ruby
require 'bundler'
Bundler.require

sprockets = Sprockets::Environment.new.tap do |s|

  # register slim
  s.register_engine '.slim', Slim::Template

  # register opal
  s.register_engine '.rb', Opal::Processor

  # add folders
  s.append_path 'app'
  s.append_path 'views'
  s.append_path 'styles'

  # add paths from opal
  Opal.paths.each do |p|
    s.append_path p
  end

  # add paths from rails-assets
  RailsAssets.load_paths.each do |p|
    s.append_path p
  end
end

Opal::Processor.source_map_enabled = false

map '/' do
  run sprockets
end
```

Let start with `views/index.html.slim` file:

```slim
doctype html
html
  head
    title Hello
    link href='style.css' rel='stylesheet' type='text/css'
    script src='app.js'
  body
    h2#element
    button#button ClickMe
```

Simple, include `style.css` stylesheet, and `app.js` for javascriptis.
Create a styleshet `styles/style.css.sass`:

```sass
body h2
  color: red
```

Finally we can create ruby (opal) file `app/app.js.rb`:

```ruby
# use sprockets directive to include jquery
#= require 'jquery'

require 'opal'
require 'opal-jquery'

Document.ready? do
  # checkout browser console
  puts "Message from opal"

  # add some text to h2
  Element.find('#element').text = "Setting header with Opal"

  # onclick event
  Element.find('#button').on :click do
    Element.find('#element').text = "Button Clicked!"
  end
end
```

We're done, is this working ?

```bash
$ rackup
```

And open [http://localhost:9292/index.html](http://localhost:9292/index.html)! Happy?

You're lazy ? Check out [github repository](https://github.com/fazibear/opal-slim-sass-sprockets-example) or simply:

```
$ git clone git@github.com:fazibear/opal-slim-sass-sprockets-example.git
```
