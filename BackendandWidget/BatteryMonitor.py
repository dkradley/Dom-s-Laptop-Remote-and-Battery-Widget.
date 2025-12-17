# -*- coding: utf-8 -*-
"""
Battery Monitor - unified program
- Launch menu (Launch Widget / Settings)
- Settings persist to settings.json
- Modern Windows-11-style rounded battery widget
- Scaled for 200% DPI (widget 400x150, launcher 500x260)
- Local JSON API with many endpoints (no volume)
"""

import ctypes
import os
import json
import socket
import tkinter as tk
from tkinter import messagebox
import threading
import tempfile
from datetime import datetime

import psutil
from flask import Flask, jsonify, send_file, request

# -------- OPTIONAL DEPENDENCIES --------

try:
    import pyautogui
except Exception:
    pyautogui = None

try:
    import screen_brightness_control as sbc
except Exception:
    sbc = None

# -------- DPI FIX --------
try:
    ctypes.windll.shcore.SetProcessDpiAwareness(1)
except Exception:
    try:
        ctypes.windll.user32.SetProcessDPIAware()
    except Exception:
        pass

APP_TITLE = "Battery Monitor"
SETTINGS_FILE = "settings.json"

DEFAULT_SETTINGS = {
    "position": "top-right",
    "transparency": 0,
    "theme": "light",
    "icon_size": "large",
    "font_size": 16,
    "color_thresholds": {"low": 20, "med": 30},
    "show_close_button": True,
    "show_info": "both",
    "update_interval": 5000,
    "notification_style": "popup",
    "drag_enabled": True
}

battery_state = {
    "battery": None,
    "charging": None,
    "remaining": None,
    "powerPlan": None
}

# ---------------- SETTINGS ----------------

def load_settings():
    try:
        if os.path.exists(SETTINGS_FILE):
            with open(SETTINGS_FILE, "r", encoding="utf-8") as f:
                data = json.load(f)
                merged = DEFAULT_SETTINGS.copy()
                merged.update(data)
                if "color_thresholds" in data:
                    merged["color_thresholds"].update(data["color_thresholds"])
                return merged
    except Exception:
        pass
    return DEFAULT_SETTINGS.copy()

def save_settings(settings):
    try:
        with open(SETTINGS_FILE, "w", encoding="utf-8") as f:
            json.dump(settings, f, indent=4)
    except Exception as e:
        messagebox.showerror("Save Error", f"Failed to save settings: {e}")

# ---------------- WINDOWS BATTERY API ----------------

class SYSTEM_POWER_STATUS(ctypes.Structure):
    _fields_ = [
        ("ACLineStatus", ctypes.c_byte),
        ("BatteryFlag", ctypes.c_byte),
        ("BatteryLifePercent", ctypes.c_byte),
        ("Reserved1", ctypes.c_byte),
        ("BatteryLifeTime", ctypes.c_ulong),
        ("BatteryFullLifeTime", ctypes.c_ulong),
    ]

def get_system_power_status():
    status = SYSTEM_POWER_STATUS()
    if not ctypes.windll.kernel32.GetSystemPowerStatus(ctypes.byref(status)):
        raise ctypes.WinError()
    return status

def format_time(secs: int) -> str:
    if secs is None or secs < 0 or secs == 0xFFFFFFFF:
        return "--"
    hours = secs // 3600
    minutes = (secs % 3600) // 60
    return f"{hours}h {minutes:02d}m" if hours > 0 else f"{minutes}m"

def color_for_percent(pct: float) -> str:
    if pct < 20:
        return "#F44336"
    elif pct < 30:
        return "#FFC107"
    else:
        return "#4CAF50"

def best_contrast_text_color(bg_hex: str) -> str:
    bg_hex = bg_hex.lstrip("#")
    try:
        r, g, b = tuple(int(bg_hex[i:i+2], 16) for i in (0, 2, 4))
    except Exception:
        return "#000000"
    luminance = 0.299*r + 0.587*g + 0.114*b
    return "#000000" if luminance > 186 else "#FFFFFF"

