# Laptop Remote & Battery Widget

This project contains two components that work together:

- A Flutter Android app that remotely controls your laptop and displays system information
- A Python backend that provides battery status, system metrics, and remote control actions
- A standalone battery widget that runs on the laptop when the phone isn’t connected

It’s a simple but powerful companion setup that lets you monitor and control your laptop from your Android device.

## Features

- Battery percentage and charging status
- CPU, RAM, and disk usage
- Temperature monitoring (if supported)
- Power controls (shutdown, restart, sleep, lock)
- Volume and brightness control
- Display off
- App launcher endpoints
- Clean Flutter UI with Riverpod state management

## Getting Started (Flutter App)

If you're new to Flutter, here are some helpful resources:

- Write your first Flutter app: https://docs.flutter.dev/get-started/codelab
- Flutter Cookbook: https://docs.flutter.dev/cookbook
- Flutter documentation: https://docs.flutter.dev/

## Python Backend

The backend runs on your laptop and exposes a REST API consumed by the Flutter app.

You’ll find:

- battery_widget.py — standalone battery widget
- server.py — Flask server providing system info and control endpoints
- requirements.txt — dependencies

Run it with:

pip install -r requirements.txt
python server.py

## Project Purpose

This project started as a simple battery widget and evolved into a full remote‑control system for a laptop, accessible from an Android device.