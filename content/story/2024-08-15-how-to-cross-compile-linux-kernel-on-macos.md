---
date: 2024-08-15
title: How to cross compile linux kernel on MacOS
tags:
  - rpi
  - linux
  - kernel
  - docker

image: /images/stories/crosscompile.png
---

You have a mac? You need to compile linux kernel for your Raspberry PI?

Great. Follow me…

<!--more-->

### Part 1. Case sensitive file system

Note: This step is required if you want to have kernel files outside docker.
There is a case sensitive fs inside docker container.
You can just copy needed file at the end.

Bad news. MacOS uses case insensitive file system by default. What we can do about it?
No we will not make whole root partition case sensitive. We might have trouble.
We try USB drive or SD card, but I don't want to get up from a chair.

We need to create an image file with case sensitive file system first:

```bash
$ hdiutil create -size 5g -fs "Case-sensitive APFS" -volname LinuxBuilder LinuxBuilder.dmg
```

Then we need to mount it:
```bash
$ hdiutil attach LinuxBuilder.dmg -mountpoint linux_builder -nobrowse -readwrite
```

Enter the new file system

```bash
$ cd linux_builder
```

OK problem solved.

### Part 2. Checkout kernel

Within aur new shiny file system checkout a kernel source:

```bash
$  git clone --depth 1 https://github.com/raspberrypi/linux
```

### Part 3. Cross compilation tools

I bet there are, but don't want to think about this where they are, how to install them. We have docker. Right?
I have you can install it too. It's easy. Just do it.

Create a "Dockerfile" file:

```dockerfile
FROM debian:buster

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get clean && apt-get update && \
    apt-get install -y \
    bc \
    bison \
    flex \
    libssl-dev \
    make \
    kmod \
    libc6-dev \
    libncurses5-dev \
    crossbuild-essential-armhf \
    crossbuild-essential-arm64

WORKDIR /linux
VOLUME ["/linux"]
```

Build an image:

```bash
$ docker build -t linux_builder .
```

### Part 4. Make script

We will need one command: `make`. But let's create a simple wrapper that runs `make` in the container.
I am so creative, will call this file `make`.

```bash
# Run builder environment
docker run --rm \
    --device /dev/fuse \
    --cap-add SYS_ADMIN \
    --name linux_builder \
    -v "$(pwd)/linux":"/linux" \
    -e ARCH=arm \
    -e KERNEL=kernel7 \
    -e CROSS_COMPILE=arm-linux-gnueabihf- \
    -it linux_builder \
    make $@
```

This example is for RPI3. For other platform just adjust `ARCH`, `KERNEL`, and `CROSS_COMPILE` envs.

Make it executable:

```
$ chmod +x make
```

We're done.

### Part 5. Build the kernel

Now instead use `make menuconfig` we will use `./make menuconfig`.
You know what to do next. Right?

If not, here is a hint:

```bash
$ ./make bcm2709_defconfig
$ ./make -j12 zImage modules dtbs
```

Wait. And look what is there:

```bash
$ ls linux/arch/arm/boot/
```

This is all we want.
Cheers!