# ---------------- POWER PLAN ----------------

POWER_PLANS = {
    "balanced": "381b4222-f694-41f0-9685-ff5bb260df2e",
    "high": "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c",
    "power_saver": "a1841308-3541-4fab-bc81-f71556f20b4a"
}

def get_current_power_plan():
    try:
        result = os.popen("powercfg /getactivescheme").read().strip()
        if "(" in result and ")" in result:
            return result.split("(")[-1].split(")")[0]
        return result
    except Exception:
        return "Unknown"

# ---------------- FLASK JSON API ----------------

app = Flask(__name__)

@app.route("/status")
def status():
    # Battery info (already maintained by your widget)
    battery = battery_state.get("battery")
    charging = battery_state.get("charging")
    remaining = battery_state.get("remaining")
    power_plan = battery_state.get("powerPlan")

    # CPU + RAM
    cpu = psutil.cpu_percent(interval=0.1)
    ram = psutil.virtual_memory().percent

    # Disk usage (main drive)
    disk = psutil.disk_usage("/").percent

    # Temperature (if available)
    try:
        temps = psutil.sensors_temperatures()
        if temps:
            # Pick first available sensor
            first = list(temps.values())[0]
            temperature = first[0].current
        else:
            temperature = None
    except Exception:
        temperature = None

    # Uptime
    boot_time = datetime.fromtimestamp(psutil.boot_time())
    uptime_delta = datetime.now() - boot_time
    uptime_str = str(uptime_delta).split(".")[0]  # HH:MM:SS

    return jsonify({
        "battery": battery,
        "charging": charging,
        "remaining": remaining,
        "powerPlan": power_plan,
        "cpu": cpu,
        "ram": ram,
        "disk": disk,
        "temperature": temperature,
        "uptime": uptime_str
    })

@app.route("/ping")
def ping():
    return jsonify({"alive": True})

@app.route("/info")
def info():
    return jsonify({
        "hostname": socket.gethostname(),
        "computername_env": os.getenv("COMPUTERNAME"),
        "cpu_percent": psutil.cpu_percent(),
        "ram_percent": psutil.virtual_memory().percent
    })
# --- Power plan control ---

@app.route("/setPowerPlan/<plan>")
def set_power_plan(plan):
    plan = plan.lower()
    if plan not in POWER_PLANS:
        return jsonify({"success": False, "error": "Unknown plan"}), 400
    guid = POWER_PLANS[plan]
    os.system(f"powercfg /setactive {guid}")
    return jsonify({"success": True, "activePlan": plan})

# -------------------------
# Quick Access Commands
# -------------------------

@app.route("/display_off")
def display_off():
    import subprocess
    cmd = r'''
    $signature = @"
    [DllImport("user32.dll")]
    public static extern int SendMessage(int hWnd, int Msg, int wParam, int lParam);
"@
    Add-Type -MemberDefinition $signature -Name Win32 -Namespace Native
    [Native.Win32]::SendMessage(-1, 0x0112, 0xF170, 2)
    '''
    subprocess.call(["powershell", "-Command", cmd])
    return {"ok": True}


@app.route("/volume/mute")
def volume_mute():
    import subprocess
    subprocess.call("nircmd.exe mutesysvolume 2", shell=True)
    return {"ok": True}


@app.route("/volume/up")
def volume_up():
    import subprocess
    subprocess.call("nircmd.exe changesysvolume 5000", shell=True)
    return {"ok": True}


@app.route("/volume/down")
def volume_down():
    import subprocess
    subprocess.call("nircmd.exe changesysvolume -5000", shell=True)
    return {"ok": True}


@app.route("/open/browser")
def open_browser():
    import webbrowser
    webbrowser.open("https://google.com")
    return {"ok": True}


@app.route("/open/explorer")
def open_explorer():
    import subprocess
    subprocess.Popen("explorer")
    return {"ok": True}


