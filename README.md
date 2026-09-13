 # System Monitor

A lightweight real-time system monitor written in **C for macOS**.

This project is mainly a personal learning project. The goal is to learn C, macOS system APIs, hardware monitoring, graphical interfaces, and software architecture while building a small and useful desktop tool.

## Features

The project aims to provide a small floating system monitor displaying:

* CPU usage
* RAM usage
* GPU usage
* Real-time statistics
* Movable overlay window
* Dynamic window resizing
* Custom colors
* Custom appearance
* Optional transparency
* Persistent configuration

## Platform

Currently developed for:

**macOS**

The project is intentionally focused on macOS APIs and Apple hardware.

Cross-platform support may be considered in the future, but it is not a current goal.

## Building

The project is currently under development, so the build process may change.

For the early Metal experiments, the project can be compiled with Apple's Clang compiler:

```bash
clang main.c gpu.m -framework Metal -o monitor
```

Then:

```bash
./monitor
```