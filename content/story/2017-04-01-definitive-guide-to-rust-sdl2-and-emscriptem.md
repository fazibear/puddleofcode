---
date: 2017-04-01
slug: definitive-guide-to-rust-sdl2-and-emscriptem
title: Definitive guide to Rust, SDL 2 and Emscripten!
tags:
  - rust
  - javascript
  - emscripten
  - asm.js

section: story
image: /assets/images/stories/rustemscripten.png
author: Michał Kalbarczyk
author_image: ../images/authors/michal.png
---

So, you want to write a game? And run it in the browser? Do you like Rust? Great! I’ll show you how to write a sample program in Rust using SDL2 and how to compile it with Emscripten.

## Installing Rust

Best way to install Rust starts here: https://www.rustup.rs/

```bash
$ curl https://sh.rustup.rs -sSf | sh
```

Then just type:

```bash
$ rustup default stable
```

Will also need an additional target to compile our program to javascript.

```bash
$ rustup target add asmjs-unknown-emscripten
```

Now we have Rust!

## Installing Emscripten

We will also need Emscripten. It’s a compilator that takes any LLVM compatible language and outputs a javascript.

There is a tool, which will manage Emscripten installation for us.

```bash
$ git clone https://github.com/juj/emsdk
$ cd emsdk
$ ./emsdk install latest
$ ./emsdk activate latest
```

To setup emscripten environment just run:

```bash
source ./emsdk_env.sh
```

## Setting up SDL2

You’ll have to install SDL2 on your system.

On MacOS:

```bash
$ brew install sdl2
```

On Ubuntu:

```bash
$ apt-get install libsdl2–2.0–0 libsdl2-dev
```

On other linux distributions try something similar.

## Creating new Rust project

Cargo will create a new project for you, for example:

```bash
$ cargo new — bin rust_to_js
$ cd rust_to_js
$ cargo run
```

We have it. Hello world up and running.

We need to add these dependencies to `Cargo.toml`:

```toml
[dependencies]
sdl2 = “0.29.0”
```

And modify `src/main.rs` like this:

```rust
extern crate sdl2;

use std::process;
use sdl2::rect::{Rect};
use sdl2::event::{Event};
use sdl2::keyboard::Keycode;

fn main() {
    let ctx = sdl2::init().unwrap();
    let video_ctx = ctx.video().unwrap();

    let window  = match video_ctx
        .window("rust_to_js", 640, 480)
        .position_centered()
        .opengl()
        .build() {
            Ok(window) => window,
            Err(err)   => panic!("failed to create window: {}", err)
        };

    let mut renderer = match window
        .renderer()
        .build() {
            Ok(renderer) => renderer,
            Err(err) => panic!("failed to create renderer: {}", err)
        };

    let mut rect = Rect::new(10, 10, 10, 10);

    let black = sdl2::pixels::Color::RGB(0, 0, 0);
    let white = sdl2::pixels::Color::RGB(255, 255, 255);

    let mut events = ctx.event_pump().unwrap();

    let mut main_loop = || {
        for event in events.poll_iter() {
            match event {
                Event::Quit {..} | Event::KeyDown {keycode: Some(Keycode::Escape), ..} => {
                    process::exit(1);
                },
                Event::KeyDown { keycode: Some(Keycode::Left), ..} => {
                    rect.x -= 10;
                },
                Event::KeyDown { keycode: Some(Keycode::Right), ..} => {
                    rect.x += 10;
                },
                Event::KeyDown { keycode: Some(Keycode::Up), ..} => {
                    rect.y -= 10;
                },
                Event::KeyDown { keycode: Some(Keycode::Down), ..} => {
                    rect.y += 10;
                },
                _ => {}
            }
        }

        let _ = renderer.set_draw_color(black);
        let _ = renderer.clear();
        let _ = renderer.set_draw_color(white);
        let _ = renderer.fill_rect(rect);
        let _ = renderer.present();
    };

    loop { main_loop(); }
}
```

A few explanations. In this example, we’ve created a sample application to move a white box using cursor keys. Simple enough.

Run it!

```bash
$ cargo run
```

Great! A window appeared, and the box is moving.
If you see note: `ld: library not found for -lSDL2` you have to check if SLD2 is installed correctly on your system.