@app.route("/open/taskmgr")
def open_taskmgr():
    import subprocess
    subprocess.Popen("taskmgr")
    return {"ok": True}


@app.route("/open/notepad")
def open_notepad():
    import subprocess
    subprocess.Popen("notepad")
    return {"ok": True}
# --- Power control ---

@app.route("/shutdown")
def shutdown_pc():
    os.system("shutdown /s /t 0")
    return jsonify({"success": True, "action": "shutdown"})

@app.route("/restart")
def restart_pc():
    os.system("shutdown /r /t 0")
    return jsonify({"success": True, "action": "restart"})

@app.route("/sleep")
def sleep_pc():
    os.system("rundll32.exe powrprof.dll,SetSuspendState 0,1,0")
    return jsonify({"success": True, "action": "sleep"})

@app.route("/lock")
def lock_pc():
    os.system("rundll32.exe user32.dll,LockWorkStation")
    return jsonify({"success": True, "action": "lock"})

@app.route("/logout")
def logout_pc():
    os.system("shutdown /l")
    return jsonify({"success": True, "action": "logout"})

# --- System / network info ---

@app.route("/network")
def network_info():
    addrs = {}
    for iface, snics in psutil.net_if_addrs().items():
        addrs[iface] = []
        for snic in snics:
            if snic.family == socket.AF_INET:
                addrs[iface].append({
                    "address": snic.address,
                    "netmask": snic.netmask,
                    "broadcast": snic.broadcast
                })
    return jsonify({
        "hostname": socket.gethostname(),
        "interfaces": addrs
    })

@app.route("/disk")
def disk_info():
    partitions_info = []
    for p in psutil.disk_partitions():
        try:
            usage = psutil.disk_usage(p.mountpoint)
            partitions_info.append({
                "device": p.device,
                "mountpoint": p.mountpoint,
                "fstype": p.fstype,
                "total_gb": round(usage.total / (1024 ** 3), 2),
                "used_gb": round(usage.used / (1024 ** 3), 2),
                "free_gb": round(usage.free / (1024 ** 3), 2),
                "percent": usage.percent
            })
        except PermissionError:
            continue
    return jsonify({"partitions": partitions_info})

# --- Process control ---

@app.route("/processes")
def list_processes():
    procs = []
    for p in psutil.process_iter(["pid", "name", "cpu_percent", "memory_percent"]):
        try:
            info = p.info
            procs.append({
                "pid": info.get("pid"),
                "name": info.get("name"),
                "cpu_percent": info.get("cpu_percent"),
                "memory_percent": round(info.get("memory_percent", 0) or 0, 2)
            })
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            continue
    return jsonify({"processes": procs})

@app.route("/kill/<int:pid>")
def kill_process(pid):
    try:
        p = psutil.Process(pid)
        name = p.name()
        p.terminate()
        return jsonify({"success": True, "killed": {"pid": pid, "name": name}})
    except psutil.NoSuchProcess:
        return jsonify({"success": False, "error": "No such process"}), 404
    except psutil.AccessDenied:
        return jsonify({"success": False, "error": "Access denied"}), 403
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

# --- Brightness ---

@app.route("/brightness/<int:level>")
def http_set_brightness(level):
    try:
        if sbc is None:
            return jsonify({"success": False, "error": "Brightness control not available on this system."}), 501
        level = max(0, min(100, int(level)))
        sbc.set_brightness(level)
        return jsonify({"success": True, "brightness": level})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

@app.route("/brightness")
def http_get_brightness():
    try:
        if sbc is None:
            return jsonify({"success": False, "error": "Brightness control not available on this system."}), 501
        current = sbc.get_brightness()
        if isinstance(current, list):
            current = current[0]
        return jsonify({"success": True, "brightness": int(current)})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

# --- Media keys ---

