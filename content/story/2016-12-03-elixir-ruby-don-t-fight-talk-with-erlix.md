---
date: 2016-12-03
slug: elixir-ruby-don-t-fight-talk-with-erlix
title: Elixir, Ruby, don’t fight. Talk… with Erlix
tags:
  - elixir
  - erlang
  - ruby
  - erlix

section: story
image: /assets/images/stories/erlix.png
author: Michał Kalbarczyk
author_image: ../images/authors/michal.png
---

This article describes another way, how Elixir and Ruby can talk to each other. We will use [Erlix](https://github.com/KDr2/erlix) this time. This method makes Ruby process act like the Erlang node, which is connected to Erlang VM over the network.

We will make some kind of chat between Ruby and Elixir. There will be two separate parts. Elixir and Ruby project.

## Elixir Project

We need to create new Elixir project.

```bash
$ mix new chat_ex
$ cd chat_ex
```

And add mod to application:

```elixir
defmodule ChatEx.Mixfile do
  use Mix.Project

  def project do
    [app: :chat_ex,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [
      applications: [:logger],
      mod: {ChatEx, []}
    ]
  end

  defp deps do
    []
  end
end
```

We need a little bit configuration

```elixir
@process_name :ex_rb
@ruby_process_name :ruby
```

_@process_name is_ a name of process that will receive messages from Ruby
_@ruby_process_name_ is the name of the process, that will store PID of the process that ruby send just after connecting to the node.

Ok, write a function that will be executed when out application start.

```elixir
def start(_type, _args) do
  pid = spawn(&receive_messages/0)
  Process.register(pid, @process_name)
  read_line
end
```

When our application starts we need to spawn a process that will receive messages from ruby and register it with a name so ruby can locate it. Also, we need to start a loop that will read messages from the console and send it to Ruby.

We need two types of messages. One message will send us Ruby process PID, we will need to save it for future usage. And second one that will receive our messages.

```elixir
def receive_messages do
  receive do
    # message with process pid
    {:register, pid} ->
      IO.puts "Ruby connected!"
      Agent.start_link(fn -> pid end, name: @ruby_process_name)
    # message with message
    {:message, message} ->
      IO.puts "Message from ruby: #{message}"
  end
 receive_messages
end
```

Nice, while register message will come, we start a new Agent that will store Ruby process PID. When we receive a message with text, we will just display it on the console.

What about reading from the console ? Right! The read_line function will do that.

```elixir
def read_line do
  case IO.read(:stdio, :line) do
    :eof -> :ok
    {:error, reason} -> IO.puts "Error: #{reason}"
    data ->
      if Process.registered |> Enum.member?(@ruby_process_name) do
        ruby = Agent.get(@ruby_process_name, &(&1))
        send ruby, data
      end
  end
  read_line
end
```

When we will receive any line from STDIO, we will send it to our Ruby process. We can get pid of this process from Agent, and send our data.

We’re finished! Our module looks like this:

```elixir
defmodule ChatEx do
  use Application

  @process_name :ex_rb
  @ruby_process_name :ruby

  def receive_messages do
    receive do
      {:register, pid} ->
        IO.puts "Ruby connected!"
        Agent.start_link(fn -> pid end, name: @ruby_process_name)
      {:message, message} ->
        IO.puts "Message from ruby: #{message}"
    end
    receive_messages
  end

  def read_line do
    case IO.read(:stdio, :line) do
      :eof -> :ok
      {:error, reason} -> IO.puts "Error: #{reason}"
      data ->
        if Process.registered |> Enum.member?(@ruby_process_name) do
          ruby = Agent.get(@ruby_process_name, &(&1))
          send ruby, data
        end
    end
    read_line
  end

  def start(_type, _args) do
    pid = spawn(&receive_messages/0)
    Process.register(pid, @process_name)
    read_line
  end
end
```

We’ve got all we need, let’s move to Ruby Project!

## Ruby Project

Also in Ruby, we need to create a Ruby project.

```bash
$ mkdir chat_rb
$ cd chat_rb
$ bundle init
```

Add `erlix` gem to Gemfile:

```ruby
# frozen_string_literal: true
source 'https://rubygems.org'
gem 'erlix'
```

and bundle it.

```bash
$ bundle
```

Now we’re creating the main file of our application. First, we need to require bundler to include all dependencies. So let’s create file named `main.rb`

```ruby
#!/usr/bin/ruby
require 'bundler'
Bundler.require
```

Next, we will need a few constants:

```ruby
COOKIE = 'cookie'
HOST = `hostname -s`.strip
NODE_NAME = 'ruby'
DST_NODE_NAME = 'elixir'
DST_NODE = "#{DST_NODE_NAME}@#{HOST}"
DST_PROC = 'ex_rb'
```

So, let’s describe them:

- _COOKIE_ is a name of Erlang cookie. Nodes to communicate to each other have to have the same name.
- _HOST_ host that we will connect to, in this case, is our computer
- _NODE_NAME_ name of node written in ruby
- _DST_NODE_NAME_ name of node that we will connect to
- _DST_NODE_ full name of node that we connect to
- _DST_PROC_ name of process that will receive our messages

We’ve got all information needed to connect.

```ruby
Erlix::Node.init(NODE_NAME, COOKIE)
connection = Erlix::Connection.new(DST_NODE)
```

Fist line will initialize our node, next one will connect to Erlang node. Just after connection we need to send registration message, so Elixir will know that we’re connected, and save out PID.

```ruby
connection.esend(
 DST_PROC,
 Erlix::Tuple.new([
   Erlix::Atom.new('register'),
   Erlix::Pid.new(connection)
 ])
)
```

We’re registered, next, we need a thread that will receive messages from Elixir, and print them on the console.

```ruby
Thread.new do
 while true do
   message = connection.erecv
   puts 'Message from elixir: #{message.message.data}'
 end
end
```

OK, the missing part is a loop that reads data from the console and sends them to Elixir.

```ruby
while true
  input = STDIN.gets
  connection.esend(
    DST_PROC,
    Erlix::Tuple.new([
      Erlix::Atom.new("message"),
      Erlix::Atom.new(input)
    ])
  )
end
```

And we’re done! Our final script will look like this:

```ruby
#!/usr/bin/ruby

require 'bundler'
Bundler.require

COOKIE = 'cookie'
HOST = `hostname -s`.strip
NODE_NAME = 'ruby'
DST_NODE_NAME = 'elixir'
DST_NODE = "#{DST_NODE_NAME}@#{HOST}"
DST_PROC = 'ex_rb'

Erlix::Node.init(NODE_NAME, COOKIE)

connection = Erlix::Connection.new(DST_NODE)

puts "Connected to #{DST_NODE}"

connection.esend(
  DST_PROC,
  Erlix::Tuple.new([
    Erlix::Atom.new("register"),
    Erlix::Pid.new(connection)
  ])
)

Thread.new do
  while true do
    message = connection.erecv
    puts "Message from elixir: #{message.message.data}"
  end
end

while true
  input = STDIN.gets
  connection.esend(
    DST_PROC,
    Erlix::Tuple.new([
      Erlix::Atom.new("message"),
      Erlix::Atom.new(input)
    ])
  )
end
```

## Connecting…

We need to start our Elixir application with parameters that we used in Ruby project.

```bash
$ cd chat_ex
$ elixir --sname elixir --cookie cookie  -S mix run
```

Compiling… Done! Elixir node run, now Ruby.

```bash
$ cd chat_rb
$ ruby main.rb
```

Great! `Connected to …@…` nice, take a look at Elixir console… `Ruby connected` Wow it works. Let’s send some messages. On Elixir console just type, for example, `hello from elixir` end hit enter! What is on Ruby console ? Our message! `Message from elixir: hello from elixir!` Now from Ruby. Type on ruby console `hello from ruby` again hit enter. What is on elixir console ? Right: `Message from ruby: hello from ruby!` We’re connected. Another great success!

# Unstable!

After some [benchmarks](https://blog.fazibear.me/elixir-ruby-dont-fight-benchmark-9c6f442de37e#.38sn5dr82), I figure out that erlix is very unstable. Erlix crashes after about 1500 messages. Unfortunately, memory management is broken, there is a lot of TODOin the source code.