Time to modify our code to run in also in javascript.
We will need a wrapper around emscripten API. There is no working solution in the Crate (package manager for Rust). But we can find few on the internet.

Save this file to `src/emscripten.rs`:

```rust
// taken from https://github.com/Gigoteur/PX8/blob/master/src/px8/emscripten.rs

#[cfg(target_os = "emscripten")]
pub mod emscripten {
    use std::cell::RefCell;
    use std::ptr::null_mut;
    use std::os::raw::{c_int, c_void, c_float};

    #[allow(non_camel_case_types)]
    type em_callback_func = unsafe extern fn();

    extern {
        pub fn emscripten_set_main_loop(func: em_callback_func, fps: c_int, simulate_infinite_loop: c_int);
        pub fn emscripten_cancel_main_loop();
        pub fn emscripten_get_now() -> c_float;
    }

    thread_local!(static MAIN_LOOP_CALLBACK: RefCell<*mut c_void> = RefCell::new(null_mut()));

    pub fn set_main_loop_callback<F>(callback: F) where F: FnMut() {
        MAIN_LOOP_CALLBACK.with(|log| {
            *log.borrow_mut() = &callback as *const _ as *mut c_void;
        });

        unsafe { emscripten_set_main_loop(wrapper::<F>, 0, 1); }

        unsafe extern "C" fn wrapper<F>() where F: FnMut() {
            MAIN_LOOP_CALLBACK.with(|z| {
                let closure = *z.borrow_mut() as *mut F;
                (*closure)();
            });
        }
    }
}
```

And modify our `src/main.rs` to look like this:

```rust
extern crate sdl2;

use std::process;
use sdl2::rect::{Rect};
use sdl2::event::{Event};
use sdl2::keyboard::Keycode;

#[cfg(target_os = "emscripten")]
pub mod emscripten;

fn main() {
    let ctx = sdl2::init().unwrap();
    let video_ctx = ctx.video().unwrap();

    let window  = match video_ctx
        .window("rust_to_js", 640, 480)
        .position_centered()
        .opengl()
        .build() {
            Ok(window) => window,
            Err(err)   => panic!("failed to create window: {}", err)
        };

    let mut renderer = match window
        .renderer()
        .build() {
            Ok(renderer) => renderer,
            Err(err) => panic!("failed to create renderer: {}", err)
        };

    let mut rect = Rect::new(10, 10, 10, 10);

    let black = sdl2::pixels::Color::RGB(0, 0, 0);
    let white = sdl2::pixels::Color::RGB(255, 255, 255);

    let mut events = ctx.event_pump().unwrap();

    let mut main_loop = || {
        for event in events.poll_iter() {
            match event {
                Event::Quit {..} | Event::KeyDown {keycode: Some(Keycode::Escape), ..} => {
                    process::exit(1);
                },
                Event::KeyDown { keycode: Some(Keycode::Left), ..} => {
                    rect.x -= 10;
                },
                Event::KeyDown { keycode: Some(Keycode::Right), ..} => {
                    rect.x += 10;
                },
                Event::KeyDown { keycode: Some(Keycode::Up), ..} => {
                    rect.y -= 10;
                },
                Event::KeyDown { keycode: Some(Keycode::Down), ..} => {
                    rect.y += 10;
                },
                _ => {}
            }
        }

        let _ = renderer.set_draw_color(black);
        let _ = renderer.clear();
        let _ = renderer.set_draw_color(white);
        let _ = renderer.fill_rect(rect);
        let _ = renderer.present();
    };

    #[cfg(target_os = "emscripten")]
    use emscripten::{emscripten};

    #[cfg(target_os = "emscripten")]
    emscripten::set_main_loop_callback(main_loop);

    #[cfg(not(target_os = "emscripten"))]
    loop { main_loop(); }
}
```

We need to alternate our code when we are compling to javascript. We will use `#[cfg(target_os = “emscripten")]` to define lines that will used for javascript build and `#[cfg(not(target_os = “emscripten"))]` for standard builds.

Just to be sure, let’s check if all the things are working for standard builds?

```bash
$ cargo run
```

Yes! Everything works fine.

## Compiling to Javasctipt

