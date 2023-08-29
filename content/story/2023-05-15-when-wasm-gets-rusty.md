---
date: 2023-05-15
title: When WASM gets Rusty?
tags:
  - rust
  - wasm
  - async
image: /images/stories/rusty-wasm.png
---

We will take a look at WASM again! But this time with Rust. Why Rust? Because I can compile Rust directly into WASM.

Our goal is the same app we've created in Go, but ... yes! with Rust!

What is the plan?

Let's try to create same app that we did last time in Go. The asciifyier. It ill convert data from video camera into asciiart.

```bash
# cargo new --lib asciifier
```

One more thing:
```bash
# rustup target install wasm32-unknown-unknown  
```
Target is needed, so we can compile directly to WASM.

Before we go into the code we need to add dependencies into `Cargo.toml` file.

```toml
[dependencies]
wasm-bindgen = "0.2.63"
wasm-bindgen-futures = "0.4.15"
js-sys = "0.3.35"
console_error_panic_hook = "0.1.7"
log = "0.4"

console_log = { version = "1", features = [
  'color'
]}

web-sys = { version = "0.3.4", features = [
  'Document',
  'Element',
  'GetUserMediaRequest',
  'HtmlCanvasElement',
  'HtmlMediaElement',
  'HtmlVideoElement',
  'HtmlElement',
  'MediaStreamConstraints',
  'MediaDevices',
  'Navigator',
  'Node',
  'Window',
  'MediaStream',
  'CanvasRenderingContext2d',
  'ImageData',
  'console',
  'ContextAttributes2d',
]}
```

It's clear there are libs that our project will use but what about `features`? When we specify `features`, compiler will compile in these so we can use them.
Anyway our project uses only libs that allows us to use what browser offer.

Divide our project to 3 parts:
 - `webcam` - fetch image from web cam
 - `canvas` - fetch pixel data from image
 - `asciifyier` - turn image data into string

The `canvas.rs`:

We need:
 - create `canvas` element
 - get `2d` context
 - function to draw `video` frame on canvas
 - function to fetch pixel data from canvas


```rust
use wasm_bindgen::{prelude::*, Clamped};
use web_sys::{window, CanvasRenderingContext2d, HtmlCanvasElement, HtmlVideoElement};

use crate::{CANVAS_HEIGHT, CANVAS_WIDTH};

#[derive(Debug)]
pub struct Canvas {
    pub context: CanvasRenderingContext2d,
}

impl Canvas {
    pub fn new() -> Self {
        let document = window().unwrap().document().unwrap();

        let mut context_attributes = web_sys::ContextAttributes2d::new();
        context_attributes.will_read_frequently(true);

        // create document element
        let canvas = document
            .create_element("canvas")
            .unwrap()
            .dyn_into::<HtmlCanvasElement>()
            .unwrap();

        // set dimensions
        canvas.set_width(CANVAS_WIDTH.into());
        canvas.set_height(CANVAS_HEIGHT.into());

        // get 2d context
        let context = canvas
            .get_context_with_context_options("2d", &context_attributes)
            .unwrap()
            .unwrap()
            .dyn_into::<CanvasRenderingContext2d>()
            .unwrap();

        // store the context
        Self { context }
    }
  
    // draw a video frame on canvas
    pub fn draw_image(self: &Self, video: &HtmlVideoElement) {
        self.context
            .draw_image_with_html_video_element_and_dw_and_dh(
                video,
                0.0,
                0.0,
                CANVAS_WIDTH as f64,
                CANVAS_HEIGHT as f64,
            )
            .unwrap();
    }

    // fetch pixel data
    pub fn get_image_data(self: &Self) -> Clamped<Vec<u8>> {
        self.context
            .get_image_data(0.0, 0.0, CANVAS_WIDTH as f64, CANVAS_HEIGHT as f64)
            .unwrap()
            .data()
    }
}
```

Important thing is that you need to use `dyn_into` to make created element have a specific type. Other than that whole implementation is easy to read.

The `asciifier` takes a pixel data and converts it into `String`. 

```rust
use wasm_bindgen::Clamped;

const CHARS_LENGTH: usize = 16;
const fn get_char(index: usize) -> char {
    "   .,:;i1tfLCG08@".as_bytes()[index] as char
}

pub fn process(data: &Clamped<Vec<u8>>) -> String {
    let mut output = String::new();

    for y in 0..40 {
        for x in 0..80 {
            let offset = (y * 80 + x) * 4;

            let red = data[offset];
            let green = data[offset + 1];
            let blue = data[offset + 2];
            //let alpha = data[offset+3]

            let brightness = (0.3 * red as f32 + 0.59 * green as f32 + 0.11 * blue as f32) / 255.0;

            let char_index = CHARS_LENGTH - (brightness * CHARS_LENGTH as f32) as usize;

            output.push(get_char(char_index));
        }
        output.push('\n');
    }
    output
}
```