@app.route("/media/playpause")
def media_playpause():
    if pyautogui is None:
        return jsonify({"success": False, "error": "pyautogui not available"}), 501
    try:
        pyautogui.press("playpause")
        return jsonify({"success": True})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

@app.route("/media/next")
def media_next():
    if pyautogui is None:
        return jsonify({"success": False, "error": "pyautogui not available"}), 501
    try:
        pyautogui.press("nexttrack")
        return jsonify({"success": True})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

@app.route("/media/prev")
def media_prev():
    if pyautogui is None:
        return jsonify({"success": False, "error": "pyautogui not available"}), 501
    try:
        pyautogui.press("prevtrack")
        return jsonify({"success": True})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

# --- Mouse control ---

@app.route("/mouse/move/<int:x>/<int:y>")
def mouse_move(x, y):
    if pyautogui is None:
        return jsonify({"success": False, "error": "pyautogui not available"}), 501
    try:
        pyautogui.moveTo(x, y)
        return jsonify({"success": True, "x": x, "y": y})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

@app.route("/mouse/click")
def mouse_click():
    if pyautogui is None:
        return jsonify({"success": False, "error": "pyautogui not available"}), 501
    try:
        pyautogui.click()
        return jsonify({"success": True})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

# --- Typing ---

@app.route("/type")
def type_text():
    if pyautogui is None:
        return jsonify({"success": False, "error": "pyautogui not available"}), 501
    try:
        text = request.args.get("text", "")
        if not text:
            return jsonify({"success": False, "error": "No text provided"}), 400
        pyautogui.typewrite(text)
        return jsonify({"success": True, "typed": text})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

# --- Screenshot ---

@app.route("/screenshot")
def screenshot():
    if pyautogui is None:
        return jsonify({"success": False, "error": "pyautogui not available"}), 501
    try:
        img = pyautogui.screenshot()
        tmp_dir = tempfile.gettempdir()
        filename = f"screenshot_{datetime.now().strftime('%Y%m%d_%H%M%S')}.png"
        path = os.path.join(tmp_dir, filename)
        img.save(path)
        return send_file(path, mimetype="image/png", as_attachment=True, download_name=filename)
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500
    # --- File download ---

@app.route("/download")
def download_file():
    path = request.args.get("path")
    if not path:
        return jsonify({"success": False, "error": "No path provided"}), 400
    if not os.path.exists(path):
        return jsonify({"success": False, "error": "File not found"}), 404
    try:
        return send_file(path, as_attachment=True)
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

# --- Wake-on-LAN ---

def send_magic_packet(mac_address: str):
    mac = mac_address.replace(":", "").replace("-", "")
    if len(mac) != 12:
        raise ValueError("Invalid MAC address")
    data = "FF" * 6 + mac * 16
    packet = bytes.fromhex(data)
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
        s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
        s.sendto(packet, ("<broadcast>", 9))

@app.route("/wol")
def wol():
    mac = request.args.get("mac")
    if not mac:
        return jsonify({"success": False, "error": "No MAC provided"}), 400
    try:
        send_magic_packet(mac)
        return jsonify({"success": True, "mac": mac})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

# --- Actions list ---

@app.route("/actions")
def actions():
    return jsonify({
        "endpoints": [
            "/status", "/ping", "/info", "/network", "/disk",
            "/processes", "/kill/<pid>",
            "/setPowerPlan/<balanced|high|power_saver>",
            "/shutdown", "/restart", "/sleep", "/lock", "/logout",
            "/brightness", "/brightness/<level>",
            "/media/playpause", "/media/next", "/media/prev",
            "/mouse/move/<x>/<y>", "/mouse/click",
            "/type?text=...", "/screenshot",
            "/download?path=...", "/wol?mac=..."
        ]
    })

def start_http_server():
    app.run(host="0.0.0.0", port=5000, debug=False)

# ---------------- MODERN ROUNDED BATTERY WIDGET ----------------

