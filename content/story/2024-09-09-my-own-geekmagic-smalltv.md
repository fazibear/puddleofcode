---
date: 2024-09-09
title: My Own GeekMagic SmallTv
tags:
  - esp8266
  - st7789
  - tft

image: /images/stories/smalltv.png
---

Got one! And you know what? Firmware is not open source. I need to write my own right?

RIGHT?

No more talking let's start.

There are two versions. PRO version with a touch button on top with ESP32 inside, and other one without. The other one have ESP8266 inside.

It's from aliexpress, you never know what you will get ;)

Wanna look inside? Someone did a video.
Here you are:

{{< youtube id="70CDu9o2_Yo" width="50%" >}}

And this is mine:

![minitv](/images/content/minitv.jpg)

What to we need?
 - USB to TTL converter
 - few spare pins
 - solder iron
 - few cables
 - computer ;)

I think you guess it, but:

- GRN to ground pin
- RX to TTLs TX pin
- TX to TTLs RX pin
- VCC to 3.3V (5V works fine ;)
- FLASH - short to ground during power on to upload flash.

Now you need to setup PlatformIO new project. If you really want Arduino IDE will be fine.

Create `src/main.c` ...

And now what? Now we need some informations...

- What microcontroller we have
- What tft driver we need to use
- Where the screen is connected?

What pins goes to tft socket?

LCD use those pins:
 - 14
 - 13
 - 0
 - 2
 - 5

It's not enough, uncle google your friend... (ugh! forget to ask chat GPT, next time)

Anyway I found this: https://community.home-assistant.io/t/installing-esphome-on-geekmagic-smart-weather-clock-smalltv-pro/618029

There is lot of informations.
If you carefully read whole conversation you will know that you need to use ST7789 tft driver and pins are:
 - TFT_CLK 14
 - TFT_MOSI 13
 - TFT_DC 0
 - TFT_RST 2
 - TFT_BACKLIGHT 5
 - TFT_CS 15

Now we're talking.

Our brand new `main.c`:

```
#include <Arduino.h>
#include <Adafruit_GFX.h>
#include <Adafruit_ST7789.h>

#define TFT_CLK 14
#define TFT_MOSI 13
#define TFT_DC 0
#define TFT_RST 2
#define TFT_CS 15
#define TFT_BACKLIGHT 5

Adafruit_ST7789 tft = Adafruit_ST7789(TFT_CS, TFT_DC, TFT_RST);

void setup() {
  pinMode(TFT_BACKLIGHT, OUTPUT);
  digitalWrite(TFT_BACKLIGHT, LOW);
  tft.init(240, 240, SPI_MODE3);
}

void loop() {
  tft.fillScreen(ST77XX_BLACK);
  delay(100);
  tft.fillScreen(ST77XX_WHITE);
  delay(100);
  tft.fillScreen(ST77XX_YELLOW);
  delay(100);
  tft.fillScreen(ST77XX_GREEN);
  delay(100);
  tft.fillScreen(ST77XX_BLUE);
  delay(100);
  tft.fillScreen(ST77XX_RED);
  delay(100);
}
```

It work!!! Great. My own MiniTv firmware. NICE!
But what I can display on it?

Yes! PIX! My other project uses ESP with led matrix.

https://github.com/fazibear/pix/tree/master/pix_esp8266

I just need to write another front end to display things on tft display. Let's do IT.

FEW HOURS LATER

Voila! Yet another interesting project without AI :P

![minitv](/images/content/minitv_weather.jpg)
![minitv](/images/content/minitv_crab.jpg)

Whoops. It's 4AM. I need to sleep.

Here is the code: https://github.com/fazibear/pix/blob/master/pix_esp8266/src/tft/tft.cpp

Good Night!
