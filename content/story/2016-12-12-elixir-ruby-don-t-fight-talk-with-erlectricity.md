---
date: 2016-12-12
title: Elixir, Ruby, don’t fight. Talk… with Erlectricity
tags:
  - elixir
  - erlang
  - ruby
  - erlectricity

image: /assets/images/stories/erlectricity.png
---

The third method that allows us to communicate Ruby and Elixir is Erlectricity. It’s only a Ruby gem that you have to open an Erlang Port yourself, also you have to take care of data conversion (on Elixir side). Erlport using same trick underneath. Regardless I want do describe how to connect to Ruby with Erlectricity. Let’s do it!

Install erlectricity gem

```bash
$ gem install erlectricity
```

Generate new elixir project and directory for ruby script

```bash
$ mix new erlectricity_app
$ cd erlectricity_app
$ mkdir priv
$ mkdir priv/ruby
```

In this example, we also try, to sum up two integers in ruby.

```ruby
require 'rubygems'
require 'erlectricity'

receive do |f|
  f.when([:sum_two_integers, Integer, Integer]) do |a, b|
    f.send!([:result, [:ok, a+b]])
    f.receive_loop
  end
end
```

As you can see, Ruby DSL is more like the Elixir. We’re creating a receive loop, match incoming messages, and if matched, send a message back.

I this example, we’re waiting for the message like this `{:sum_two_integers, 1, 2}` and send back message like `{:result, {:ok, 3}}`.

Moving to Elixir part, we have to create a function that will open an Erlang Port to ruby process and send the message to this process.

```elixir
defmodule ErlectricityApp do
  @ruby_echo Application.app_dir(:erlectricity_app, "priv/ruby/sum.rb")

  @command "ruby #{@ruby_echo}"

  def sum_two_integers_in_ruby(one, another) do
    pid = Port.open({:spawn, @command}, [{:packet, 4}, :nouse_stdio, :exit_status, :binary])

    encoded_msg = {:sum_two_integers, one, another} |> encode_data

    pid |> Port.command(encoded_msg)

    receive do
      {_, {:data, data}} ->
      case data |> decode_data do
        {:result, result} -> result
        _ -> {:error, "Unknown message"}
      end
    end
  end

  defp encode_data(data) do
    data |> :erlang.term_to_binary
  end

  defp decode_data(data) do
    data |> :erlang.binary_to_term
  end
end
```

What exactly going on here ?
We need to know where is our ruby script. `@ruby_echo` stores that data. Next one is `@command`, this one stores command that will start or ruby process. Which is ruby with the path to the ruby file.

Our function first launches an Erlang port. Spawn a process with parameters.More about these parameters you can read [here](http://erlang.org/doc/reference_manual/ports.html).

Because we’re using port protocol, we must encode our data. `encode_data` function will do it for us.

Finally, we can send a message to our ruby process and wait for a response. Yes, all things are happening asynchronously.

When we receive a message from Ruby process, we need to decode them withdecode*data function, match if it is a `{:result, *}` message, and return the result.

Fire up `iex` and check if it works

```elxir
$ iex -S mix
Erlang/OTP 19 [erts-8.1] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false]
Compiling 1 file (.ex)
Interactive Elixir (1.3.3) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)> ErlectricityApp.sum_two_integers_in_ruby(1,2)
{:ok, 3}
iex(2)> ErlectricityApp.sum_two_integers_in_ruby(5,2)
{:ok, 7}
iex(3)>
```

Work as expected. We’ve made it. Simple right ?
