---
date: 2019-08-23
slug: how-to-use-elixir-s-compiler-to-avoid-typos
title: How to Use Elixir's Compiler to Avoid Typos
tags:
  - elixir
  - compiler
  - contracts
  - typos

section: story
image: /assets/images/stories/typo.jpg
author: Michał Kalbarczyk
author_image: ../images/authors/michal.png
---

In this article, I want to describe how you can use elixir metaprogramming to avoid some runtime errors caused by typos. If you're passing around some handcrafted messages ex. `%{name: "app_one_hello", payload: "payload"}` you can easily introduce errors. Sending `app_one_hello` and listening for `app_ane_hello` will not make your system works correctly. Imagine you have thousands of messages. It's really hard to manage them like that. To make things better, you can create a list of all messages and generate functions to send and receive them. Now when you will create a typo, elixir's compiler will tell you!

## Example application

Under the umbrella we have 3 apps.

- `dispatcher`
- `app_one`
- `app_two`

`app_one` and `app_two` will send and receive messages managed by the `dispatcher`

### The Dispatcher

This it the application we will be working on. This is the main module:

```elixir
defmodule Dispatcher do
  @moduledoc """
  Dispatcher is for dispatching messages.
  """

  use GenStage
  require Logger

  def start_link(_opts) do
    GenStage.start_link(__MODULE__, [], name: __MODULE__)
  end

  def message(message) do
    GenStage.cast(__MODULE__, message)
  end

  def init(_) do
    {:producer, %{enabled: true}, dispatcher: GenStage.BroadcastDispatcher}
  end

  def handle_info(:disable, state) do
    {:noreply, [], %{state | enabled: false}}
  end

  def handle_info(:enable, state) do
    {:noreply, [], %{state | enabled: true}}
  end

  def handle_cast(message, %{enabled: true} = state) when is_map(message) do
    Logger.info("Dispatch message: #{inspect(message)}")
    {:noreply, [message], state}
  end

  def handle_demand(_demand, state), do: {:noreply, [], state}
end
```

This is simple pubsub using `gen_stage`. The message will be send to any subscribed processes.

To make it easier to manage each app, there is also a `Listener`

```elixir
defmodule Dispatcher.Listener do
  @moduledoc """
  Listener for messages from dispatcher
  """
  @callback on_message(message :: map) :: any

  @doc false
  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour Dispatcher.Listener

      use GenStage

      def start_link(opts) do
        GenStage.start_link(__MODULE__, opts, name: __MODULE__)
      end

      def init(state) do
        {:consumer, state, subscribe_to: [Dispatcher]}
      end

      def handle_events(messages, _from, state) do
        for message <- messages do
          on_message(message)
        end

        {:noreply, [], state}
      end

      def on_message(_), do: :nothing

      defoverridable on_message: 1
    end
  end
end
```

This module makes easier to listen to messages.

Now you can send message like this:

```elixir
Dispatcher.message(%{name: "app_one_hello", payload: "some_kind_of_payload"}
```

And receive it with a little module:

```elixir
defmodule AppOne.Listener do
  @moduledoc """
  AppOne listener
  """
  use Dispatcher.Listener

  def on_message(%{name: "app_one_hello", payload: payload}) do
    AppOne.hello(payload)
  end

  def on_message(_), do: :nothing
end

```

It works fine, but you can easily type `app_twe_hello` instead of `app_two_hello`. Also when you have thousands of messages you need to search the codebase for names. It might be difficult.

Why not use the compiler to track such errors?

### Metaprogramming

We will use an elixir's neat feature for that!. Metaprogramming.

First we need a module to store all of of the messages:

```elixir
defmodule Dispatcher.Message do
  @moduledoc """
  List of all messages
  """

  @list ~w[
      app_one_hello
      app_two_hello
    ]a

  def list, do: @list
end
```

And functions to send them:

```elixir
defmodule Dispatcher.Message do
  @moduledoc """
  List of all messages
  """

  @list ~w[
      app_one_hello
      app_two_hello
    ]a

  def list, do: @list

  Enum.each(@list, fn message ->
    def unquote(message)(payload \\ nil) do
      GenStage.cast(
        Dispatcher,
        {:message,
         %{
           name: unquote(message),
           payload: payload
         }}
      )
    end
  end)
end
```

Great! We can now send a message with:

```elixir
Dispatcher.Message.app_one_hello("some_payload")
```

There are few advantages of this:

- compiler will tell us about typos
- IDE will autocomplete function name

Now we gonna take care of listener.

```elixir
defmodule Dispatcher.Listener do
  @moduledoc """
  Listener for messages from dispatcher
  """
  @callback on_message(message :: map) :: any

  @doc false
  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour Dispatcher.Listener

      use GenStage
      import Dispatcher.Listener

      def start_link(opts) do
        GenStage.start_link(__MODULE__, opts, name: __MODULE__)
      end

      def init(state) do
        {:consumer, state, subscribe_to: [Dispatcher]}
      end

      def handle_events(messages, _from, state) do
        for message <- messages do
          on_message(message)
        end

        {:noreply, [], state}
      end

      def on_message(_), do: :nothing
      defoverridable on_message: 1
    end
  end

  Enum.each(Dispatcher.Message.list(), fn message ->
    defmacro unquote(message)(payload, block) do
      message = Macro.escape(unquote(message))
      payload = Macro.escape(payload)
      block = Macro.escape(block, unquote: true)

      quote bind_quoted: [message: message, payload: payload, block: block] do
        def on_message(%{name: unquote(message), payload: unquote(payload)}), do: unquote(block)
      end
    end
  end)

  defmacro other(name, payload, block) do
    name = Macro.escape(name)
    payload = Macro.escape(payload)
    block = Macro.escape(block, unquote: true)

    quote bind_quoted: [name: name, payload: payload, block: block] do
      def on_message(%{name: unquote(name), payload: unquote(payload)}), do: unquote(block)
    end
  end
end
```

Looks a little bit complicated, but it's not!

We've just built a simple DSL for receiving messages. Now the listening module looks like this:

```elixir
defmodule AppOne.Listener do
  @moduledoc """
  AppOne listener
  """
  use Dispatcher.Listener

  app_one_hello(payload) do
    AppOne.hello(payload)
  end

  other(_, _) do
    :nothing
  end
end
```

Again! Typos are handled by the compiler, and we can use IDE to complete functions names.

### Summary

I've used message name for all of the functions. If you want you can use prefix those function. For example `send_app_one_hello` and `on_app_one_hello`.

Check out my github for example app:

- [first version](https://github.com/fazibear/avoiding_typos/tree/master)

- [with metaprogramming](https://github.com/fazibear/avoiding_typos/tree/with_meta)
