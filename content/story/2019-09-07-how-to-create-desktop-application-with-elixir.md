---
date: 2019-09-07
title: How to Create Desktop Application with Elixir
tags:
  - elixir
  - phoenix
  - live view
  - chromium
  - electron
image: /assets/images/stories/desktop-app.jpg
---

Writing desktop application is not an easy task. But why don't use Elixir, Phoenix and LiveView?
We will figure out how we can create a desktop application using those technologies.

## Phoenix Framework

We will use the Phoenix framework. All the details on how to install phoenix can be found here: https://hexdocs.pm/phoenix/installation.html

Let's get started!

```bash
mix phx.new elixir_desktop_application --no-ecto
cd elixir_desktop_application
```

## Phoenix LiveView

So far so good. To make things hot we will use [LiveView](https://github.com/phoenixframework/phoenix_live_view). Here is the [instalation guite](https://github.com/phoenixframework/phoenix_live_view#installation). After settings up Phoenix and LiveView, we will push things to git.

```bash
git init .
git add .
git commit -m "Initial commit"
```

Moving further We'll a build simple file browser. Out root LiveView will look like this:

```elixir
scope "/", ElixirDesktopApplicationWeb do
  pipe_through :browser

  live "/", FileBrowserLive
end
```

And write a simple file browser live view:

```elixir
defmodule ElixirDesktopApplicationWeb.FileBrowserLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~L"""
    <h3><%= @current %></h3>
    <ul>
      <li phx-click="cd" phx-value=".."><b>..</b></li>
      <%= for entry <- @dirs do %>
        <li phx-click="cd" phx-value="<%= entry %>"><b><%= entry %></b></li>
      <% end %>
      <%= for entry <- @files do %>
        <li><%= entry %></li>
      <% end %>
    </ul>
    """
  end

  def mount(_session, socket) do
    socket =
      socket
      |> assign(current: Path.expand("."))
      |> ls()

    {:ok, socket}
  end

  def handle_event("cd", param, socket) do
    socket =
      socket
      |> assign(current: path(socket, param))
      |> ls()

    {:noreply, socket}
  end

  defp ls(socket) do
    case File.ls(socket.assigns.current) do
      {:ok, entries} ->
        {dirs, files} = Enum.split_with(entries, &File.dir?(path(socket, &1)))

        assign(socket, dirs: Enum.sort(dirs), files: Enum.sort(files))

      _ ->
        socket
    end
  end

  defp path(socket, param) do
    Path.expand(socket.assigns.current <> "/" <> param)
  end
end
```

Take a look at http://localhost:4000/ such a nice file browser huh?

## WebEngineKiosk

To make our app desktop we need a window. What we can do about it? There is something we can use [webengine_kioks](https://github.com/fhunleth/webengine_kiosk). Let use it!

We need to add it as dependency:

```elixir
{:webengine_kiosk, "~> 0.2"}
```

And insert it to our supervision tree:

```elixir
defmodule ElixirDesktopApplication.Application do
  ...
  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Start the endpoint when the application starts
      ElixirDesktopApplicationWeb.Endpoint,
      # Starts a worker by calling: ElixirDesktopApplication.Worker.start_link(arg)
      # {ElixirDesktopApplication.Worker, arg},
      {WebengineKiosk, {[homepage: "http://localhost:4000", fullscreen: false], name: MyKiosk}}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ElixirDesktopApplication.Supervisor]
    Supervisor.start_link(children, opts)
  end
  ...
end

```

Easy peasy! Is it works? Let start our application:

```bash
mix phx.server
```

Wow! The window appeared with our browser. Nice! But we can go further! The erlang release.

## I Can't Quit!

But wait! I can't quit! Hit `ctrl-c` in your terminal and add the quit button:

In `lib/elixir_desktop_application_web/live/file_browser_live.ex` :

```elixir
  def render(assigns) do
    ~L"""
    <h4 phx-click="quit">quit</h4>
    """
    ...
  end

  def handle_event("quit", _param, _socket) do
    System.halt(0)
  end
```

We can close application now.

## OTP Release

OTP releases are included in elixir 1.9.
Out build script can look like this:

```bash
#!/bin/bash
export SECRET_KEY_BASE=ENhzfdb/3IwgO8LX0QHfYqPfpU6I8kyrPG348vFwRkzxG0CjN7+egBO/F0RJnjxE
export MIX_ENV=prod

mix deps.get --only prod
mix compile
npm run deploy --prefix ./assets
mix phx.digest
mix release --overwrite
```

And few more tweaks to our application. In`config/prod.exs`:

```elixir
config :elixir_desktop_application, ElixirDesktopApplicationWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true
```

Finally, create the build!

```bash
./build.sh
```

And run!

```bash
_build/prod/rel/elixir_desktop_application/bin/elixir_desktop_application start
```

Success!

## OSX Application

Yay! Everything still works. But this is not an app, right? Right. We will try to create an OSX app...

Updated build script looks like this:

```bash
#!/bin/bash
export SECRET_KEY_BASE=ENhzfdb/3IwgO8LX0QHfYqPfpU6I8kyrPG348vFwRkzxG0CjN7+egBO/F0RJnjxE
export MIX_ENV=prod

mix deps.get --only prod
mix compile
npm run deploy --prefix ./assets
mix phx.digest
mix release --overwrite

APP=FileBrowser
APP_DIR="${APP}.app/Contents/MacOS"
RELEASE=_build/prod/rel/elixir_desktop_application

rm -rf $APP.app
mkdir -p $APP_DIR
echo "cp -r $RELEASE $APP_DIR"
cp -r $RELEASE $APP_DIR
echo "#!/bin/bash" > $APP_DIR/$APP
echo 'DIR="\$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )' >> $APP_DIR/$APP
echo '$DIR/elixir_desktop_application/bin/elixir_desktop_application start' >> $APP_DIR/$APP
chmod +x $APP_DIR/$APP
```

Just run the script, click on FileBrowser.app ... and ... voila! But...

## Not So Fast!
Although it all works just fine it's not ready to distribute! There are a few things we need to look at!

#### HTTP
We're still communicating with HTTP. The browser talks to the server over HTTP. That's bad. You can't run a few instances at the same time. Is there a solution? Yes, it is! We can communicate over a port instead of HTTP. With the phoenix framework, it can be done. Also, some changes to WebEngineKiosk are required.

#### QT5 Libraries
This application will work fine on your computer, but not on another. QT5 libraries need to be installed. We can include those libraries in our bundle and relink the binary.

#### Other platforms

What about other platforms? Erlang releases works on Windows and Linux. It shouldn't be hard to make create releases for those platforms as well.

## It's possible!

This is just proof of concept. But it turns out that we are not far away from the framework like Electron for Elixir. Will you be interested in such a thing? Are you interested in writing the desktop application in Elixir with a little bit of Javascript? What do you think?

P.S. The source code is here: https://github.com/fazibear/elixir_desktop_application
