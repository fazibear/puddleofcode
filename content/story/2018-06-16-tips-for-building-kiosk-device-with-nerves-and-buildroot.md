---
date: 2018-06-16
slug: tips-for-building-kiosk-device-with-nerves-and-buildroot
title: 7 Tips for Building Kiosk Device with Nerves and Buildroot
tags:
  - buildroot
  - nerves
  - linux
  - drives
  - kernel

section: story
image: /assets/images/stories/nervesbuildroot.png
author: Michał Kalbarczyk
author_image: ../images/authors/michal.png
---

For about a year I’m working on some interesting machine. The first challenge was to build a kiosk device. During working on that I’ve made a lot of research and ended up with Nerves.

## What is Nerves?

> Craft and deploy bulletproof embedded software in Elixir

You can read more about this project here: https://nerves-project.org/

Nerves is a neat tool, to help you wrap software you’ve written into the single firmware. You can burn it into sd card, pen drive or an SD drive. Single file firmware file is a big advantage. You can burn a few versions of firmware on a bunch of pen drives, and switch them easily.

## What do we need to archive?

We need a kiosk device with two screens. The displays should show us a web content served by local server (no internet connection). The backend stuff is written in elixir of course. All things are running on X86_64 with Radeon. Important thing is that we will need the full power of GPU.

## What is this article about?

It’s not a step by step guide to building such a thing. I’ll share with you few tips learned during working with buildroot and nerves.

### Start!

As a good start, we have to burn something and see what will happen.

First I’ve tried was this one:

https://github.com/LeToteTeam/kiosk_system_x86_64

Good start but nothing works. Why? Because there are no radeon drivers. We will take care of that later.

So I’ve started to build a new `nerves_system` on the top of:

https://github.com/nerves-project/nerves_system_x86_64

### Buildroot cache

I’m spent a lot of time watching the nerves system compiles. To make things faster you can enable the cache. Buildroot has a build in solution. All you need to do is add a single line to `nerves_defconfig` file.

```text
BR2_CCACHE=y
```

Now your next build should finish a lot faster.

### Radeon drivers

As I mentioned GPU driver is a must. There are 2 places. First one is a linux kernel, the second one is a burildroot config.

I’ve added those line into linux-\*.config file:

```text
CONFIG_DRM_AMDGPU=y
CONFIG_DRM_AMDGPU_SI=y
CONFIG_DRM_AMDGPU_CIK=y
CONFIG_DRM_AMDGPU_USERPTR=y
BR2_PACKAGE_LINUX_FIRMWARE=y
BR2_PACKAGE_LINUX_FIRMWARE_AMDGPU=y
```

Yeah! No big deal. But this is not enough. We need few other things. To make it work we will need at least `buildroot` version `2018.05`. No worries, nerves supports it from a `1.2` version. It can be done with later version but why we should bother with dirty hacks if we can make it easy.

We need the kernel and mesa3d drivers!

```text
BR2_PACKAGE_LINUX_FIRMWARE=y
BR2_PACKAGE_LINUX_FIRMWARE_AMDGPU=y
BR2_PACKAGE_MESA3D=y
BR2_PACKAGE_MESA3D_LLVM=y
BR2_PACKAGE_MESA3D_GALLIUM_DRIVER_RADEONSI=y
BR2_PACKAGE_MESA3D_DRI_DRIVER_RADEON=y
BR2_PACKAGE_MESA3D_OPENGL_EGL=y
BR2_PACKAGE_MESA3D_OPENGL_TEXTURE_FLOAT=y
```

First two lines will install GPU driver to the target system, next we asking buildroot to install mesa3d drivers. The last line is important. I’ve spent a lot of time figuring out why there are a lot of glitches on the screen, the last line resolves the problem completely.

### Make things faster

I’ve figured out that our application runs a lot slower compared to one running on Ubuntu. It’s not about GPU. The CPU load was as twice bigger that on ubuntu? Why? As always, a lot of research and very easy solution.

```text
CONFIG_NO_HZ_FULL=y
CONFIG_NO_HZ_FULL_ALL=y
CONFIG_HIGH_RES_TIMERS=y
CONFIG_IRQ_TIME_ACCOUNTING=y
CONFIG_SCHED_SMT=y
CONFIG_PREEMPT=y
CONFIG_CPU_IDLE_GOV_MENU=y
```

I know looks weird. But those kernel switches will improve CPU time scheduling. How did I figure out this? When I was thought about why the load average is so high, I’ve taken a look how Ubuntu kernel is configured. There was CPU section. After few google queries, it was clear.

### Compile optimization

Buildroot optimizing target system for size. It’s not very performant. You can change that.

```text
BR2_OPTIMIZE_3=y
```

That’s it. You can try `BR2_OPTIMIZE_FAST` but it does not work for me.

### Show me something

We need a web browser! During one of the ElixirConf, The Nerves Guys convince us to use QT5. QT is great. Is very light, have a webengine component, and you can create an app with few lines of C++ code and QML. How can I install it? Here you are:

```text
BR2_PACKAGE_QT5=y
BR2_PACKAGE_QT5BASE_SQLITE_SYSTEM=y
BR2_PACKAGE_QT5BASE_LINUXFB=y
BR2_PACKAGE_QT5BASE_DEFAULT_QPA="eglfs"
BR2_PACKAGE_QT5BASE_GIF=y
BR2_PACKAGE_QT5BASE_PNG=y
BR2_PACKAGE_QT5MULTIMEDIA=y
BR2_PACKAGE_QT5WEBENGINE=y
```

Another advantage of that is that you don’t need to worry about Xorg or Wayland configuration. It’s not needed. QT has its own compositor and supports OpenGL as well.

### Configuring WebEngine

It’s very easy to configure WebEngine inside your application. All you have to use is `QTWEBENGINE_CHROMIUM_FLAGS` environment variable.

I’ve spent a lot of time figuring out how to enable antialiasing in WebGL context. Tried to add switches, but always at the end of parameters QT added few own switches that disable antialiasing. The `--disable-embedded-switches` switch done the job.
