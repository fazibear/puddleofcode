---
date: 2017-09-10
slug: the-beginners-guide-to-linux-kernel-module-raspbery-pi-and-led-matrix
title: The Beginner’s Guide to Linux Kernel Module, Raspberry Pi and LED Matrix
tags:
  - linux
  - kernel
  - gpio
  - raspberrypi
  - led

section: story
image: /assets/images/stories/leds.png
author: Michał Kalbarczyk
author_image: ../images/authors/michal.png
---

When I found an old broken bluetooth speaker with RGB LED matrix, I decided to make use of it. It will be the great challenge to connect LEDs to Raspberry and display some fancy information.

## Reversing the matrix

I want to connect this matrix to Raspberry Pi somehow. But how this thing works? I learned how LED matrices work in general. And started to google some chip names and numbers for this particular thing. Nothing. But I was lucky, after about 10 pages, there was a link to PDF file. All information was in Chinese, but the chip matched. Google translator really helps me. After some measurements, I figured out what are each pin is for. There were 3 pins to choose the line, clock, latch, serial data in, and output enable. So I need 7 GPIO ports to drive this matrix. The protocol was described in PDF. It was the first success. Finally, the LED matrix started to work with my Raspberry Pi. But there were a simple few scripts.

## Linux Kernel Module

I have a few ideas how to implement screen driver. But finally, I decided to choose a kernel module with sysfs interface. There are few pros about it:

- Near realtime updating
- Loaded when system start
- Language independent usage

## Implementing Kernel Module

We will need 3 things:

- Use GPIO from kernel space
- Create a kernel module thread to drive led matrix
- Sysfs interface

So, let’s start. We will develop it directly on Raspberry Pi with Rapsbian. We will call out project `pix_mod`.

## Makefile

Most important thing is `Makefile`. It will build our module by simply typing `make`. Don’t worry it’s really simple:

```makefile
obj-m := pix_mod.o

all:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

clean:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean
```

## The module

We have to create a `pix_mod.c` file next to our make file.

```c
#include <linux/init.h>
#include <linux/module.h>

MODULE_LICENSE("GPL");

static int __init pix_init(void){
  printk(KERN_INFO "PIX: staring...");
  // stuff to do
  printk(KERN_INFO "PIX: staring done.");
  return 0;
}

static void __exit pix_exit(void){
  printk(KERN_INFO "PIX: stopping...");
  // stuff to do
  printk(KERN_INFO "PIX: stopping done.");
}

module_init(pix_init);
module_exit(pix_exit);
```

This is a simple kernel module template. We have two functions that will invoke when the module will load or unload. Now we can `make` it, and try to load it. To load a kernel module you have to type `sudo insmod pix_mod.ko`. If it works, let’s check `dmesg`, wow there is our message. Great. We can move forward.

# Use GPIO from kernel space

We don’t need to write GPIO driver. Rapsbian have one. we need to just use it. We will add two more functions to init and release our GPIOs.

```c
#include <linux/gpio.h>

#define A1  17 // 0
#define A2  18 // 1
#define A3  27 // 2
#define OE  22 // 3
#define LE  23 // 4
#define SDI 24 // 5
#define CLK 25 // 6

void pix_gpio_init(void){
  printk(KERN_INFO "PIX: starting gpio...");
  gpio_request(A1, "A1");
  gpio_request(A2, "A2");
  gpio_request(A3, "A3");

  gpio_request(OE, "OE");
  gpio_request(LE, "LE");
  gpio_request(SDI, "SDI");
  gpio_request(CLK, "CLK");

  gpio_direction_output(A1, 0);
  gpio_direction_output(A2, 0);
  gpio_direction_output(A3, 0);

  gpio_direction_output(OE, 1);
  gpio_direction_output(LE, 0);
  gpio_direction_output(SDI, 0);
  gpio_direction_output(CLK, 0);
  printk(KERN_INFO "PIX: starting gpio done.");
}

void pix_gpio_exit(void){
  printk(KERN_INFO "PIX: stopping gpio...");
  gpio_free(A1);
  gpio_free(A2);
  gpio_free(A3);

  gpio_free(OE);
  gpio_free(LE);
  gpio_free(SDI);
  gpio_free(CLK);
  printk(KERN_INFO "PIX: stopping gpio done.");
}
```

This lines will define to what GPIO port each matrix line is connected. `A1`, `A2`, `A3` are lines to choose what line is displaying. `CLK` is clock pin, `SDI` is serial data pin, `LE`, `OE`, will control serial communication. We will initialize each pin, and set the initial value to `0`. How can we change GPIO pin value? Let’s implement functions that set what line is currently displaying.

