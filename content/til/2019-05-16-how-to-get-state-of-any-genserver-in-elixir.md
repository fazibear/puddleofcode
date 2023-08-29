---
date: 2019-05-16
title: How to Get State of Any GenServer in Elixir?
---
To get state of any process in erlang/elixir use `:sys.get_state/1`


By name:
```elixir
:sys.get_state(MyGenServer)
```

By pid:
```elixir
:sys.get_state(pid)
```
