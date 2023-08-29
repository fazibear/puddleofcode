---
date: 2017-12-27
title: Brewing the Firmware for Raspberry PI with Elixir and Nerves
tags:
  - elixir
  - nerves
  - led
  - gpio

image: /images/stories/brewing.png
---

As the PIX PROJECT started to be a real thing. I decided to make it more dynamic. The first version written in Ruby is very static. There is no easy way to animate dots within the clock for example. Also, you have to install the whole Linux, install packages and start the application. It’s not how the firmware works right? I decided to rewrite it into Elixir and wrap it with Nerves to create firmware. Let the story begin…

## Don’t know what are you talking about!

Just to make thing clear. PIX PROJECT is about to create something like pixel frame. Long story short. I’m trying to fix a broken toy. It is simply Raspberry PI Zero with 16x16 pixels LED Matrix.

## The Ingredients

At the beginning we will need some knowledge of Elixir and OTP. We will use GenServers, also we will need to use a Ports to drive LED Matrix.

Our system will have 3 main component types:

### Output

We will need few output implementations. First one will draw everything to console. Another one will drive real LED Matrix. But it’s not our target right now. If you’ll look at the code, there is also 3rd output. That one is using kernel module that I wrote for the Ruby version, just for tests.

### Display

This is the main part. This piece will collect all data, decide which one we want to display, show us fancy transitions. This component will use one of out output to show us data.

### Features

There will be a lot of this components. I called it features because it’s like features of out PIX THING. For example clock, temperature, notifications. Each feature will be programmed as a separate application that will generate its own output and talk to our display if everything changed.

## The Jar

We will need a big jar for all of those ingredients. Yes, you’re right. We will use umbrella application. The first application will take a data and display it on the terminal.

#Terminal Output
It’s really simple GenServer application. It waits for data. In our application data is an array of lines. The line is an array of numbers. The number is a color of the pixel in the line.

We need to convert it and display it to the console.

```elixir
defp draw(state) do
  state
  |> Enum.map(&process_line/1)
  |> ANSI.format()
  |> List.insert_at(0, [IO.ANSI.clear(), IO.ANSI.home()])
  |> IO.puts()
end
```

We need to process each line, clear the screen and display it.

```elixir
defp process_line(line) do
  line
  |> Enum.map(&process_pix/1)
  |> Kernel.++("\n")
end
defp process_pix(pix) do
  [color(pix), "■ "]
end
```

Each color will be converted to uft8 pixel with the corresponding color. You can check all code [here](https://github.com/fazibear/pix_elixir/blob/master/apps/terminal/lib/terminal.ex) on github.

### Random Pixel Generator

Now we will do a little shortcut. We will create a feature that generates the random pixel, and send data to output.

We need to generate a random application and create a GenServer within it. All data (pixel colors) will be stored in GenServer state. To make it live, GenServer should generate pixels by itself.

```elixir
def handle_info(:tick, state) do
  state = draw_random(state)
  Process.send_after(self(), :tick, @timeout)
  Terminal.data(__MODULE__, state)
  {:noreply, state}
end
```

We can archive that using handle_info. After each update, our terminal application will get new data to display. [Here](https://github.com/fazibear/pix_elixir/tree/master/apps/random) is the whole random application.

### Display

The display will be the most complicated part of our application. It will gather all data from all features generate current screen and send it to the output application. You should look at the code yourself [here](https://github.com/fazibear/pix_elixir/tree/master/apps/display/lib).

There are few things going up there that I’ll describe:

#### Cycle

Each feature will be displayed on the screen for 30 seconds and will switch to next registered one.

#### Subscriptions

When we run a feature application it needs to subscribe to display. The display app needs to know what features are running.

#### Transitions

We want to make a beautiful transition between them. Display application stores all current screen data for all subscribed features, so we can draw a transition

Now you have an idea how it works. What is an architecture, what each part is responsible for. You can check [pix_elixir](https://github.com/fazibear/pix_elixir) repo for more features examples like Clock, Binary Clock, Weather etc. We need to go further.

## LED Matrix

To drive LED Matrix will have to use Erlang Ports. We need a little C program that will talk to Elixir with stdin/out and display our data. Writing ports is far beyond the scope of this article, but to make it work, I have to copy few C function from Kernel and wrap it with the port.
I have a problem with process priorities and schedules. Within the kernel module, I can set the priority for LED loop. So I don’t see any glitches. With Erlang port, every io operation causes LED glitches. I’m still working on it.

## Nerves

The final part is wrapping the whole thing we just created a small image that can be burned on the sd card and will work with Raspberry PI.

To make it work, we need to add another application to our jar. This time we will name it firmware, and use nerves.new mix command.

All you need to do, is to add few application from our umbrella app, build the firmware with `mix firmware` and burn it with `mix firmware.burn` Stick sd card into your raspberry pi and that’s it!

Most important things to make it work with nerves are:

- Makefile for port must support few important ENV VARIABLES
- Remember to set Matrix (LED output) for production build
- Make sure bootloader is running your application after boot

You can connect a keyboard and monitor to your Raspberry PI, and play with IEX console on the device.
