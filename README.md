# Dom's Laptop Remote & Battery Widget

A cross‑platform project combining a Flutter Android app and a Python backend to remotely monitor and control a Windows laptop. It includes a standalone battery widget, a REST API server, and a clean mobile UI for quick access to system information and power controls.

## 🚀 Features

### 📱 Flutter Android App
- Live battery percentage and charging status
- CPU, RAM, and disk usage
- Temperature monitoring (if supported)
- Power controls:
  - Shutdown
  - Restart
  - Sleep
  - Lock
- Display off
- Volume and brightness control
- App launcher endpoints
- Clean UI with Riverpod state management

### 🖥️ Python Backend (`backendandWidget`)
- Flask REST API server (`server.py`)
- Standalone battery widget (`BatteryMonitor.py`)
- System information endpoints
- Power control endpoints
- Requirements file for easy setup

## 📂 Project Structure

pc_remote/
│
├── backendandWidget/
│   ├── server.py
│   ├── BatteryMonitor.py
│   ├── requirements.txt
│   └── (other backend files)
│
├── flutter_app/ (or your Flutter project root)
│   └── lib/
│       └── ...
│
└── README.md

## 🛠️ Backend Setup (Python)

1. Open a terminal inside the backend folder:

   cd backendandWidget

2. Install dependencies:

   pip install -r requirements.txt

3. Run the server:

   python server.py

The server will start on your local network and the Flutter app will connect to it.

## 📱 Flutter App Setup

1. Install Flutter: https://docs.flutter.dev/get-started/install
2. Open the Flutter project folder
3. Run the app:

   flutter run

4. Make sure your phone and laptop are on the same Wi‑Fi network.

## 🎯 Purpose

This project started as a simple battery widget and evolved into a full remote‑control system for a laptop. It’s designed to be lightweight, fast, and practical — a companion tool that makes your laptop more accessible from your Android device.

## 🙌 Credits

### 👤 Project Author
- **Dominic Radley** — full project creator, developer, designer, and architect  
  - Flutter app development  
  - Python backend development  
  - UI/UX design  
  - System integration  
  - Repository structure and documentation  

### 🛠️ Technologies & Tools
- **Flutter** — mobile UI framework  
- **Dart** — programming language for the Flutter app  
- **Python** — backend logic and system control  
- **Flask** — REST API server  
- **psutil** — system information (CPU, RAM, battery, etc.)  
- **pywin32 / ctypes** — Windows system control 
- **Visual Studio / VS Code** — development environment  
- **Git & GitHub** — version control and project hosting  

### 💡 Inspiration & Purpose
- Built to create a seamless way to monitor and control a laptop from an Android device  
- Inspired by the desire for a lightweight, personal remote‑control companion  

## 📄 License

This project uses the GPL 3.0 License (see LICENSE file).
