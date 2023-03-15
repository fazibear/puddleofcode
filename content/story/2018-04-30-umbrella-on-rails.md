---
date: 2018-04-30
slug: umbrella-on-rails
title: Umbrella On Rails
tags:
  - rails
  - umbrella
  - ruby

section: story
image: /assets/images/stories/railsumbrella.png
author: Michał Kalbarczyk
author_image: ../images/authors/michal.png
---

So you want to have a Rails application with few other applications inside? Can I have a Rails application inside a Rails application? If you ever asked yourself such a question, you’ll find an answer. Let’s start!

## What is an Umbrella?

Umbrella application is an application that contains other full featured, complete applications inside. For example. You have few small applications for serving few different APIs, some static content and administration panel. As a good start you can join them together under one umbrella application. It’s easier to deploy, but when it grows, it is very easy to decouple.

## Creating an umbrella

The first thing we should build is the umbrella application.

```bash
$ rails new umbrella_app
```

We will stop here for a while. Just to clarify. You can’t have multiple different Rails apps running simultaneously in one environment (server). Why ? Because of namespaces. You have to call `Rails.appllication` to run a single app. That’s where `Rails::Engine` comes in. It is something we’re looking for: a namespaced Rails application that works within another Rails application. Despite some downsides (it can only work within a Rails app, and not some other Ruby framework), it’s a good start when you want to split your monolithic app. So as you might expect next step is to create `Rails::Engine`:

## Creating Rails Engine

Let’s assume that we will have all applications into apps folder. Now we can generate our first rails engine.

```bash
$ rails plugin new --mountable apps/sub_rails
```

And switch to its directory.

```bash
$ cd apps/sub_rails
```

Here we’ve got another rails application. The first thing we have to do is to fix `sub_rails.gemfile`. Change `homepage`, `summary`, and `description` do something more descriptive and remove all `TODO`.

The first question is: Can I start this application alone? Yes! To check if sub-application is working just type:

```bash
$ cd test/dummy
$ rails s
```

Your application contains a dummy rails application that mounts your sub-application. It’s used for testing purposes, but you can also check how you sub-application working.

So, we should make our sub-application to serve something. Right? Make sure we’re in `apps/sub_rails` application dir.

```bash
$ rails g controller hello
```

And add `index` route to our new controller: `apps/sub_rails/app/controller/sub_rails/hello_controller.rb`:

```ruby
require_dependency “sub_rails/application_controller”
module SubRails
  class HelloController < ApplicationController
    def index
      render text: “Hello from sub_rails!”
    end
  end
end
```

Also, we need to change `apps/sub_rails/app/config/routes.rb`:

```ruby
SubRails::Engine.routes.draw do
  root to: "hello#index"
end
```

Just check if it works:

```bash
$ cd test/dummy
$ rails s
```

And go to http://localhost:3000/sub_rails in your browser. Yay! It works! Good.

Now let’s integrate our sub-application with our umbrella app. We have to change directory to umbrella app. And this line to your `Gemfile`

```ruby
gem 'sub_rails', path: 'apps/sub_rails'
```

Of course, we need to bundle. And don’t forget to add it to `config/routes.rb`

```ruby
Rails.application.routes.draw do
   mount SubRails::Engine, at: 'my_sub_rails'
end
```

And voila! We’ve mounted our sub-application at `/my_sub_rails`. Testing time!

```bash
$ rails s
```

Check http://localhost:3000/my_sub_rails. Congratulations. You’ve just build your first rails engine.

## What’s next?

It’s not the end of the story. You can add any `rack` application and mount it whatever you like in you umbrella application. You can use `Sinatra`, `Roda`, `Grape` or even static application build by `npm`. If you find this interested, and want to know how to add these? Just let me know. Will write about it.
