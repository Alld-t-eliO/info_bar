# System Monitor

A lightweight real-time system monitor overlay for macOS, written in **C and Objective-C**.

This project is mainly a personal learning project. The goal is to learn C, macOS system APIs, hardware monitoring, graphical interfaces, and software architecture while building a small and useful desktop tool.

## Features

* CPU usage (%), computed from live Mach host statistics
* RAM usage (%), computed from live VM statistics
* GPU VRAM usage (%), via Metal (`currentAllocatedSize` / `recommendedMaxWorkingSetSize`)
* Real-time stats, refreshed every second
* Floating overlay window with transparent background
* Movable window — just click and drag the bar anywhere on screen
* Custom text color, chosen via the native macOS color picker
* Optional semi-transparent background pill for readability
* Persistent configuration — window position and color are restored on relaunch

### Planned

* True GPU compute utilization (currently only VRAM usage is available; real utilization would require parsing the private `IOReport` API)
* Dynamic window resizing based on content
* Dedicated preferences window (currently right-click menu)
* Launch at login

## Platform

**macOS only.** The project intentionally relies on macOS-specific frameworks (Metal, IOKit, Mach) and Apple hardware. Cross-platform support is not a current goal.

## Project structure

```
main.m           App entry point (Cocoa)
AppDelegate.h/m  Window setup, refresh timer, context menu (color, background, quit)
OverlayView.h/m  Custom transparent view that draws the stats text
cpu.c/h          CPU usage via Mach host_statistics
ram.c/h          RAM usage via Mach host_statistics64 + sysctl
gpu.h/m          GPU info via Metal (MTLDevice)
iokit_gpu.c/h    IOKit exploration of GPU services (dev/debug tool)
test_ioreport.c  Experiment with the IOReport API (dev/debug tool)
```

## Building

Requirements:
* macOS
* Xcode Command Line Tools (`xcode-select --install`)

Build the overlay app from source:

```bash
clang -fobjc-arc -o MonitorBar \
    main.m AppDelegate.m OverlayView.m \
    cpu.c ram.c gpu.m \
    -framework Cocoa -framework Metal -framework Foundation
```

Then run it:

```bash
./MonitorBar
```

## Usage

* **Move the bar**: click and drag anywhere on it.
* **Right-click** the bar for options:
  * *Choose a color...* — pick any text color
  * *Semi-transparent background* — toggle a dark pill behind the text
  * *Quit*

Position and color are saved automatically and restored the next time you launch the app.

## Status

Under active development. File layout, build process, and features may change without notice.