If we want to compile something to javascript that uses system libraries, we need to compile those libraries with emscripten. But emscripten provides us few precompiled libraries. You can check them
with:

```bash
$ emcc --show-ports
```

There is SDL, great! We don’t need to compile it ourselves. We need to use `USE_SDL=2` because we’re using version 2.0.

Before we will add any empscripten compiler flags to our environment we need to compile our dependencies itself

```bash
$ embuilder.py build sdl2
```

Now we can set `EMMAKEN_CFLAGS` environment variable to `-s USE_SDL=2`

```bash
$ export EMMAKEN_CFLAGS="-s USE_SDL=2"
```

Now we will try to compile

```bash
$ cargo build — target asmjs-unknown-emscripten
```

Got it! Take a look

```bash
$ ls target/asmjs-unknown-emscripten/debug/rust_to_js.js
```

One big javascript file. That’s it? How to run it?

You have to create another file `index.html`:

```html
<!DOCTYPE html>
<html lang="en-us">
  <head>
    <meta charset="utf-8" />
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <title>Emscripten-Generated Code</title>
    <style>
      body {
        font-family: arial;
        margin: 0;
        padding: none;
      }
      .emscripten {
        padding-right: 0;
        margin-left: auto;
        margin-right: auto;
        display: block;
      }
      div.emscripten {
        text-align: center;
      }
      div.emscripten_border {
        border: 1px solid black;
      }
      /* the canvas *must not* have any border or padding, or mouse coords will be wrong */
      canvas.emscripten {
        border: 0px none;
        background-color: black;
      }
      #emscripten_logo {
        display: inline-block;
        margin: 0;
      }
      .spinner {
        height: 30px;
        width: 30px;
        margin: 0;
        margin-top: 20px;
        margin-left: 20px;
        display: inline-block;
        vertical-align: top;
        -webkit-animation: rotation 0.8s linear infinite;
        -moz-animation: rotation 0.8s linear infinite;
        -o-animation: rotation 0.8s linear infinite;
        animation: rotation 0.8s linear infinite;
        border-left: 5px solid rgb(235, 235, 235);
        border-right: 5px solid rgb(235, 235, 235);
        border-bottom: 5px solid rgb(235, 235, 235);
        border-top: 5px solid rgb(120, 120, 120);
        border-radius: 100%;
        background-color: rgb(189, 215, 46);
      }
      @-webkit-keyframes rotation {
        from {
          -webkit-transform: rotate(0deg);
        }
        to {
          -webkit-transform: rotate(360deg);
        }
      }
      @-moz-keyframes rotation {
        from {
          -moz-transform: rotate(0deg);
        }
        to {
          -moz-transform: rotate(360deg);
        }
      }
      @-o-keyframes rotation {
        from {
          -o-transform: rotate(0deg);
        }
        to {
          -o-transform: rotate(360deg);
        }
      }
      @keyframes rotation {
        from {
          transform: rotate(0deg);
        }
        to {
          transform: rotate(360deg);
        }
      }
      #status {
        display: inline-block;
        vertical-align: top;
        margin-top: 30px;
        margin-left: 20px;
        font-weight: bold;
        color: rgb(120, 120, 120);
      }
      #progress {
        height: 20px;
        width: 30px;
      }
      #controls {
        display: inline-block;
        float: right;
        vertical-align: top;
        margin-top: 30px;
        margin-right: 20px;
      }
      #output {
        width: 100%;
        height: 200px;
        margin: 0 auto;
        margin-top: 10px;
        border-left: 0px;
        border-right: 0px;
        padding-left: 0px;
        padding-right: 0px;
        display: block;
        background-color: black;
        color: white;
        font-family: 'Lucida Console', Monaco, monospace;
        outline: none;
      }
    </style>
  </head>
  <body>
    <div class="spinner" id="spinner"></div>
    <div class="emscripten" id="status">Downloading...</div>

    <span id="controls">
      <span><input type="checkbox" id="resize" />Resize canvas</span>
      <span
        ><input type="checkbox" id="pointerLock" checked />Lock/hide mouse
        pointer &nbsp;&nbsp;&nbsp;</span
      >
      <span
        ><input
          type="button"
          value="Fullscreen"
          onclick="Module.requestFullscreen(document.getElementById('pointerLock').checked,
                                                                                document.getElementById('resize').checked)"
        />
      </span>
    </span>

    <div class="emscripten">
      <progress value="0" max="100" id="progress" hidden="1"></progress>
    </div>

    <div class="emscripten_border">
      <canvas
        class="emscripten"
        id="canvas"
        oncontextmenu="event.preventDefault()"
      ></canvas>
    </div>
    <textarea id="output" rows="8"></textarea>

    <script type="text/javascript">
      var statusElement = document.getElementById('status')
      var progressElement = document.getElementById('progress')
      var spinnerElement = document.getElementById('spinner')
      var Module = {
        preRun: [],
        postRun: [],
        print: (function() {
          var element = document.getElementById('output')
          if (element) element.value = '' // clear browser cache
          return function(text) {
            if (arguments.length > 1)
              text = Array.prototype.slice.call(arguments).join(' ')
            // These replacements are necessary if you render to raw HTML
            //text = text.replace(/&/g, "&amp;");
            //text = text.replace(/</g, "&lt;");
            //text = text.replace(/>/g, "&gt;");
            //text = text.replace('\n', '<br>', 'g');
            console.log(text)
            if (element) {
              element.value += text + '\n'
              element.scrollTop = element.scrollHeight // focus on bottom
            }
          }
        })(),
        printErr: function(text) {
          if (arguments.length > 1)
            text = Array.prototype.slice.call(arguments).join(' ')
          if (0) {
            // XXX disabled for safety typeof dump == 'function') {
            dump(text + '\n') // fast, straight to the real console
          } else {
            console.error(text)
          }
        },
        canvas: (function() {
          var canvas = document.getElementById('canvas')
          // As a default initial behavior, pop up an alert when webgl context is lost. To make your
          // application robust, you may want to override this behavior before shipping!
          // See http://www.khronos.org/registry/webgl/specs/latest/1.0/#5.15.2
          canvas.addEventListener(
            'webglcontextlost',
            function(e) {
              alert('WebGL context lost. You will need to reload the page.')
              e.preventDefault()
            },
            false
          )
          return canvas
        })(),
        setStatus: function(text) {
          if (!Module.setStatus.last)
            Module.setStatus.last = { time: Date.now(), text: '' }
          if (text === Module.setStatus.text) return
          var m = text.match(/([^(]+)\((\d+(\.\d+)?)\/(\d+)\)/)
          var now = Date.now()
          if (m && now - Date.now() < 30) return // if this is a progress update, skip it if too soon
          if (m) {
            text = m[1]
            progressElement.value = parseInt(m[2]) * 100
            progressElement.max = parseInt(m[4]) * 100
            progressElement.hidden = false
            spinnerElement.hidden = false
          } else {
            progressElement.value = null
            progressElement.max = null
            progressElement.hidden = true
            if (!text) spinnerElement.style.display = 'none'
          }
          statusElement.innerHTML = text
        },
        totalDependencies: 0,
        monitorRunDependencies: function(left) {
          this.totalDependencies = Math.max(this.totalDependencies, left)
          Module.setStatus(
            left
              ? 'Preparing... (' +
                  (this.totalDependencies - left) +
                  '/' +
                  this.totalDependencies +
                  ')'
              : 'All downloads complete.'
          )
        },
      }
      Module.setStatus('Downloading...')
      window.onerror = function(event) {
        // TODO: do not warn on ok events like simulating an infinite loop or exitStatus
        Module.setStatus('Exception thrown, see JavaScript console')
        spinnerElement.style.display = 'none'
        Module.setStatus = function(text) {
          if (text) Module.printErr('[post-exception status] ' + text)
        }
      }
    </script>
    <script
      type="text/javascript"
      src="target/asmjs-unknown-emscripten/debug/rust_to_js.js"
    ></script>
  </body>
</html>
```

This is a wrapper that will download generated javascript code and run it in the browser. Look at line `190` there is a link to this javascript file.
Let’s open index.html in the browser.

Works! You can use cursor buttons to move the little white box.

As you can see it’s fairly easy to generate working javascript from Rust code and run it in the browser. Now you should create some more interesting program or even game!

[Here](https://github.com/fazibear/rust_to_js) is a github repository with all code that we’ve just created. Hope you enjoy it!
