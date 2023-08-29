---
date: 2017-01-23
title: 'Defql: SQL Queries as Elixir Functions'
tags:
  - elixir
  - sql
  - query
  - orm
  - database

image: /images/stories/defql.png
---

Elixir world is functional. There are no objects or instances at all. In this case, I asked myself a question.

> Do I need ORM?

My answer to this question is no.

I need data. Pure data that comes straight from the database. Another question, that comes to my mind.

> Do I need a DSL for querying database?

Another negative answer.

We have a great language created for querying database. SQL, remember?

What if I could create an elixir function that has an SQL body? What if I could use this function exactly like any other Elixir function? It would be great, wouldn’t it?

We can archive that using Elixir’s very powerful macro system. However, this is also a good way to learn how Elixir’s macros work.

To archive that I’ve started writing [Defql](https://github.com/fazibear/defql). [Defql](https://github.com/fazibear/defql) is an Elixir package that provides a simple way to define functions with SQL language. How does it work?

## Querying Database

This package provides the `defquery` macro. With it, you can define the function that contains an SQL query. For example:

```elixir
defmodule UserQuery do
  use Defql

  defquery get_by_blocked(blocked) do
    "SELECT * FROM users WHERE blocked = $blocked"
  end
end
```

Looks very clean, it’s easy to read, and the best part of it, is that it supports parameters. Brilliant!

Calling that function is also very simple.
Depending on given parameter we will get blocked or unblocked users.

```elixir
UserQuery.get_user(false) # => {:ok, []}
UserQuery.get_user(true) # => {:ok, []}
```

Now we can easy query our database, and get a result.

What about `INSERT`, `UPDATE`, and `DELETE`? Good question! You can create those queries with `defquery`, but there is another method.

## CRUD

This package also contains other macros. Take a look at this example:

```elixir
defmodule UserQuery do
  use Defql

  defselect get(conds), table: :users
  definsert add(params), table: :users
  defupdate update(params, conds), table: :users
  defdelete delete(conds), table: :users
end
```

What will they do ? Those macros will create common CRUD functions. So you don’t have to write each query with SQL. Simple one are created for you like this. How can I invoke them ? Here is example:

```elixir
UserQuery.get(id: "3") # => {:ok, [%{...}]}
UserQuery.add(name: "Smbdy") # => {:ok, [%{...}]}
UserQuery.update([name: "Other"],[id: "2"]) # => {:ok, [%{...}]}
UserQuery.delete(id: "2") # => {:ok, [%{...}]}
```

## Configuration

Configuration is also an easy task. Right now you can use it in two ways.

With existing Ecto connection:

```elixir
config :defql, connection: [
  adapter: Defql.Adapter.Ecto.Postgres,
  repo: Taped.Repo
]
```

As a standalone connection:

```elixir
config :defql, connection: [
  hostname: "localhost",
  username: "username",
  password: "password",
  database: "my_db",
  pool: DBConnection.Poolboy,
  pool_size: 1
]
```

## What is missing ?

Of course, it’s a very early stage, but `postgres` support works well. There are few things that are missing:

- MySQL support
- Support `IN` with array `%{id: [1,2,3]}`
- Cleanup ECTO adapter
- Support database errors

## Summary

Using [Defql](https://github.com/fazibear/defql) we have a very clear, simple and powerful way to interact with a database.

## Links

- Github Repository: https://github.com/fazibear/defql
- Hex Package: https://hex.pm/packages/defql
- Documentation: https://hexdocs.pm/defql
