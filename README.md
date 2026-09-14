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
Info.plist       App bundle metadata (used by build.sh)
build.sh         Builds and packages MonitorBar.app
```

## Installation

### Option 1 — Download the app (recommended for most users)

1. Go to the [Releases](../../releases) page and download the latest `MonitorBar.app.zip`.
2. Unzip it and drag `MonitorBar.app` into `/Applications`.
3. **First launch**: macOS will block the app because it isn't signed by a
   registered Apple Developer account. Right-click (or Control-click)
   `MonitorBar.app` → **Open** → **Open** again in the dialog. You only need
   to do this once.
4. The bar appears floating on your screen. Right-click it any time to
   change its color, toggle the background, or quit.

### Option 2 — Build from source

Requirements:
* macOS
* Xcode Command Line Tools (`xcode-select --install`)

Clone the repo, then run the build script from the project root:

```bash
./build.sh
```

This compiles everything and assembles a real `.app` bundle at
`build/MonitorBar.app`. Launch it with:

```bash
open build/MonitorBar.app
```

Alternatively, to build a plain command-line binary without an app bundle:

```bash
clang -fobjc-arc -o MonitorBar \
    main.m AppDelegate.m OverlayView.m \
    cpu.c ram.c gpu.m \
    -framework Cocoa -framework Metal -framework Foundation

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