class BatteryWindow:
    def __init__(self, root, settings):
        self.root = root
        self.settings = settings

        self.root.title(APP_TITLE)
        self.root.overrideredirect(True)
        self.root.resizable(False, False)

        # DPI scaling for 200%
        self.root.tk.call('tk', 'scaling', 2.0)

        # Transparent background
        self.root.configure(bg="pink")
        try:
            self.root.wm_attributes("-transparentcolor", "pink")
        except Exception:
            pass

        # Widget size
        self.canvas_width = 400
        self.canvas_height = 150

        screen_w = self.root.winfo_screenwidth()
        x = screen_w - self.canvas_width - 20
        y = 20
        self.root.geometry(f"{self.canvas_width}x{self.canvas_height}+{x}+{y}")

        self.canvas = tk.Canvas(
            self.root,
            width=self.canvas_width,
            height=self.canvas_height,
            bg="pink",
            highlightthickness=0
        )
        self.canvas.pack()

        # --- Battery shape ---
        self.batt_x1 = 50
        self.batt_y1 = 40
        self.batt_x2 = 350
        self.batt_y2 = 110
        self.batt_radius = 20

        # Battery cap
        self.cap_x1 = 350
        self.cap_y1 = 60
        self.cap_x2 = 370
        self.cap_y2 = 90

        # Outline
        self.batt_outline = self.draw_rounded_rect(
            self.batt_x1, self.batt_y1,
            self.batt_x2, self.batt_y2,
            self.batt_radius,
            outline="#212121",
            width=3,
            fill=""
        )

        # Cap
        self.batt_cap = self.canvas.create_rectangle(
            self.cap_x1, self.cap_y1,
            self.cap_x2, self.cap_y2,
            outline="#212121",
            width=3,
            fill=""
        )

        # Fill bar (initial)
        self.batt_fill = self.draw_rounded_rect(
            self.batt_x1 + 4, self.batt_y1 + 4,
            self.batt_x1 + 4, self.batt_y2 - 4,
            self.batt_radius - 6,
            outline="",
            fill="#4CAF50"
        )

        # Text centered inside battery
        self.batt_text = self.canvas.create_text(
            (self.batt_x1 + self.batt_x2) // 2,
            (self.batt_y1 + self.batt_y2) // 2,
            text="",
            font=("Segoe UI", 22, "bold"),
            fill="#212121"
        )

        # Close button
        if self.settings.get("show_close_button", True):
            self.close_btn = self.canvas.create_text(
                380, 20,
                text="✖",
                font=("Segoe UI", 20, "bold"),
                fill="white"
            )
            self.canvas.tag_bind(self.close_btn, "<Button-1>", self.confirm_close)
            self.canvas.tag_bind(self.close_btn, "<Enter>", lambda e: self.canvas.itemconfig(self.close_btn, fill="red"))
            self.canvas.tag_bind(self.close_btn, "<Leave>", lambda e: self.canvas.itemconfig(self.close_btn, fill="white"))

        # Dragging
        if self.settings.get("drag_enabled", True):
            self.offset_x = 0
            self.offset_y = 0
            self.canvas.bind("<ButtonPress-1>", self.start_move)
            self.canvas.bind("<B1-Motion>", self.do_move)

        # Animation state
        self.current_fill_width = 0
        self.target_fill_width = 0
        self.animation_duration = 250  # S2 = 250ms
        self.animation_fps = 60
        self.animation_steps = int(self.animation_duration / (1000 / self.animation_fps))
        self.animation_step = 0

        self.update_battery()
        self.root.after(
            max(1000, int(self.settings.get("update_interval", 5000))),
            self.schedule_update
        )

    # --- Rounded rectangle helper ---
    def draw_rounded_rect(self, x1, y1, x2, y2, r, **kwargs):
        points = [
            x1+r, y1,
            x2-r, y1,
            x2, y1,
            x2, y1+r,
            x2, y2-r,
            x2, y2,
            x2-r, y2,
            x1+r, y2,
            x1, y2,
            x1, y2-r,
            x1, y1+r,
            x1, y1
        ]
        return self.canvas.create_polygon(points, smooth=True, **kwargs)

    # --- Dragging ---
    def start_move(self, event):
        self.offset_x = event.x_root - self.root.winfo_x()
        self.offset_y = event.y_root - self.root.winfo_y()

    def do_move(self, event):
        new_x = event.x_root - self.offset_x
        new_y = event.y_root - self.offset_y
        self.root.geometry(f"+{new_x}+{new_y}")
            # --- Close ---
    def confirm_close(self, event=None):
        if messagebox.askyesno("Confirm Exit", "Close Battery Monitor?"):
            self.root.destroy()

    # --- Animation engine (60fps smooth fill) ---
    def animate_fill(self):
        if self.animation_step >= self.animation_steps:
            self.current_fill_width = self.target_fill_width
        else:
            progress = self.animation_step / self.animation_steps
            self.current_fill_width = int(
                self.start_fill_width +
                (self.target_fill_width - self.start_fill_width) * progress
            )
            self.animation_step += 1
            self.root.after(int(1000 / self.animation_fps), self.animate_fill)

        # Redraw fill bar
        self.canvas.delete(self.batt_fill)
        self.batt_fill = self.draw_rounded_rect(
            self.batt_x1 + 4, self.batt_y1 + 4,
            self.batt_x1 + 4 + self.current_fill_width, self.batt_y2 - 4,
            self.batt_radius - 6,
            outline="",
            fill=self.current_fill_color
        )

    # --- Update loop ---
    def schedule_update(self):
        self.update_battery()
        self.root.after(
            max(1000, int(self.settings.get("update_interval", 5000))),
            self.schedule_update
        )

    def update_battery(self):
        global battery_state

        try:
            status = get_system_power_status()
        except Exception:
            self.canvas.itemconfig(self.batt_text, text="--", fill="#FFFFFF")
            return

        percent = status.BatteryLifePercent
        if percent == 255:
            percent = 0

        bar_color = color_for_percent(percent)
        text_color = best_contrast_text_color(bar_color)

        # Compute fill width
        full_width = (self.batt_x2 - self.batt_x1) - 8
        new_width = int(full_width * (percent / 100.0))

        # Start animation
        self.start_fill_width = self.current_fill_width
        self.target_fill_width = new_width
        self.current_fill_color = bar_color
        self.animation_step = 0
        self.animate_fill()

        plugged = (status.ACLineStatus == 1)
        secs_left = status.BatteryLifeTime

        battery_state["battery"] = percent
        battery_state["charging"] = bool(plugged)
        battery_state["remaining"] = format_time(secs_left)
        battery_state["powerPlan"] = get_current_power_plan()

        # Text inside battery
        if plugged:
            self.canvas.itemconfig(self.batt_text, text="⚡", fill=text_color)
        else:
            remaining = format_time(secs_left)
            text = f"{percent}% • {remaining}"
            self.canvas.itemconfig(self.batt_text, text=text, fill=text_color)

