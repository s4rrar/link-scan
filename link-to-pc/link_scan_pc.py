#!/usr/bin/env python3
"""
WiFi Barcode Scanner — LinkScanPC
System tray app with HTTP server, keystroke wedge, and settings panel.
"""

import sys
import os
import json
import time
import socket
import logging
import threading
import datetime
import queue
from http.server import HTTPServer, BaseHTTPRequestHandler
from pathlib import Path

# ── third-party ──────────────────────────────────────────────────────────────
try:
    import pystray
    from pystray import MenuItem as item
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    sys.exit("Install: pip install pystray pillow")

try:
    import tkinter as tk
    from tkinter import ttk, messagebox, scrolledtext
except ImportError:
    sys.exit("tkinter is required (usually bundled with Python).")

try:
    from pynput.keyboard import Controller as KbController, Key
    keyboard = KbController()
    HAS_KEYBOARD = True
except Exception:
    HAS_KEYBOARD = False

# ── paths & config ────────────────────────────────────────────────────────────
OLD_APP_DIR = Path.home() / ".barcode_companion"
APP_DIR     = Path.home() / ".linkscanpc"
APP_DIR.mkdir(exist_ok=True)

# Migrate old settings if they exist and new settings don't
OLD_CFG = OLD_APP_DIR / "settings.json"
CFG_FILE = APP_DIR / "settings.json"
if OLD_CFG.exists() and not CFG_FILE.exists():
    try:
        CFG_FILE.write_text(OLD_CFG.read_text())
    except Exception:
        pass

LOG_FILE  = APP_DIR / "scans.log"

logging.basicConfig(
    filename=str(APP_DIR / "app.log"),
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s"
)

DEFAULT_SETTINGS = {
    "port":           8080,
    "suffix":         "enter",        # enter | tab | none
    "prefix":         "",
    "custom_suffix":  "",
    "beep":           True,
    "show_notify":    True,
    "log_scans":      True,
    "auto_start":     True,
    "theme":          "dark",
}


def load_settings() -> dict:
    if CFG_FILE.exists():
        try:
            saved = json.loads(CFG_FILE.read_text())
            return {**DEFAULT_SETTINGS, **saved}
        except Exception:
            pass
    return dict(DEFAULT_SETTINGS)


def save_settings(cfg: dict):
    CFG_FILE.write_text(json.dumps(cfg, indent=2))


# ── shared state ──────────────────────────────────────────────────────────────
cfg            = load_settings()
server_thread  = None
http_server    = None
server_running = False
scan_count     = 0
last_scan      = ""
last_scan_ts   = ""
scan_history   = []          # list of dicts
ui_queue       = queue.Queue()   # thread-safe msgs → GUI
settings_win   = None
tray_icon      = None


# ── tray icon image (neon green on slate) ────────────────────────────────────
def make_tray_image(active: bool = True) -> Image.Image:
    size = 64
    img  = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d    = ImageDraw.Draw(img)
    
    is_dark = cfg.get("theme", "dark") == "dark"
    bg   = (26, 31, 38, 255) if is_dark else (240, 244, 248, 255)
    
    if active:
        fg = (158, 202, 255, 255) if is_dark else (0, 97, 164, 255)
    else:
        fg = (142, 144, 153, 255) if is_dark else (83, 95, 112, 255)

    # Rounded rect background
    d.rounded_rectangle([0, 0, size - 1, size - 1], radius=12, fill=bg)

    # Barcode lines
    bars = [8, 12, 16, 20, 26, 30, 36, 40, 46, 50, 54]
    for i, x in enumerate(bars):
        w = 2 if i % 2 == 0 else 3
        d.rectangle([x, 12, x + w, 40], fill=fg)

    # WiFi arc (bottom)
    d.arc([16, 42, 48, 56], start=200, end=340, fill=fg, width=3)
    d.ellipse([30, 50, 34, 54], fill=fg)

    return img


# ── HTTP server ───────────────────────────────────────────────────────────────
class ScanHandler(BaseHTTPRequestHandler):

    def log_message(self, fmt, *args):   # silence default logging
        pass

    def _json(self, code: int, body: dict):
        data = json.dumps(body).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        if self.path == "/ping":
            self._json(200, {"status": "ok", "server": "LinkScanPC"})
        else:
            self._json(404, {"error": "not found"})

    def do_POST(self):
        if self.path != "/scan":
            self._json(404, {"error": "not found"})
            return
        try:
            length  = int(self.headers.get("Content-Length", 0))
            payload = json.loads(self.rfile.read(length))
            barcode = str(payload.get("barcode", "")).strip()
            fmt     = str(payload.get("format", "UNKNOWN"))
            ts      = payload.get("timestamp", int(time.time() * 1000))
            if not barcode:
                self._json(400, {"error": "empty barcode"})
                return
            handle_scan(barcode, fmt, ts)
            self._json(200, {"status": "received"})
        except Exception as exc:
            logging.exception("POST /scan error")
            self._json(500, {"error": str(exc)})