```c
void pix_line(u8 row){
  gpio_set_value(A1, !(row & 0b00000001));
  gpio_set_value(A2, !(row & 0b00000010));
  gpio_set_value(A3, !(row & 0b00000100));
}
```

OK. We can change the state of particular GPIO pins. What’s next?

## Kernel Thread

Displaying a picture on the LED matrix is a little bit more complex job. Because not all lines are displayed at the same time, you need to constantly display each line very quickly. This is what is our thread for. We will need a screen buffer that will store our picture and the loop that will read picture data from that buffer and display it on LEDs. This is a thread part of our kernel module:

```c
#include <linux/kthread.h>
#include <linux/delay.h>

#define THREAD_NAME "pix"

struct task_struct *task;

int pix_thread(void *data){
  u8 line, pos, bit;
  struct task_struct *TSK;
  struct sched_param PARAM = { .sched_priority = MAX_RT_PRIO };
  TSK = current;

  PARAM.sched_priority = THREAD_PRIORITY;
  sched_setscheduler(TSK, SCHED_FIFO, &PARAM);

  while(1) {
    // display line
    usleep_range(2000, 2000);
    if (kthread_should_stop()) break;
  }
  return 0;
}

void pix_thread_init(void){
  printk(KERN_INFO "PIX: starting thread...");
  task = kthread_run(pix_thread, NULL, THREAD_NAME);
  printk(KERN_INFO "PIX: starting thread done.");
}

void pix_thread_exit(void){
  printk(KERN_INFO "PIX: stopping thread...");
  kthread_stop(task);
  printk(KERN_INFO "PIX: stopping thread done.");
}
```

There is two function for initializing and release our thread. We will use them in main linux callbacks. And a thread function that will loop all the time displaying pictures on LED matrix. To make this article short I’ll skip displaying algorithm implementation. All source will be available at the end.

Now we can display pictures on our matrix. We miss one more thing, how other programs will set pixels?

# Sysfs interface

The last thing that we have to implement is an sysfs interface. It’s a simple file that you can write to. For example, to lit up the 5th pixel in the 10th row in white you have to `5 10 1 1 1` string to that file. There are 5 values. X, Y, R, G, B. The RGB values are booleans, but later I’ll try to implement some kind of PWM to archive more colors.

```c
static struct kobject *pix_kobject;

static ssize_t set_pix(struct kobject *kobj, struct kobj_attribute *attr, const char *buff, size_t count) {
  u8 x = 0;
  u8 y = 0;
  u8 r = 0;
  u8 g = 0;
  u8 b = 0;
  sscanf(buff, "%hhd %hhd %hhd %hhd %hhd", &x, &y, &r, &g, &b);
  pix_dot(x,y,r,g,b);
  return count;
}

static struct kobj_attribute pix_attribute =__ATTR(dot, (S_IWUSR | S_IRUGO), NULL, set_pix);

void pix_sysfs_init(void){
  printk(KERN_INFO "PIX: starting sysfs...");
  pix_kobject = kobject_create_and_add("pix", NULL);
  if (sysfs_create_file(pix_kobject, &pix_attribute.attr)) {
    pr_debug("failed to create pix sysfs!\n");
  }
  printk(KERN_INFO "PIX: starting sysfs done.");
}

void pix_sysfs_exit(void){
  printk(KERN_INFO "PIX: stopping sysfs...");
  kobject_put(pix_kobject);
  printk(KERN_INFO "PIX: stopping sysfs done.");
}
```

This piece of code will create a file `/sys/pix/dot`. As always we have 2 callbacks `init` and `exit`. For each write to `/sys/pix/dot` kernel will invoke the `set_pix` function. This function will parse input and invoke other function that will change a picture buffer. Remember the thread, the thread is drawing our picture all the time, so changes should appear immediately.

## The Final Module

Here is source of the module:

https://gist.github.com/fazibear/f1fe97c9799501e0e0955859e12ef4f8

If you want to test it, here a little ruby script that will draw color lines:

```ruby
while true
  r = rand(2)
  g = rand(2)
  b = rand(2)
  (0..15).each do |y|
    (0..15).each do |x|
      File.write('/sys/pix/dot', "#{x} #{y} #{r} #{g} #{b}")
    end
  end
end
```

It’s not perfect but works really well. On Raspberry Pi Zero, where there is only one core, I see some glitches. So there is some work to make it perfect. I’m really happy about it. I learn a lot about LED matrices, and linux kernel.
