---
date: 2019-05-09
title: Free PubSub in Elixir Phoenix Application
---
If you need a pubsub, to connect LiveViews for example just use YourAppWeb.Endpoint.

```elixir
YourAppWeb.Endpoint.subscribe("topic")
```

```elixir
YourAppWeb.Endpoint.broadcast("topic", "event", %{data: "data"})
```

```elixir
def handle_info(%{event: "event", topic: "topic", payload: payload}) do
  # Do whatever you want
end
```
