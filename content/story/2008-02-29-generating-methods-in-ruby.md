---
date: 2008-02-29
slug: generating-methods-in-ruby
title: Generating Methods in Ruby
tags:
  - ruby
  - tips

section: story
image: /assets/images/stories/archived.jpg
author: Michał Kalbarczyk
author_image: ../images/authors/michal.png
---

I was trying to find a way for generating dynamic methods.
My first attempt was very ugly and use a simple eval:

```ruby
class DynamicMethods
  %w{ one two three }.each do |z|
    eval "def #{z}(param) puts 'Hello from \\'#{z}\\' method with \\''+param+'\\' param' end"
  end
end
```

Hmm... no... all this escape characters ... there must be a better way. And there is. Using %Q{} ...

```ruby
class DynamicMethods
  %w{ one two three }.each do |z|
    eval %Q{
      def #{z}(param)
        puts "Hello form '#{z}' method with '\#{param}' param"
      end
    }
  end
end
```

That's better ... more readable, but i don't have syntax highligt for this whole string. Lets try define_method ...

```ruby
class DynamicMethods
  %w{ one two three }.each do |z|
    define_method z do |param|
      puts "Hello from '#{z}' method with '#{param}' param"
    end
  end
end
```

There it is. No eval, no big strings, just a method name and code block. Beautful. All examples give you same output.

```ruby
DynamicMethods.new.one("hello") # => Hello from 'one' method with 'hello' param
```