# ---------------- SETTINGS WINDOW ----------------

class SettingsWindow:
    def __init__(self, parent):
        self.settings = load_settings()
        self.top = tk.Toplevel(parent)
        self.top.title("Settings")
        self.top.geometry("500x400")
        self.top.resizable(False, False)

        self.top.tk.call('tk', 'scaling', 2.0)

        frame = tk.Frame(self.top, padx=20, pady=20)
        frame.pack(fill="both", expand=True)

        tk.Label(frame, text="Transparency (0 = opaque, 100 = fully transparent)").pack(anchor="w")
        self.transparency_var = tk.IntVar(value=self.settings.get("transparency", 0))
        tk.Scale(frame, from_=0, to=100, orient="horizontal", variable=self.transparency_var, length=300).pack(pady=6)

        self.close_var = tk.BooleanVar(value=self.settings.get("show_close_button", True))
        tk.Checkbutton(frame, text="Show Close Button", variable=self.close_var).pack(anchor="w", pady=4)

        self.drag_var = tk.BooleanVar(value=self.settings.get("drag_enabled", True))
        tk.Checkbutton(frame, text="Enable Drag-to-Move", variable=self.drag_var).pack(anchor="w", pady=4)

        tk.Label(frame, text="Info Display").pack(anchor="w", pady=(8, 0))
        self.info_var = tk.StringVar(value=self.settings.get("show_info", "both"))
        tk.OptionMenu(frame, self.info_var, "percent", "time", "both").pack(anchor="w", pady=4)

        tk.Label(frame, text="Update Interval (ms)").pack(anchor="w", pady=(8, 0))
        self.update_var = tk.IntVar(value=self.settings.get("update_interval", 5000))
        tk.Scale(frame, from_=1000, to=30000, orient="horizontal", resolution=500,
                 variable=self.update_var, length=300).pack(pady=6)

        btn_frame = tk.Frame(frame)
        btn_frame.pack(fill="x", pady=12)
        tk.Button(btn_frame, text="Reset to Defaults", command=self.reset_defaults).pack(side="left", padx=(0, 6))
        tk.Button(btn_frame, text="Save", command=self.save).pack(side="right", padx=(6, 0))

    def reset_defaults(self):
        if messagebox.askyesno("Reset", "Restore default settings?"):
            self.settings = DEFAULT_SETTINGS.copy()
            self.transparency_var.set(self.settings["transparency"])
            self.close_var.set(self.settings["show_close_button"])
            self.drag_var.set(self.settings["drag_enabled"])
            self.info_var.set(self.settings["show_info"])
            self.update_var.set(self.settings["update_interval"])

    def save(self):
        self.settings["transparency"] = int(self.transparency_var.get())
        self.settings["show_close_button"] = bool(self.close_var.get())
        self.settings["drag_enabled"] = bool(self.drag_var.get())
        self.settings["show_info"] = str(self.info_var.get())
        self.settings["update_interval"] = int(self.update_var.get())

        save_settings(self.settings)
        messagebox.showinfo("Settings", "Settings saved.")
        self.top.destroy()

