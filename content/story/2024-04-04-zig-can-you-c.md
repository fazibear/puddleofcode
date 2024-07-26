---
date: 2024-04-04
title: Zig! Can you C?
tags:
    - c
    - zig
    - raylib
image: /images/stories/raylib.png
#draft: true
---

I just want to develop something different. But what? Game, graphics, sound processing?
Surely you'll say Rust! Yep done a lot of things in Rust. But maybe C?

Ohhh... Noooo...
Remember `Segmentation Fault`?
How are you going to manage depenencies?

OK, So try to use some C library in ZIG! How hard it will be? Let's see.

Try to write somple app using `raylib`.

```bash
$ mkdir ray_test_zig
$ cd ray_test_zig
$ zig init-exe
```

Got a project. Try to run?

```bash
$ zig build run
```

Yep it's working.
We need to fetch and include `raylib` somehow.

Zig uses `zon` to fetch dependencies. Does it work with C libraries? Find out!

We need to provide where the lib is! Here it is:

Create `build.zig.zon` file.

```zig
.{
    .name = "ray_test_zig",
    .version = "0.0.1",
    .paths = .{""},

    .dependencies = .{
        .raylib = .{
            .url = "https://github.com/raysan5/raylib/archive/efce4d69ce913bca42289184b0bffe4339c0193f.tar.gz",
        },
    },
}
```
Try to build project?

```bash
$ zig build
```

What it is?

```
...build.zig.zon:7:20: error: dependency is missing hash field
            .url = "https://github.com/raysan5/raylib/archive/efce4d69ce913bca42289184b0bffe4339c0193f.tar.gz",
                   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
note: expected .hash = "1220055a322aac82f0c8104810bac892eaf62ab11582ca0f7bd1d04081048c67a081",

```

Ok, zon expects a hash, just in case someone will try to hack out computer. Once again:

```zig
.{
    .name = "ray_test_zig",
    .version = "0.0.1",

    .dependencies = .{
        .raylib = .{
            .url = "https://github.com/raysan5/raylib/archive/efce4d69ce913bca42289184b0bffe4339c0193f.tar.gz",
            .hash = "1220055a322aac82f0c8104810bac892eaf62ab11582ca0f7bd1d04081048c67a081",
        },
    },
}
```
Try once again:

```bash
$ zig build
```
It works! Woooow! That's it?

No! We need to tell zig to include `raylib` during build!

Now we will edit `build.zig`. Just above line ~30 we have `b.installArtifact(exe);`
Before that line we need to add:

```zig
const raylib = b.dependency("raylib", .{
    .target = target,
    .optimize = optimize,
});

exe.installLibraryHeaders(raylib.artifact("raylib"));
exe.linkLibrary(raylib.artifact("raylib"));

```

We're teling zig where header files are and to link out executable with `raylib`.
Does it works? Let's check!

```bash
$ zig build
```

OMG! Looks like somethings with raylib was happened. It's compiled?
Let's port an simple example from `raylib` to zig.

In the `src/main.zig`:

```zig
const std = @import("std");

const ray = @cImport({
    @cInclude("raylib.h");
});

pub fn main() !void {
    ray.InitWindow(800, 450, "Hey ZIG");
    defer ray.CloseWindow();

    while (!ray.WindowShouldClose()) {
        ray.BeginDrawing();
        ray.ClearBackground(ray.RAYWHITE);
        ray.DrawText("Congrats! You created your first window!", 190, 200, 20, ray.LIGHTGRAY);
        ray.EndDrawing();
    }
}
```

```bash
$ zig build
```

No errors? Great!

```bash
$ zig build run
```

We got the raylib window!
As you can see! Just one line of code and `raylib` working like native lib!

So yep! Zig can C!

PS. raylib a good example. There is build.zig included and makes things easier ;]