def handle_scan(barcode: str, fmt: str, ts: int):
    global scan_count, last_scan, last_scan_ts
    scan_count += 1
    dt = datetime.datetime.fromtimestamp(ts / 1000).strftime("%Y-%m-%d %H:%M:%S")
    last_scan    = barcode
    last_scan_ts = dt

    entry = {"barcode": barcode, "format": fmt, "time": dt}
    scan_history.insert(0, entry)
    if len(scan_history) > 500:
        scan_history.pop()

    logging.info("SCAN  %s  [%s]", barcode, fmt)

    if cfg.get("log_scans"):
        with open(LOG_FILE, "a") as f:
            f.write(f"{dt}\t{fmt}\t{barcode}\n")

    # Send keystrokes
    if HAS_KEYBOARD:
        try:
            full = cfg.get("prefix", "") + barcode
            suffix_opt = cfg.get("suffix", "enter")
            keyboard.type(full)
            if suffix_opt == "enter":
                keyboard.press(Key.enter);  keyboard.release(Key.enter)
            elif suffix_opt == "tab":
                keyboard.press(Key.tab);    keyboard.release(Key.tab)
            elif suffix_opt == "custom":
                cs = cfg.get("custom_suffix", "")
                if cs:
                    keyboard.type(cs)
        except Exception as exc:
            logging.warning("Keyboard error: %s", exc)

    # Send desktop notification
    if cfg.get("show_notify") and tray_icon:
        try:
            tray_icon.notify(f"Scanned: {barcode}", title="LinkScanPC")
        except Exception as exc:
            logging.warning("Notification error: %s", exc)

    # Notify GUI
    ui_queue.put(("scan", entry))


def start_server():
    global http_server, server_running
    port = int(cfg.get("port", 8080))
    try:
        http_server    = HTTPServer(("0.0.0.0", port), ScanHandler)
        server_running = True
        ui_queue.put(("status", True))
        logging.info("Server started on port %d", port)
        http_server.serve_forever()
    except OSError as exc:
        server_running = False
        ui_queue.put(("error", f"Cannot bind port {port}: {exc}"))
        logging.error("Server start failed: %s", exc)


def stop_server():
    global http_server, server_running
    if http_server:
        http_server.shutdown()
        http_server = None
    server_running = False
    ui_queue.put(("status", False))
    logging.info("Server stopped")


def toggle_server():
    global server_thread
    if server_running:
        threading.Thread(target=stop_server, daemon=True).start()
    else:
        server_thread = threading.Thread(target=start_server, daemon=True)
        server_thread.start()


# ── Settings / dashboard window ───────────────────────────────────────────────
DARK  = {"bg": "#121314", "fg": "#E2E2E6", "acc": "#9ECAFF", "acc_hover": "#C4E2FF",
         "on_acc": "#003258", "card": "#1A1C1E", "border": "#3B4858", "entry_bg": "#0F1113",
         "dim": "#8E9099", "red": "#FFB4AB", "red_hover": "#FFDAD6", "on_red": "#690005",
         "yellow": "#FFD54F"}
LIGHT = {"bg": "#FDFBFF", "fg": "#1A1C1E", "acc": "#0061A4", "acc_hover": "#00497D",
         "on_acc": "#FFFFFF", "card": "#FFFFFF", "border": "#D6E4F7", "entry_bg": "#F3F3FA",
         "dim": "#535F70", "red": "#BA1A1A", "red_hover": "#FFDAD6", "on_red": "#FFFFFF",
         "yellow": "#F57F17"}


def get_theme():
    return DARK if cfg.get("theme", "dark") == "dark" else LIGHT