# ---------------- LAUNCHER WINDOW ----------------

class LaunchMenu:
    def __init__(self, root):
        self.root = root
        self.root.title("Battery Monitor Launcher")
        self.root.geometry("500x260")
        self.root.resizable(False, False)

        self.root.tk.call('tk', 'scaling', 2.0)

        frame = tk.Frame(root, padx=20, pady=20)
        frame.pack(fill="both", expand=True)

        tk.Label(frame, text="Battery Monitor", font=("Segoe UI", 20, "bold")).pack(pady=(0, 12))
        tk.Label(frame, text="Choose an action:", font=("Segoe UI", 12)).pack()

        btn_frame = tk.Frame(frame)
        btn_frame.pack(pady=20)

        tk.Button(btn_frame, text="Launch Widget", width=16, height=2, command=self.launch_widget).pack(side="left", padx=10)
        tk.Button(btn_frame, text="Settings", width=16, height=2, command=self.open_settings).pack(side="right", padx=10)

        tk.Button(frame, text="Exit", width=10, command=self.root.destroy).pack(side="bottom", pady=(10, 0))

    def launch_widget(self):
        try:
            self.root.destroy()
        except Exception:
            pass

        widget_root = tk.Tk()
        widget_root.tk.call('tk', 'scaling', 2.0)

        settings = load_settings()
        BatteryWindow(widget_root, settings)
        widget_root.mainloop()

    def open_settings(self):
        SettingsWindow(self.root)

# ---------------- MAIN ----------------

def main():
    server_thread = threading.Thread(target=start_http_server, daemon=True)
    server_thread.start()

    root = tk.Tk()
    root.tk.call('tk', 'scaling', 2.0)
    LaunchMenu(root)
    root.mainloop()

if __name__ == "__main__":
    main()