Last thing? The `webcam`:

This module will create `video` element and set it up. Get the video stream from `getUserMedia` and pass it back into `video`. 

```rust
use wasm_bindgen::prelude::*;
use web_sys::{window, HtmlVideoElement, MediaStreamConstraints};

#[derive(Debug)]
pub struct WebCam {
    pub video: HtmlVideoElement,
}

impl WebCam {
    pub fn new() -> Self {
        let document = window().unwrap().document().unwrap();

        let video = document
            .create_element("video")
            .unwrap()
            .dyn_into::<HtmlVideoElement>()
            .unwrap();

        video.set_autoplay(true);

        Self { video }
    }

    pub async fn setup(&self) -> Result<(), JsValue> {
        let mut constraints = MediaStreamConstraints::new();
        constraints.video(&JsValue::from(true));

        let promise = window()
            .unwrap()
            .navigator()
            .media_devices()
            .unwrap()
            .get_user_media_with_constraints(&constraints)
            .unwrap();

        let stream = wasm_bindgen_futures::JsFuture::from(promise).await?;

        self.video.set_src_object(Some(&stream.into()));

        Ok(())
    }
}
```

And this is where things get complicated. `getUserMedia` returns a promise. We need to wait for it! But `await` works only within async functions. Let's mars setup function as `async` then.

Making it work together.

We need to create a loop using `request_animation_frame` that:
 - draw video frame on canvas
 - takes pixel data from `canvas`
 - pass it thru `asciifier`
 - print string within `pre` element

Here what it's looks like:

```rust
extern crate console_error_panic_hook;

mod asciifyier;
mod canvas;
mod utils;
mod web_cam;

use std::cell::RefCell;
use std::rc::Rc;
use wasm_bindgen::prelude::*;
use web_sys::{window, HtmlElement};

const CANVAS_WIDTH: u16 = 80;
const CANVAS_HEIGHT: u16 = 40;

fn request_animation_frame(f: &Closure<dyn FnMut()>) {
    window()
        .unwrap()
        .request_animation_frame(f.as_ref().unchecked_ref())
        .expect("should register `requestAnimationFrame` OK");
}

#[wasm_bindgen(start)]
async fn run() -> Result<(), JsValue> {
    utils::set_panic_hook();
    console_log::init().expect("error initializing log");

    let context = canvas::Canvas::new();
    let web_cam = web_cam::WebCam::new();
    let pre = window()
        .unwrap()
        .document()
        .unwrap()
        .get_element_by_id("pre")
        .unwrap()
        .dyn_into::<HtmlElement>()
        .unwrap();

    if let Ok(()) = web_cam.setup().await {
        let f = Rc::new(RefCell::new(None));
        let g = f.clone();

        *g.borrow_mut() = Some(Closure::new(move || {
            request_animation_frame(f.borrow().as_ref().unwrap());

            context.draw_image(&web_cam.video);
            let data = context.get_image_data();
            let output = asciifyier::process(&data);

            pre.set_inner_text(&output);
        }));

        request_animation_frame(g.borrow().as_ref().unwrap());
    } else {
        pre.set_inner_text("Camera not found!");
    };

    Ok(())
}
```

We did it! But wait! `async fn run()`?. Yes! Because the target is WASM. We can have async main function. Browser will take care of it!

Compile time!

`index.html` of course...

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <title>asscify-me</title>
    <script src='asciifyme.js'></script>
    <script>
        wasm_bindgen('asciifyme_bg.wasm');
    </script>
  </head>
  <body>
    <pre id="pre"></pre>
  </body>
</html>
```

The build script:

`build.sh`:

```bash
#/bin/bash

mkdir -p build
cp index.html build/
wasm-pack build -t no-modules -d build/
```

And we're done. `wasm-pack` will do the dirty work for us!

```bash
$ ./build.sh
```

Serve files from `build` folder, and use the browser.

Notice that the browser will give camera access when you're using `https://` or `localhost`!

What is better? Rust or GO?

Creating the same application with Rust was much harder, but there are some positives because of that!
You'll ask what? Harder is better? Yes! Rust compiler forced me to think deeper about what I am doing. Like a good, but strict friend ;)
Other than that the Rust runtime is a way faster.

For WASM I will choose Rust!

Don't need to write whole thing yourself if you don't want. Check out my [github](https://github.com/fazibear/asciifyme.rust) or working an [app](https://fazibear.me/asciifyme.rust/).
