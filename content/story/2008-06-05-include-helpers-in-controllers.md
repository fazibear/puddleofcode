---
date: 2008-06-05
slug: include-helpers-in-controllers
title: Include helpers in controllers
tags:
  - ruby
  - rails

section: story
image: /assets/images/stories/archived.jpg
author: Michał Kalbarczyk
author_image: ../images/authors/michal.png
---

Yes, I know!

>Helpers are modules that provide methods which are automatically usable in your view.

But somtimes you want to use it in controllers ;)
This is my solution. Helpers are available in module named 'Helpers', so they don't brake anything. All rails helpers and named routes are included by default.
This is simple usage:

```ruby
class ExampleController < ApplicationController
  include_helper ApplicationHelper, PicturesHelper
  def show
    ...
    flash[:notice] = Helpers::flash_with_picture('Hello from helper')
    ...
  end
end
```

And method to add to ApplicationController class.

```ruby
class ApplicationController < ActionController::Base
  def self.include_helper(*args)
    require 'action_controller/integration'
      class_eval do
        helpers = const_defined?('Helpers') ? const_get('Helpers') : Module.new do
          @@controller = ActionController::Integration::Session.new
          def self.method_missing(method, *args, &block)
            if @@controller && method.to_s =~ /_path$|_url$/
              @@controller.send(method, *args, &block)
            else
              raise NoMethodError, "undefined method `#{method}' for #{self}"
            end
          end
        end
      ActionView::Helpers.constants.each do |constant|
        helpers.extend ActionView::Helpers.const_get(constant) if ActionView::Helpers.const_get(constant).instance_of?(Module)
      end
      if args.instance_of?(Array)
        args.each do |helper|
          helpers.extend helper if helper.instance_of?(Module)
        end
      elsif args.instance_of?(Module)
        helpers.extend args
      end
      const_set( 'Helpers', helpers ) unless const_defined?('Helpers')
    end
  end
end
```