class SettingsWindow:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title("LinkScanPC")
        self.root.geometry("740x620")
        self.root.resizable(True, True)
        self.root.minsize(640, 500)
        self._apply_theme()
        self._build_ui()
        self._poll_queue()
        self.root.protocol("WM_DELETE_WINDOW", self._hide)
        self.root.withdraw()

    def _apply_theme(self):
        t = get_theme()
        self.t = t
        self.root.configure(bg=t["bg"])
        style = ttk.Style(self.root)
        style.theme_use("clam")
        
        # Configure standard layouts and colors
        style.configure("TFrame", background=t["bg"])
        style.configure("Card.TFrame", background=t["card"], relief="flat")
        style.configure("TLabel", background=t["bg"], foreground=t["fg"],
                        font=("Segoe UI", 10))
        style.configure("Head.TLabel", background=t["bg"], foreground=t["acc"],
                        font=("Segoe UI", 13, "bold"))
        style.configure("Sub.TLabel", background=t["bg"], foreground=t["dim"],
                        font=("Segoe UI", 9))
        style.configure("Card.TLabel", background=t["card"], foreground=t["fg"],
                        font=("Segoe UI", 10))
        style.configure("Stat.TLabel", background=t["card"], foreground=t["acc"],
                        font=("Segoe UI", 22, "bold"))
        
        # Buttons styling (Material Flat style with hover)
        style.configure("TButton", background=t["acc"], foreground=t["on_acc"],
                        font=("Segoe UI", 10, "bold"), padding=8, relief="flat", borderwidth=0)
        style.map("TButton",
                  background=[("active", t["acc_hover"]), ("disabled", t["border"])],
                  foreground=[("active", t["on_acc"])])
        
        style.configure("Stop.TButton", background=t["red"], foreground=t["on_red"],
                        font=("Segoe UI", 10, "bold"), padding=8, relief="flat", borderwidth=0)
        style.map("Stop.TButton",
                  background=[("active", t["red_hover"])],
                  foreground=[("active", t["on_red"])])
        
        style.configure("TEntry", fieldbackground=t["entry_bg"], foreground=t["fg"],
                        insertcolor=t["acc"], font=("Segoe UI", 10), bordercolor=t["border"])
                        
        style.configure("TCombobox", fieldbackground=t["entry_bg"], foreground=t["fg"],
                        font=("Segoe UI", 10), bordercolor=t["border"])
                        
        style.configure("TCheckbutton", background=t["bg"], foreground=t["fg"],
                        font=("Segoe UI", 10))
        style.map("TCheckbutton",
                  background=[("active", t["bg"])],
                  foreground=[("active", t["fg"])])
                  
        style.configure("Horizontal.TScale", background=t["bg"], troughcolor=t["border"])
        style.configure("TNotebook", background=t["bg"], borderwidth=0, tabmargins=[2, 2, 0, 0])
        style.configure("TNotebook.Tab",
                        background=t["card"], foreground=t["dim"],
                        font=("Segoe UI", 10), padding=[14, 6])
        style.map("TNotebook.Tab",
                  background=[("selected", t["bg"])],
                  foreground=[("selected", t["acc"])])
                  
        style.configure("Treeview",
                        background=t["card"], foreground=t["fg"],
                        fieldbackground=t["card"], rowheight=26,
                        font=("Segoe UI", 9))
        style.configure("Treeview.Heading",
                        background=t["border"], foreground=t["dim"],
                        font=("Segoe UI", 9, "bold"))
        style.map("Treeview", background=[("selected", t["acc"])],
                  foreground=[("selected", t["on_acc"])])

        # Dynamic Combobox Listbox colors via option db
        self.root.option_add("*TCombobox*Listbox.background", t["entry_bg"])
        self.root.option_add("*TCombobox*Listbox.foreground", t["fg"])
        self.root.option_add("*TCombobox*Listbox.selectBackground", t["acc"])
        self.root.option_add("*TCombobox*Listbox.selectForeground", t["on_acc"])

        # If window is already initialized and open, propagate theme changes recursively
        if hasattr(self, "root") and self.root.winfo_exists():
            self._update_all_widgets(self.root)
            
        # Update the status pill dynamically
        if hasattr(self, "_status_pill") and self._status_pill.winfo_exists():
            if server_running:
                self._status_pill.configure(bg=t["acc"], fg=t["on_acc"])
            else:
                self._status_pill.configure(bg=t["red"], fg=t["on_red"])

    def _update_all_widgets(self, parent):
        t = self.t
        for w in parent.winfo_children():
            # Recursively update children
            self._update_all_widgets(w)
            
            role = getattr(w, "theme_role", None)
            if not role:
                continue
                
            w_class = w.winfo_class()
            
            if role == "bg":
                w.configure(bg=t["bg"])
            elif role == "card":
                w.configure(bg=t["card"], highlightbackground=t["border"])
            elif role == "border":
                w.configure(bg=t["border"])
            elif role == "header":
                w.configure(bg=t["bg"], fg=t["acc"])
            elif role == "text":
                is_in_card = getattr(w, "is_in_card", False)
                w.configure(bg=t["card"] if is_in_card else t["bg"], fg=t["fg"])
            elif role == "label_normal":
                w.configure(bg=t["bg"], fg=t["fg"])
            elif role == "dim":
                is_in_card = getattr(w, "is_in_card", False)
                w.configure(bg=t["card"] if is_in_card else t["bg"], fg=t["dim"])
            elif role == "acc_bold":
                is_in_card = getattr(w, "is_in_card", False)
                w.configure(bg=t["card"] if is_in_card else t["bg"], fg=t["acc"])
            elif role == "warning":
                w.configure(bg=t["bg"], fg=t["yellow"])
            elif role == "radiobutton":
                w.configure(bg=t["bg"], fg=t["fg"], selectcolor=t["card"],
                            activebackground=t["bg"])
            elif role == "ep_method":
                # Keeps custom color based on method
                method = getattr(w, "method_type", "POST")
                fg_col = t["acc"] if method == "POST" else t["yellow"]
                w.configure(bg=t["card"], fg=fg_col)

    def _build_ui(self):
        t = self.t
        root = self.root

        # ── header ──
        hdr = tk.Frame(root, bg=t["bg"], pady=12)
        hdr.theme_role = "bg"
        hdr.pack(fill="x", padx=20)
        
        lbl_logo = tk.Label(hdr, text="⬡  LinkScanPC",
                            bg=t["bg"], fg=t["acc"],
                            font=("Segoe UI", 16, "bold"))
        lbl_logo.theme_role = "header"
        lbl_logo.pack(side="left")

        self._ip_var = tk.StringVar(value=self._local_ip())
        lbl_ip = tk.Label(hdr, textvariable=self._ip_var,
                          bg=t["bg"], fg=t["dim"],
                          font=("Segoe UI", 9))
        lbl_ip.theme_role = "dim"
        lbl_ip.pack(side="right", pady=4)

        # ── notebook ──
        nb = ttk.Notebook(root)
        nb.pack(fill="both", expand=True, padx=16, pady=(0, 8))

        tab_dash     = ttk.Frame(nb)
        tab_server   = ttk.Frame(nb)
        tab_keyboard = ttk.Frame(nb)
        tab_log      = ttk.Frame(nb)

        nb.add(tab_dash,     text=" Dashboard ")
        nb.add(tab_server,   text=" Server ")
        nb.add(tab_keyboard, text=" Keyboard ")
        nb.add(tab_log,      text=" Scan Log ")

        self._build_dashboard(tab_dash)
        self._build_server(tab_server)
        self._build_keyboard(tab_keyboard)
        self._build_log(tab_log)

        # ── footer ──
        foot = tk.Frame(root, bg=t["border"], height=1)
        foot.theme_role = "border"
        foot.pack(fill="x")
        
        fbar = tk.Frame(root, bg=t["bg"], pady=8)
        fbar.theme_role = "bg"
        fbar.pack(fill="x", padx=16)
        
        ttk.Button(fbar, text="Save Settings", command=self._save).pack(side="right", padx=4)
        ttk.Button(fbar, text="Hide to Tray",  command=self._hide).pack(side="right", padx=4)

    # ── Dashboard tab ─────────────────────────────────────────────────────────
    def _build_dashboard(self, parent):
        t = self.t
        parent.configure(style="TFrame")

        # Status card
        scard = tk.Frame(parent, bg=t["card"], bd=0, highlightthickness=1, highlightbackground=t["border"], pady=12, padx=16)
        scard.theme_role = "card"
        scard.pack(fill="x", padx=14, pady=(14, 6))

        top = tk.Frame(scard, bg=t["card"])
        top.theme_role = "card"
        top.pack(fill="x")

        lbl_srv = tk.Label(top, text="SERVER STATUS", bg=t["card"], fg=t["dim"],
                           font=("Segoe UI", 8, "bold"))
        lbl_srv.theme_role = "dim"
        lbl_srv.is_in_card = True
        lbl_srv.pack(side="left")

        self._status_pill = tk.Label(top, text="  ● OFFLINE  ",
                                     bg=t["red"], fg=t["on_red"],
                                     font=("Segoe UI", 9, "bold"), padx=6)
        self._status_pill.theme_role = "status_pill"
        self._status_pill.pack(side="right")

        self._status_var = tk.StringVar(value="Server is not running")
        lbl_status = tk.Label(scard, textvariable=self._status_var,
                              bg=t["card"], fg=t["fg"],
                              font=("Segoe UI", 11))
        lbl_status.theme_role = "text"
        lbl_status.is_in_card = True
        lbl_status.pack(anchor="w", pady=(6, 0))

        self._port_label = tk.Label(scard, text=f"Port: {cfg['port']}",
                                    bg=t["card"], fg=t["dim"],
                                    font=("Segoe UI", 9))
        self._port_label.theme_role = "dim"
        self._port_label.is_in_card = True
        self._port_label.pack(anchor="w")

        # Toggle button
        btn_frame = tk.Frame(parent, bg=t["bg"])
        btn_frame.theme_role = "bg"
        btn_frame.pack(fill="x", padx=14, pady=4)
        self._toggle_btn = ttk.Button(btn_frame, text="▶  Start Server",
                                      command=toggle_server)
        self._toggle_btn.pack(side="left", ipadx=10)

        # Stats row
        stats = tk.Frame(parent, bg=t["bg"])
        stats.theme_role = "bg"
        stats.pack(fill="x", padx=14, pady=8)
        self._stat_count = self._stat_card(stats, "SCANS TODAY", "0")
        self._stat_ip    = self._stat_card(stats, "LOCAL IP",    self._local_ip())
        self._stat_port  = self._stat_card(stats, "PORT",        str(cfg["port"]))

        # Last scan
        lcard = tk.Frame(parent, bg=t["card"], bd=0, highlightthickness=1, highlightbackground=t["border"], pady=10, padx=16)
        lcard.theme_role = "card"
        lcard.pack(fill="x", padx=14, pady=(0, 10))
        
        lbl_last = tk.Label(lcard, text="LAST SCAN", bg=t["card"], fg=t["dim"],
                            font=("Segoe UI", 8, "bold"))
        lbl_last.theme_role = "dim"
        lbl_last.is_in_card = True
        lbl_last.pack(anchor="w")
        
        self._last_var = tk.StringVar(value="—")
        lbl_last_val = tk.Label(lcard, textvariable=self._last_var,
                                bg=t["card"], fg=t["acc"],
                                font=("Segoe UI", 14, "bold"))
        lbl_last_val.theme_role = "acc_bold"
        lbl_last_val.is_in_card = True
        lbl_last_val.pack(anchor="w", pady=(4, 0))
        
        self._last_ts = tk.StringVar(value="")
        lbl_last_ts_val = tk.Label(lcard, textvariable=self._last_ts,
                                   bg=t["card"], fg=t["dim"],
                                   font=("Segoe UI", 8))
        lbl_last_ts_val.theme_role = "dim"
        lbl_last_ts_val.is_in_card = True
        lbl_last_ts_val.pack(anchor="w")

    def _stat_card(self, parent, label, value):
        t  = self.t
        fr = tk.Frame(parent, bg=t["card"], highlightthickness=1, highlightbackground=t["border"], bd=0, pady=10, padx=12)
        fr.theme_role = "card"
        fr.pack(side="left", fill="x", expand=True, padx=4)
        
        lbl = tk.Label(fr, text=label, bg=t["card"], fg=t["dim"],
                       font=("Segoe UI", 8, "bold"))
        lbl.theme_role = "dim"
        lbl.is_in_card = True
        lbl.pack(anchor="w")
        
        var = tk.StringVar(value=value)
        val_lbl = tk.Label(fr, textvariable=var, bg=t["card"], fg=t["acc"],
                           font=("Segoe UI", 16, "bold"))
        val_lbl.theme_role = "acc_bold"
        val_lbl.is_in_card = True
        val_lbl.pack(anchor="w")
        return var

    # ── Server settings tab ───────────────────────────────────────────────────
    def _build_server(self, parent):
        t = self.t
        pad = {"padx": 18, "pady": 6}

        lbl_title = tk.Label(parent, text="HTTP Listener Configuration",
                             bg=t["bg"], fg=t["acc"],
                             font=("Segoe UI", 12, "bold"))
        lbl_title.theme_role = "header"
        lbl_title.pack(anchor="w", **pad)

        row = tk.Frame(parent, bg=t["bg"])
        row.theme_role = "bg"
        row.pack(fill="x", **pad)
        
        lbl_port = tk.Label(row, text="Listen Port:", bg=t["bg"], fg=t["fg"],
                            font=("Segoe UI", 10), width=16, anchor="w")
        lbl_port.theme_role = "label_normal"
        lbl_port.pack(side="left")
        
        self._port_var = tk.StringVar(value=str(cfg["port"]))
        ttk.Entry(row, textvariable=self._port_var, width=8).pack(side="left", padx=6)
        
        lbl_port_def = tk.Label(row, text="(default 8080)", bg=t["bg"], fg=t["dim"],
                                font=("Segoe UI", 9))
        lbl_port_def.theme_role = "dim"
        lbl_port_def.pack(side="left")

        # Checkboxes
        self._chk_notify = self._checkbox(parent, "Show desktop notifications",
                                           "show_notify", pad)
        self._chk_log    = self._checkbox(parent, "Log scans to file  (~/.linkscanpc/scans.log)",
                                           "log_scans", pad)
        self._chk_auto   = self._checkbox(parent, "Auto-start server on launch",
                                           "auto_start", pad)

        # Theme toggle
        row2 = tk.Frame(parent, bg=t["bg"])
        row2.theme_role = "bg"
        row2.pack(fill="x", **pad)
        
        lbl_theme = tk.Label(row2, text="Theme:", bg=t["bg"], fg=t["fg"],
                             font=("Segoe UI", 10), width=16, anchor="w")
        lbl_theme.theme_role = "label_normal"
        lbl_theme.pack(side="left")
        
        self._theme_var = tk.StringVar(value=cfg.get("theme", "dark"))
        for v, lbl in [("dark", "Dark"), ("light", "Light")]:
            rb = tk.Radiobutton(row2, text=lbl, variable=self._theme_var, value=v,
                                bg=t["bg"], fg=t["fg"], selectcolor=t["card"],
                                activebackground=t["bg"], font=("Segoe UI", 10))
            rb.theme_role = "radiobutton"
            rb.pack(side="left", padx=8)

        # Divider
        div = tk.Frame(parent, bg=t["border"], height=1)
        div.theme_role = "border"
        div.pack(fill="x", padx=18, pady=10)

        # Endpoint info
        lbl_api = tk.Label(parent, text="API Endpoints", bg=t["bg"], fg=t["acc"],
                           font=("Segoe UI", 11, "bold"))
        lbl_api.theme_role = "header"
        lbl_api.pack(anchor="w", padx=18)
        
        ep_frame = tk.Frame(parent, bg=t["card"], bd=0, highlightthickness=1, highlightbackground=t["border"], pady=10, padx=14)
        ep_frame.theme_role = "card"
        ep_frame.pack(fill="x", padx=18, pady=6)
        
        for method, path, desc in [
            ("POST", "/scan",  "Receive barcode from Android app"),
            ("GET",  "/ping",  "Health-check — returns {status:ok}"),
        ]:
            r = tk.Frame(ep_frame, bg=t["card"])
            r.theme_role = "card"
            r.pack(fill="x", pady=2)
            
            lbl_method = tk.Label(r, text=method, bg=t["card"],
                                  fg=t["acc"] if method == "POST" else t["yellow"],
                                  font=("Segoe UI", 9, "bold"), width=5)
            lbl_method.theme_role = "ep_method"
            lbl_method.method_type = method
            lbl_method.pack(side="left")
            
            lbl_path = tk.Label(r, text=path, bg=t["card"], fg=t["fg"],
                                font=("Segoe UI", 10), width=10, anchor="w")
            lbl_path.theme_role = "text"
            lbl_path.is_in_card = True
            lbl_path.pack(side="left")
            
            lbl_desc = tk.Label(r, text=desc, bg=t["card"], fg=t["dim"],
                                font=("Segoe UI", 9))
            lbl_desc.theme_role = "dim"
            lbl_desc.is_in_card = True
            lbl_desc.pack(side="left", padx=6)

    # ── Keyboard Wedge tab ────────────────────────────────────────────────────
    def _build_keyboard(self, parent):
        t   = self.t
        pad = {"padx": 18, "pady": 6}

        lbl_title = tk.Label(parent, text="Keystroke Wedge Settings",
                             bg=t["bg"], fg=t["acc"],
                             font=("Segoe UI", 12, "bold"))
        lbl_title.theme_role = "header"
        lbl_title.pack(anchor="w", **pad)

        if not HAS_KEYBOARD:
            lbl_warn = tk.Label(parent,
                                text="⚠  pynput unavailable — install it for keystroke support.",
                                bg=t["bg"], fg=t["yellow"],
                                font=("Segoe UI", 10))
            lbl_warn.theme_role = "warning"
            lbl_warn.pack(**pad)

        # Prefix
        row = tk.Frame(parent, bg=t["bg"])
        row.theme_role = "bg"
        row.pack(fill="x", **pad)
        
        lbl_prefix = tk.Label(row, text="Prefix string:", bg=t["bg"], fg=t["fg"],
                              font=("Segoe UI", 10), width=18, anchor="w")
        lbl_prefix.theme_role = "label_normal"
        lbl_prefix.pack(side="left")
        
        self._prefix_var = tk.StringVar(value=cfg.get("prefix", ""))
        ttk.Entry(row, textvariable=self._prefix_var, width=20).pack(side="left")
        
        lbl_prefix_desc = tk.Label(row, text="typed before each barcode", bg=t["bg"], fg=t["dim"],
                                   font=("Segoe UI", 9))
        lbl_prefix_desc.theme_role = "dim"
        lbl_prefix_desc.pack(side="left", padx=6)

        # Suffix
        row2 = tk.Frame(parent, bg=t["bg"])
        row2.theme_role = "bg"
        row2.pack(fill="x", **pad)
        
        lbl_suffix = tk.Label(row2, text="Send after scan:", bg=t["bg"], fg=t["fg"],
                              font=("Segoe UI", 10), width=18, anchor="w")
        lbl_suffix.theme_role = "label_normal"
        lbl_suffix.pack(side="left")
        
        self._suffix_var = tk.StringVar(value=cfg.get("suffix", "enter"))
        sfx_cb = ttk.Combobox(row2, textvariable=self._suffix_var, width=12,
                               values=["enter", "tab", "custom", "none"], state="readonly")
        sfx_cb.pack(side="left")
        sfx_cb.bind("<<ComboboxSelected>>", self._on_suffix_change)

        row3 = tk.Frame(parent, bg=t["bg"])
        row3.theme_role = "bg"
        row3.pack(fill="x", **pad)
        
        lbl_cust_sfx = tk.Label(row3, text="Custom suffix:", bg=t["bg"], fg=t["fg"],
                                font=("Segoe UI", 10), width=18, anchor="w")
        lbl_cust_sfx.theme_role = "label_normal"
        lbl_cust_sfx.pack(side="left")
        
        self._custom_sfx_var = tk.StringVar(value=cfg.get("custom_suffix", ""))
        self._custom_sfx_entry = ttk.Entry(row3, textvariable=self._custom_sfx_var, width=20)
        self._custom_sfx_entry.pack(side="left")
        self._on_suffix_change()

        # Divider
        div = tk.Frame(parent, bg=t["border"], height=1)
        div.theme_role = "border"
        div.pack(fill="x", padx=18, pady=12)

        # Flow diagram
        lbl_flow = tk.Label(parent, text="Data Flow", bg=t["bg"], fg=t["acc"],
                            font=("Segoe UI", 11, "bold"))
        lbl_flow.theme_role = "header"
        lbl_flow.pack(anchor="w", padx=18)
        
        lbl_flow_desc = tk.Label(parent,
                                 text="  Android App  →  WiFi  →  HTTP :8080/scan  →  Keystroke Wedge  →  Active Window",
                                 bg=t["bg"], fg=t["dim"],
                                 font=("Segoe UI", 9))
        lbl_flow_desc.theme_role = "dim"
        lbl_flow_desc.pack(anchor="w", padx=18, pady=4)

    def _on_suffix_change(self, *_):
        is_custom = self._suffix_var.get() == "custom"
        state = "normal" if is_custom else "disabled"
        self._custom_sfx_entry.configure(state=state)

    # ── Scan Log tab ──────────────────────────────────────────────────────────
    def _build_log(self, parent):
        t = self.t
        toolbar = tk.Frame(parent, bg=t["bg"])
        toolbar.theme_role = "bg"
        toolbar.pack(fill="x", padx=14, pady=8)
        
        lbl_recent = tk.Label(toolbar, text="Recent Scans", bg=t["bg"], fg=t["acc"],
                              font=("Segoe UI", 12, "bold"))
        lbl_recent.theme_role = "header"
        lbl_recent.pack(side="left")
        
        ttk.Button(toolbar, text="Clear", command=self._clear_log).pack(side="right", padx=2)
        ttk.Button(toolbar, text="Export", command=self._export_log).pack(side="right", padx=2)

        cols = ("time", "format", "barcode")
        self._tree = ttk.Treeview(parent, columns=cols, show="headings", height=18)
        self._tree.heading("time",    text="Timestamp")
        self._tree.heading("format",  text="Format")
        self._tree.heading("barcode", text="Barcode")
        self._tree.column("time",    width=160, minwidth=120)
        self._tree.column("format",  width=100, minwidth=70)
        self._tree.column("barcode", width=380, minwidth=200)

        sb = ttk.Scrollbar(parent, orient="vertical", command=self._tree.yview)
        self._tree.configure(yscrollcommand=sb.set)
        self._tree.pack(side="left", fill="both", expand=True, padx=(14, 0), pady=(0, 10))
        sb.pack(side="left", fill="y", pady=(0, 10))

        self._tree.bind("<Double-1>", self._copy_row)

    def _checkbox(self, parent, text, key, pad):
        var = tk.BooleanVar(value=cfg.get(key, False))
        ttk.Checkbutton(parent, text=text, variable=var).pack(anchor="w", **pad)
        return var

    # ── Actions ───────────────────────────────────────────────────────────────
    def _save(self):
        cfg["port"]          = int(self._port_var.get() or 8080)
        cfg["suffix"]        = self._suffix_var.get()
        cfg["prefix"]        = self._prefix_var.get()
        cfg["custom_suffix"] = self._custom_sfx_var.get()
        cfg["show_notify"]   = self._chk_notify.get()
        cfg["log_scans"]     = self._chk_log.get()
        cfg["auto_start"]    = self._chk_auto.get()
        cfg["theme"]         = self._theme_var.get()
        save_settings(cfg)
        self._port_label.configure(text=f"Port: {cfg['port']}")
        self._stat_port.set(str(cfg["port"]))
        
        # Apply the theme styling changes dynamically
        self._apply_theme()
        
        # Refresh root window background color
        t = self.t
        self.root.configure(bg=t["bg"])
        
        # Refresh system tray icon to match new light/dark theme colors
        if tray_icon:
            try:
                tray_icon.icon = make_tray_image(active=server_running)
            except Exception:
                pass
                
        messagebox.showinfo("Saved", "Settings saved.\nRestart the server for port changes to take effect.")

    def _clear_log(self):
        if messagebox.askyesno("Clear Log", "Delete all scan history from this session?"):
            scan_history.clear()
            for row in self._tree.get_children():
                self._tree.delete(row)

    def _export_log(self):
        import tkinter.filedialog as fd
        path = fd.asksaveasfilename(defaultextension=".tsv",
                                    filetypes=[("TSV", "*.tsv"), ("All", "*")])
        if path:
            with open(path, "w") as f:
                f.write("Timestamp\tFormat\tBarcode\n")
                for e in scan_history:
                    f.write(f"{e['time']}\t{e['format']}\t{e['barcode']}\n")
            messagebox.showinfo("Exported", f"Saved {len(scan_history)} records to:\n{path}")

    def _copy_row(self, event):
        sel = self._tree.selection()
        if sel:
            vals = self._tree.item(sel[0], "values")
            self.root.clipboard_clear()
            self.root.clipboard_append(vals[2] if vals else "")

    def _hide(self):
        self.root.withdraw()

    def show(self):
        self.root.deiconify()
        self.root.focus_force()

    # ── Queue polling (thread-safe GUI updates) ────────────────────────────────
    def _poll_queue(self):
        try:
            while True:
                msg = ui_queue.get_nowait()
                kind = msg[0]
                if kind == "scan":
                    entry = msg[1]
                    self._last_var.set(entry["barcode"])
                    self._last_ts.set(entry["time"])
                    self._stat_count.set(str(scan_count))
                    self._tree.insert("", 0,
                                      values=(entry["time"], entry["format"], entry["barcode"]))
                    # Keep log at 500 rows
                    children = self._tree.get_children()
                    if len(children) > 500:
                        self._tree.delete(children[-1])
                    if tray_icon:
                        try:
                            tray_icon.title = f"Last: {entry['barcode'][:30]}"
                        except Exception:
                            pass
                elif kind == "status":
                    running = msg[1]
                    if running:
                        self._status_pill.configure(text="  ● ONLINE  ",  bg=self.t["acc"],
                                                    fg=self.t["on_acc"])
                        self._status_var.set(f"Listening on port {cfg['port']}")
                        self._toggle_btn.configure(text="■  Stop Server",  style="Stop.TButton")
                    else:
                        self._status_pill.configure(text="  ● OFFLINE  ", bg=self.t["red"],
                                                    fg=self.t["on_red"])
                        self._status_var.set("Server is not running")
                        self._toggle_btn.configure(text="▶  Start Server", style="TButton")
                    if tray_icon:
                        try:
                            tray_icon.icon = make_tray_image(active=running)
                        except Exception:
                            pass
                elif kind == "error":
                    messagebox.showerror("Server Error", msg[1])
        except queue.Empty:
            pass
        self.root.after(120, self._poll_queue)

    @staticmethod
    def _local_ip() -> str:
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            ip = s.getsockname()[0]
            s.close()
            return ip
        except Exception:
            return "127.0.0.1"

    def run(self):
        self.root.mainloop()


