---
date: 2015-12-13
title: Inesita - What Is The Difference?
tags:
  - opal
  - ruby
  - frontend
  - inesita

image: /images/stories/inesita.png
---

This is another quick post about [Inesita](http://inesita-rb.github.io/). Lot of people asked me about differences to other framework [Clearwater](https://github.com/clearwater-rb/clearwater).
I'll try to describe them all.

#### 1. It's all about frontend

First of all I want to keep Inesita a pure front-end framework. There is no integration with rails or any other backend framework.
Just a browser side with tools to generate new application template, generate static files, etc.

#### 2. Keep It Beautiful

Inesita is cure isn't it ? There is a nice DSL for HTML Markup. And I want to make it even more useful.
Right now render method look like this:

```ruby
def render
  div class: 'monday active' do
    text 'Monday'
  end
end
```

but this shorter version should will be also acceptable in futerue versions

```ruby
def render
  div.monday.active do
    text 'Monday'
  end
end
```

#### 3. Modularity

I want to keep Inesita as small as possible. There is `opal-virtual-dom` gem that is responsible for html markup.
`Store` is a almost empty class where you have to implement data storege that will fit your needs.
And of course live-reload - you can just disable it with if you don't want to use it.

#### 0. Other

I think there are few other minor differences I not include here. Just to keep this post simple, simple and beautiful as Inesita ;)
