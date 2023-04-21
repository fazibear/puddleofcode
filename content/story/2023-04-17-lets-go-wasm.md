---
date: 2023-04-17
title: Let's GO WASM
tags:
  - go
  - wasm
image: /assets/images/stories/go-wasm.png
---

WASM? WebAssembly?

Lately I've started to ask myself: "Is WASM worth paying attention to?"

Let's find out. There are several languages that can be compiled into WASM. Anyway let's try GO.

We will make a simple web application that converts image from your webcam into ascii art.
The goal is to write as much code in Go as possible.

Let's go!

```bash
# go mod init asciifyme
```

And just it, everything works! 

Just kidding. It's not that simple.

We will need following pieces:
 - `webcam` - will initialize and fetch data from web cam
 - `canvas` - we need this to fetch pixel data from image
 - `asciifyier` - turn image data into ascii

The webcam:

This module will:
 - create a `video` element with `document.createElement`
 - initialize webcam with `navigator.getUserMedia`

We need to create a file `webcam/webcam.go`

First part looks like this:

```go
package webcam

import (
	"fmt"
	"syscall/js"
)

var (
	navigator js.Value
	video     js.Value
)

func init() {
	navigator = js.Global().Get("navigator")
	video = js.Global().Get("document").Call("createElement", "video")
}
```

With this code we are creating `video` element, and fetching `navigator` for future use.

It's time to setup webcam:

```go
func Setup() js.Value {
	user_media_params := map[string]interface{}{
		"video": true,
	}

	navigator.Call("getUserMedia", user_media_params, js.FuncOf(stream), js.FuncOf(err))

	return video
}
```

We will call this function from the main, it will setup webcam and return `video` object to fetch data from.
But wait! There are two callbacks `stream` and `err` we need to implement:

```go
func err(this js.Value, args []js.Value) interface{} {
	fmt.Println("err")
	return nil
}

func stream(this js.Value, args []js.Value) interface{} {
	video.Set("srcObject", args[0])
	video.Call("addEventListener", "canplaythrough", js.FuncOf(canPlay))
	return nil
}
```

For now we will ignore errors, just write error on console.
`stream` function adds a stream to the video element and listen to `canplaythrough` event.
Another callback? Yes! `video` will call `canPlay` callback when there will be enough data.

```go
func canPlay(this js.Value, args []js.Value) interface{} {
	video.Call("play")
	return nil
}
```

When we have enough data press play!

We have a `video`, now we need a pixel data. Let's create `canvas` in `canvas/canvas.go`

```go
package canvas

import (
	"syscall/js"
)

const (
	CanvasWidth  = 80
	CanvasHeight = 40
)

var (
	ctx js.Value
)

func init() {
	ctx = js.Global().Get("document").Call("createElement", "canvas").Call("getContext", "2d")
}
```

We're creating `canvas` element and fetching `context`. Will use it to draw and fetch pixel data.

```go
func DrawImage(video js.Value) {
	ctx.Call("drawImage", video, 0, 0, CanvasWidth, CanvasHeight)
}
```

We can draw a frame from `video` just by passing it into `drawImage` function.

```go
func GetImageData() []uint8 {
	data := ctx.Call("getImageData", 0, 0, CanvasWidth, CanvasHeight).Get("data")

	lenght := data.Get("length").Int()

	goData := make([]uint8, lenght)

	js.CopyBytesToGo(goData, data)

	return goData
}
```

Fetching pixel data is more complicated. We have to fetch JS array of `uint8` into GO.
This function takes the length of data from `canvas`, create GO array, and copy whole data into go array.
Voila! We have a pixel data.

What's left? Convert it to asciiart.

`asciifyier/asciifyier.go` is what we need!

```go
package asciifyier

import (
	"asciifyme/canvas"
)

const (
	Chars       = "   .,:;i1tfLCG08@"
	CharsLength = 16
)
```

We don't need any JS stuff here. Bui need to import our `canvas` to fetch its size.

```go
func Asciify(data []uint8) string {
	output := ""

	for y := 0; y < canvas.CanvasHeight; y++ {
		for x := 0; x < canvas.CanvasWidth; x++ {
			offset := (y*canvas.CanvasWidth + x) * 4

			red := data[offset]
			green := data[offset+1]
			blue := data[offset+2]
			//alpha := data[offset+3]

			brightness := (0.3*float64(red) + 0.59*float64(green) + 0.11*float64(blue)) / 255.0

			char_index := CharsLength - int(brightness*CharsLength)

			output += string(Chars[char_index])
		}
		output += "\n"
	}

	return output
}
```

What we're doing here? We're Taking each pixel data from array of `uint8` and creating a string. Our asciiart.

It's time for `main.go` ...

```go
package main

import (
	"asciifyme/asciifyier"
	"asciifyme/canvas"
	"asciifyme/webcam"
	"syscall/js"
)

var (
	camera js.Value
	window js.Value
	pre    js.Value
)

func init() {
	camera = webcam.Setup()
	window = js.Global().Get("window")
	pre = js.Global().Get("document").Call("getElementById", "pre")
}
```

Taking all the pieces together. We will need a `camera`, `window.requestAnimationFrame`, and `pre` element to display our asciiart.

```go
func loop(this js.Value, args []js.Value) interface{} {
	window.Call("requestAnimationFrame", js.FuncOf(loop))
	canvas.DrawImage(camera)
	imageData := canvas.GetImageData()
	output := asciifyier.Asciify(imageData)
	pre.Set("innerHTML", output)
	return nil
}

func main() {
	loop(js.ValueOf(nil), make([]js.Value, 0))

	select {}
}
```

In main loop we're:
 - fetching data from `video`
 - drawing it on `canvas`
 - fetch pixel data from `canvas`
 - create asciiart using `asciifyier`
 - draw asciify into `pre`

One more thing! `select {}` make the wasm program don't quit!

That's it. Compile time!

To run this in the browser we need:
 - index.html
 - wasm_exec.js
 - compiled app

Simple `index.html` file

```html
<html>
  <head>
    <title>asscify-me</title>
    <style>
      body{background-color:#000}pre{text-align:center}header{color:#daa520;font-size:18px;font-weight:700;text-shadow:0 0 3px gold}section{margin-top:30px;color:#32cd32;text-shadow:0 0 15px #0f0;font-size:14px}footer,footer a{margin-top:30px;color:red;text-shadow:0 0 15px tomato;font-size:14px}
    </style>
    <script src="wasm_exec.js"></script>
    <script>
    const go = new Go();
    WebAssembly.instantiateStreaming(fetch("asciifyme.wasm"), go.importObject).then((result) => {
    go.run(result.instance);
    });
    </script>
  </head>
  <body>
    <pre id="pre"></pre>
  </body>
</html>
```

And the build script:

```bash
#/bin/bash

export GOOS=js
export GOARCH=wasm
mkdir -p build
cp index.html build/
cp "$(go env GOROOT)/misc/wasm/wasm_exec.js" build/
go build -o build/asciifyme.wasm
```

Now we need to just:

```bash
# ./build.sh
```

Serve files from `build` folder, and use the browser.

Notice that the browser will give camera access only on `localhost`, or when you're using `https://`

P.S

But wait! The size! ~2MB is way to much! Yes!

Try `thinygo` compiler, ~200KB is much better!

```bash
# tinygo build -o build/asciifyme.wasm -target wasm
```

Don't need to write whole thing yourself if you don't want. Check out my [github](https://github.com/fazibear/asciifyme.go) or just an [app](https://fazibear.me/asciifyme.go/).