# ── System tray ───────────────────────────────────────────────────────────────
def open_settings(_=None):
    if settings_win:
        settings_win.root.after(0, settings_win.show)


def quit_app(_=None):
    if server_running:
        stop_server()
    if tray_icon:
        tray_icon.stop()
    if settings_win:
        settings_win.root.after(0, settings_win.root.destroy)


def build_tray():
    global tray_icon
    img = make_tray_image(active=cfg.get("auto_start", False))
    menu = pystray.Menu(
        item("Open Dashboard",  open_settings, default=True),
        item("─────────────",   lambda: None, enabled=False),
        item("Start Server",    lambda: toggle_server() if not server_running else None),
        item("Stop Server",     lambda: toggle_server() if server_running  else None),
        item("─────────────",   lambda: None, enabled=False),
        item("Quit",            quit_app),
    )
    tray_icon = pystray.Icon(
        "linkscanpc",
        icon=img,
        title="LinkScanPC",
        menu=menu,
    )
    return tray_icon


# ── Entry point ───────────────────────────────────────────────────────────────
def main():
    global settings_win

    settings_win = SettingsWindow()

    # Build and run tray in background thread
    tray = build_tray()
    t = threading.Thread(target=tray.run, daemon=True)
    t.start()

    # Auto-start server if configured
    if cfg.get("auto_start"):
        srv_t = threading.Thread(target=start_server, daemon=True)
        srv_t.start()

    # Run GUI (blocking)
    settings_win.run()


if __name__ == "__main__":
    main()
