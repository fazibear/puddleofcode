---
date: 2015-04-13
title: MRuby within VST
tags:
  - ruby
  - mruby
  - vst

image: /images/stories/mruby.png
---

From time to time, I want to just do something more than a Rails app. Recently I just looked at MRuby.

The fruit of my effort is an VST plugin that can be scripted with Ruby. One disadvantage is a big CPU usage. But it works.

Just take a look at [github](https://github.com/fazibear/mrubyvst) repo. There are instruction how to build it an use.

For example, the gain effect looks like this:

```ruby
class GainVST
  def initialize
    @gain = 1.0
  end

  def set_parameter(index, value)
    @gain = value if index = 0
  end

  def parameter_name(index)
    index == 0 ? 'Gain' : 'empty'
  end

  def parameter_value(index)
    @gain if index == 0
  end

  def parameter_display_value(index)
    @gain.to_s if index == 0
  end

  def parameter_label(index)
    'dB' if index == 0
  end

  def process(data)
    data[0].map!{ |left | left * @gain}
    data[1].map!{ |right| right * @gain }
    data
  end
end

GainVST.new
```

Nice and clean. Isn't it ?

What can we do next ? HTTP server ? Some midi integration ? We will see.

Hope you enjoy.
