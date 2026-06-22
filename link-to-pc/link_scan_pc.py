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
APP_DIR = Path.home() / ".linkscanpc"
APP_DIR.mkdir(exist_ok=True)

OLD_CFG = OLD_APP_DIR / "settings.json"
CFG_FILE = APP_DIR / "settings.json"
if OLD_CFG.exists() and not CFG_FILE.exists():
    try:
        CFG_FILE.write_text(OLD_CFG.read_text())
    except Exception:
        pass

LOG_FILE = APP_DIR / "scans.log"

logging.basicConfig(
    filename=str(APP_DIR / "app.log"),
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
)

DEFAULT_SETTINGS = {
    "port": 8080,
    "suffix": "enter",
    "prefix": "",
    "custom_suffix": "",
    "beep": True,
    "show_notify": True,
    "log_scans": True,
    "auto_start": True,
    "theme": "light",
}


def load_settings() -> dict:
    if CFG_FILE.exists():
        try:
            saved = json.loads(CFG_FILE.read_text())
            return {**DEFAULT_SETTINGS, **saved}
        except Exception:
            pass
    return dict(DEFAULT_SETTINGS)


def save_settings(c: dict):
    CFG_FILE.write_text(json.dumps(c, indent=2))


# ── shared state ──────────────────────────────────────────────────────────────
cfg = load_settings()
server_thread = None
http_server = None
server_running = False
scan_count = 0
last_scan = ""
last_scan_ts = ""
scan_history = []
ui_queue = queue.Queue()
settings_win = None
tray_icon = None


# ── tray icon ─────────────────────────────────────────────────────────────────
def make_tray_image(active: bool = True) -> Image.Image:
    size = 64
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    is_dark = cfg.get("theme", "dark") == "dark"
    bg = (26, 31, 38, 255) if is_dark else (240, 244, 248, 255)
    if active:
        fg = (158, 202, 255, 255) if is_dark else (0, 97, 164, 255)
    else:
        fg = (142, 144, 153, 255) if is_dark else (83, 95, 112, 255)
    d.rounded_rectangle([0, 0, size - 1, size - 1], radius=12, fill=bg)
    bars = [8, 12, 16, 20, 26, 30, 36, 40, 46, 50, 54]
    for i, x in enumerate(bars):
        w = 2 if i % 2 == 0 else 3
        d.rectangle([x, 12, x + w, 40], fill=fg)
    d.arc([16, 42, 48, 56], start=200, end=340, fill=fg, width=3)
    d.ellipse([30, 50, 34, 54], fill=fg)
    return img


# ── HTTP server ───────────────────────────────────────────────────────────────
class ScanHandler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        pass

    def _json(self, code, body):
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
            length = int(self.headers.get("Content-Length", 0))
            payload = json.loads(self.rfile.read(length))
            barcode = str(payload.get("barcode", "")).strip()
            fmt = str(payload.get("format", "UNKNOWN"))
            ts = payload.get("timestamp", int(time.time() * 1000))
            if not barcode:
                self._json(400, {"error": "empty barcode"})
                return
            handle_scan(barcode, fmt, ts)
            self._json(200, {"status": "received"})
        except Exception as exc:
            logging.exception("POST /scan error")
            self._json(500, {"error": str(exc)})


def handle_scan(barcode, fmt, ts):
    global scan_count, last_scan, last_scan_ts
    scan_count += 1
    dt = datetime.datetime.fromtimestamp(ts / 1000).strftime("%Y-%m-%d %H:%M:%S")
    last_scan = barcode
    last_scan_ts = dt
    entry = {"barcode": barcode, "format": fmt, "time": dt}
    scan_history.insert(0, entry)
    if len(scan_history) > 500:
        scan_history.pop()
    logging.info("SCAN  %s  [%s]", barcode, fmt)
    if cfg.get("log_scans"):
        with open(LOG_FILE, "a") as f:
            f.write(f"{dt}\t{fmt}\t{barcode}\n")
    if HAS_KEYBOARD:
        try:
            full = cfg.get("prefix", "") + barcode
            suffix_opt = cfg.get("suffix", "enter")
            keyboard.type(full)
            if suffix_opt == "enter":
                keyboard.press(Key.enter)
                keyboard.release(Key.enter)
            elif suffix_opt == "tab":
                keyboard.press(Key.tab)
                keyboard.release(Key.tab)
            elif suffix_opt == "custom":
                cs = cfg.get("custom_suffix", "")
                if cs:
                    keyboard.type(cs)
        except Exception as exc:
            logging.warning("Keyboard error: %s", exc)
    if cfg.get("show_notify") and tray_icon:
        try:
            tray_icon.notify(f"Scanned: {barcode}", title="LinkScanPC")
        except Exception as exc:
            logging.warning("Notification error: %s", exc)
    ui_queue.put(("scan", entry))


def start_server():
    global http_server, server_running
    port = int(cfg.get("port", 8080))
    try:
        http_server = HTTPServer(("0.0.0.0", port), ScanHandler)
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


# ══════════════════════════════════════════════════════════════════════════════
#  REDESIGNED SETTINGS WINDOW
# ══════════════════════════════════════════════════════════════════════════════

# ── Palette ───────────────────────────────────────────────────────────────────
DARK = {
    "bg": "#0E1014",  # deepest background
    "bg2": "#141519",  # sidebar
    "bg3": "#1A1D23",  # card surface
    "bg4": "#20242C",  # inset / entry fields
    "border": "#2A2F3A",  # subtle dividers
    "border2": "#363C49",  # hover borders
    "fg": "#E4E6ED",  # primary text
    "fg2": "#9299A8",  # secondary text
    "fg3": "#5C6270",  # tertiary / placeholder
    "acc": "#4A90D9",  # blue accent
    "acc_dim": "#1E3A5A",  # accent bg tint
    "acc_hover": "#5BA3F0",  # accent hover
    "on_acc": "#EAF4FF",  # text on accent
    "green": "#3DBD7D",  # success
    "green_dim": "#122D1F",
    "red": "#E05C5C",  # danger
    "red_dim": "#2E1212",
    "amber": "#D4932A",  # warning
    "amber_dim": "#2D1E08",
    "sel": "#253040",  # treeview selection
}

LIGHT = {
    "bg": "#F5F6F8",
    "bg2": "#ECEEF2",
    "bg3": "#FFFFFF",
    "bg4": "#F0F2F5",
    "border": "#D8DCE6",
    "border2": "#B8BED0",
    "fg": "#1A1D24",
    "fg2": "#4A5068",
    "fg3": "#8890A4",
    "acc": "#2B72CC",
    "acc_dim": "#E0ECFB",
    "acc_hover": "#1A5CB0",
    "on_acc": "#FFFFFF",
    "green": "#1B8C54",
    "green_dim": "#E3F7EE",
    "red": "#CC3333",
    "red_dim": "#FDEAEA",
    "amber": "#B87718",
    "amber_dim": "#FDF3E0",
    "sel": "#C8DDF5",
}

FONT_MONO = ("JetBrains Mono", "Consolas", "Courier New")
FONT_UI = ("Segoe UI", "SF Pro Text", "Helvetica Neue", "TkDefaultFont")


def _mono(size=10, weight="normal"):
    for f in FONT_MONO:
        try:
            return (f, size, weight)
        except Exception:
            continue
    return ("Courier New", size, weight)


def _ui(size=10, weight="normal"):
    return (FONT_UI[0], size, weight)


def T():
    return DARK if cfg.get("theme", "dark") == "dark" else LIGHT


# ── Nav pages ─────────────────────────────────────────────────────────────────
PAGES = [
    ("dashboard", "Dashboard", "⬡"),
    ("log", "Scan Log", "≡"),
    ("server", "Server", "⊕"),
    ("keyboard", "Keyboard", "⌨"),
]


class SettingsWindow:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title("LinkScanPC")
        self.root.geometry("820x580")
        self.root.minsize(720, 500)
        self.root.resizable(True, True)

        self._current_page = "dashboard"
        self._nav_btns = {}
        self._page_frames = {}
        self._server_start_time = None
        self._uptime_job = None

        self._build()
        self._apply_theme()
        self._poll_queue()
        self.root.protocol("WM_DELETE_WINDOW", self._hide)
        self.root.withdraw()

    # ── Top-level layout ──────────────────────────────────────────────────────
    def _build(self):
        t = T()
        r = self.root
        r.configure(bg=t["bg"])

        # outer frame splits sidebar | main
        self._outer = tk.Frame(r, bg=t["bg"])
        self._outer.pack(fill="both", expand=True)

        self._sidebar = tk.Frame(self._outer, bg=t["bg2"], width=168)
        self._sidebar.pack(side="left", fill="y")
        self._sidebar.pack_propagate(False)

        self._right = tk.Frame(self._outer, bg=t["bg"])
        self._right.pack(side="left", fill="both", expand=True)

        self._topbar = tk.Frame(self._right, bg=t["bg3"], height=44)
        self._topbar.pack(side="top", fill="x")
        self._topbar.pack_propagate(False)

        self._content = tk.Frame(self._right, bg=t["bg"])
        self._content.pack(fill="both", expand=True)

        self._build_sidebar()
        self._build_topbar()
        self._build_dashboard()
        self._build_log()
        self._build_server()
        self._build_keyboard()

        self._show_page("dashboard")

    # ── Sidebar ───────────────────────────────────────────────────────────────
    def _build_sidebar(self):
        t = T()
        sb = self._sidebar

        # Logo
        logo_frame = tk.Frame(sb, bg=t["bg2"], pady=14)
        logo_frame.pack(fill="x")
        logo_icon = tk.Label(
            logo_frame,
            text="⬡",
            bg=t["acc_dim"],
            fg=t["acc"],
            font=_ui(14, "bold"),
            width=3,
            pady=4,
        )
        logo_icon.pack(side="left", padx=(12, 6))
        logo_text = tk.Label(
            logo_frame, text="LinkScanPC", bg=t["bg2"], fg=t["fg"], font=_ui(11, "bold")
        )
        logo_text.pack(side="left")

        # Divider
        tk.Frame(sb, bg=t["border"], height=1).pack(fill="x")

        # Nav
        nav_frame = tk.Frame(sb, bg=t["bg2"], pady=6)
        nav_frame.pack(fill="x")

        for page_id, label, icon in PAGES:
            btn = tk.Label(
                nav_frame,
                text=f"  {icon}  {label}",
                bg=t["bg2"],
                fg=t["fg2"],
                font=_ui(10),
                anchor="w",
                cursor="hand2",
                pady=9,
                padx=8,
            )
            btn.pack(fill="x")
            btn.bind("<Button-1>", lambda e, p=page_id: self._show_page(p))
            btn.bind("<Enter>", lambda e, b=btn, p=page_id: self._nav_hover(b, p, True))
            btn.bind(
                "<Leave>", lambda e, b=btn, p=page_id: self._nav_hover(b, p, False)
            )
            self._nav_btns[page_id] = btn

        # Divider
        tk.Frame(sb, bg=t["border"], height=1).pack(fill="x")

        # Server status badge
        self._sb_status_frame = tk.Frame(sb, bg=t["bg2"], pady=10, padx=10)
        self._sb_status_frame.pack(fill="x")

        self._sb_status = tk.Label(
            self._sb_status_frame,
            text="● OFFLINE",
            bg=t["red_dim"],
            fg=t["red"],
            font=_ui(9, "bold"),
            pady=5,
            padx=10,
            relief="flat",
        )
        self._sb_status.pack(fill="x")

        # Toggle button
        btn_frame = tk.Frame(sb, bg=t["bg2"], padx=10, pady=4)
        btn_frame.pack(fill="x")
        self._toggle_btn = tk.Label(
            btn_frame,
            text="▶  Start Server",
            bg=t["acc_dim"],
            fg=t["acc"],
            font=_ui(9, "bold"),
            pady=6,
            cursor="hand2",
            relief="flat",
        )
        self._toggle_btn.pack(fill="x")
        self._toggle_btn.bind("<Button-1>", lambda e: toggle_server())
        self._toggle_btn.bind(
            "<Enter>",
            lambda e: self._toggle_btn.configure(bg=T()["acc"], fg=T()["on_acc"]),
        )
        self._toggle_btn.bind("<Leave>", lambda e: self._toggle_hover_reset())

        # IP at bottom
        tk.Frame(sb, bg=t["bg2"]).pack(fill="y", expand=True)
        self._ip_label = tk.Label(
            sb, text=self._local_ip(), bg=t["bg2"], fg=t["fg3"], font=_mono(8)
        )
        self._ip_label.pack(side="bottom", pady=8)

    def _nav_hover(self, btn, page_id, entering):
        t = T()
        if page_id == self._current_page:
            return
        btn.configure(
            bg=t["bg4"] if entering else t["bg2"], fg=t["fg"] if entering else t["fg2"]
        )

    def _toggle_hover_reset(self):
        t = T()
        if server_running:
            self._toggle_btn.configure(bg=t["red_dim"], fg=t["red"])
        else:
            self._toggle_btn.configure(bg=t["acc_dim"], fg=t["acc"])

    def _show_page(self, page_id):
        t = T()
        self._current_page = page_id
        for pid, frame in self._page_frames.items():
            frame.pack_forget()
        self._page_frames[page_id].pack(fill="both", expand=True, padx=18, pady=14)

        # update nav highlights
        for pid, btn in self._nav_btns.items():
            if pid == page_id:
                btn.configure(bg=t["acc_dim"], fg=t["acc"])
            else:
                btn.configure(bg=t["bg2"], fg=t["fg2"])

        # update topbar label
        label = next(l for p, l, _ in PAGES if p == page_id)
        self._topbar_label.configure(text=label)

    # ── Topbar ────────────────────────────────────────────────────────────────
    def _build_topbar(self):
        t = T()
        tb = self._topbar

        self._topbar_label = tk.Label(
            tb, text="Dashboard", bg=t["bg3"], fg=t["fg2"], font=_ui(9, "bold")
        )
        self._topbar_label.pack(side="left", padx=16)

        # right side: uptime + port chip
        right = tk.Frame(tb, bg=t["bg3"])
        right.pack(side="right", padx=14)

        self._uptime_label = tk.Label(
            right, text="", bg=t["bg3"], fg=t["fg3"], font=_mono(8)
        )
        self._uptime_label.pack(side="right", padx=(8, 0))

        port_chip = tk.Label(
            right,
            text=f":{cfg['port']}",
            bg=t["bg4"],
            fg=t["fg2"],
            font=_mono(9),
            padx=8,
            pady=2,
        )
        port_chip.pack(side="right")
        self._port_chip = port_chip

        # thin bottom border
        tk.Frame(self._right, bg=t["border"], height=1).place(x=0, y=43, relwidth=1)

    # ── Dashboard ─────────────────────────────────────────────────────────────
    def _build_dashboard(self):
        t = T()
        fr = tk.Frame(self._content, bg=t["bg"])
        self._page_frames["dashboard"] = fr

        # ── stat row ──
        stat_row = tk.Frame(fr, bg=t["bg"])
        stat_row.pack(fill="x", pady=(0, 12))

        self._stat_count = self._stat_card(stat_row, "SCANS TODAY", "0")
        self._stat_port = self._stat_card(stat_row, "PORT", str(cfg["port"]))
        self._stat_ip = self._stat_card(stat_row, "LOCAL IP", self._local_ip())

        # ── last scan card ──
        lcard = tk.Frame(
            fr,
            bg=t["bg3"],
            relief="flat",
            highlightthickness=1,
            highlightbackground=t["border"],
        )
        lcard.pack(fill="x", pady=(0, 12))

        lc_inner = tk.Frame(lcard, bg=t["bg3"], pady=10, padx=14)
        lc_inner.pack(fill="x")

        tk.Label(
            lc_inner, text="LAST SCAN", bg=t["bg3"], fg=t["fg3"], font=_ui(8, "bold")
        ).pack(anchor="w")

        self._last_var = tk.StringVar(value="—")
        tk.Label(
            lc_inner,
            textvariable=self._last_var,
            bg=t["bg3"],
            fg=t["acc"],
            font=_mono(15, "bold"),
        ).pack(anchor="w", pady=(4, 0))

        self._last_ts = tk.StringVar(value="")
        tk.Label(
            lc_inner,
            textvariable=self._last_ts,
            bg=t["bg3"],
            fg=t["fg3"],
            font=_mono(8),
        ).pack(anchor="w")

        # ── live feed ──
        feed_hdr = tk.Frame(fr, bg=t["bg"])
        feed_hdr.pack(fill="x", pady=(0, 6))
        tk.Label(
            feed_hdr, text="LIVE FEED", bg=t["bg"], fg=t["fg3"], font=_ui(8, "bold")
        ).pack(side="left")
        self._live_dot = tk.Label(
            feed_hdr, text="●", bg=t["bg"], fg=t["fg3"], font=_ui(8)
        )
        self._live_dot.pack(side="left", padx=4)

        feed_card = tk.Frame(
            fr,
            bg=t["bg3"],
            relief="flat",
            highlightthickness=1,
            highlightbackground=t["border"],
        )
        feed_card.pack(fill="both", expand=True)

        cols = ("time", "format", "barcode")
        self._feed_tree = ttk.Treeview(
            feed_card, columns=cols, show="headings", height=8
        )
        self._feed_tree.heading("time", text="Timestamp")
        self._feed_tree.heading("format", text="Format")
        self._feed_tree.heading("barcode", text="Barcode")
        self._feed_tree.column("time", width=155, minwidth=110)
        self._feed_tree.column("format", width=90, minwidth=60)
        self._feed_tree.column("barcode", width=340, minwidth=180)

        fsb = ttk.Scrollbar(feed_card, orient="vertical", command=self._feed_tree.yview)
        self._feed_tree.configure(yscrollcommand=fsb.set)
        self._feed_tree.pack(side="left", fill="both", expand=True)
        fsb.pack(side="left", fill="y")

    def _stat_card(self, parent, label, value):
        t = T()
        fr = tk.Frame(
            parent,
            bg=t["bg3"],
            relief="flat",
            highlightthickness=1,
            highlightbackground=t["border"],
            pady=10,
            padx=14,
        )
        fr.pack(side="left", fill="x", expand=True, padx=(0, 8))
        tk.Label(fr, text=label, bg=t["bg3"], fg=t["fg3"], font=_ui(8, "bold")).pack(
            anchor="w"
        )
        var = tk.StringVar(value=value)
        tk.Label(
            fr, textvariable=var, bg=t["bg3"], fg=t["fg"], font=_mono(18, "bold")
        ).pack(anchor="w", pady=(2, 0))
        return var

    # ── Scan Log ──────────────────────────────────────────────────────────────
    def _build_log(self):
        t = T()
        fr = tk.Frame(self._content, bg=t["bg"])
        self._page_frames["log"] = fr

        toolbar = tk.Frame(fr, bg=t["bg"])
        toolbar.pack(fill="x", pady=(0, 10))

        tk.Label(
            toolbar, text="SCAN HISTORY", bg=t["bg"], fg=t["fg3"], font=_ui(8, "bold")
        ).pack(side="left")

        self._log_count_var = tk.StringVar(value="0 records")
        tk.Label(
            toolbar,
            textvariable=self._log_count_var,
            bg=t["bg"],
            fg=t["acc"],
            font=_ui(8, "bold"),
        ).pack(side="left", padx=8)

        self._mk_btn(toolbar, "Export .tsv", self._export_log).pack(
            side="right", padx=(4, 0)
        )
        self._mk_btn(toolbar, "Clear", self._clear_log).pack(side="right", padx=(4, 0))

        log_card = tk.Frame(
            fr,
            bg=t["bg3"],
            relief="flat",
            highlightthickness=1,
            highlightbackground=t["border"],
        )
        log_card.pack(fill="both", expand=True)

        cols = ("time", "format", "barcode")
        self._log_tree = ttk.Treeview(log_card, columns=cols, show="headings")
        self._log_tree.heading("time", text="Timestamp")
        self._log_tree.heading("format", text="Format")
        self._log_tree.heading("barcode", text="Barcode")
        self._log_tree.column("time", width=160, minwidth=110)
        self._log_tree.column("format", width=95, minwidth=60)
        self._log_tree.column("barcode", width=380, minwidth=200)

        lsb = ttk.Scrollbar(log_card, orient="vertical", command=self._log_tree.yview)
        self._log_tree.configure(yscrollcommand=lsb.set)
        self._log_tree.pack(side="left", fill="both", expand=True)
        lsb.pack(side="left", fill="y")

        self._log_tree.bind("<Double-1>", self._copy_row)

    # ── Server settings ───────────────────────────────────────────────────────
    def _build_server(self):
        t = T()
        fr = tk.Frame(self._content, bg=t["bg"])
        self._page_frames["server"] = fr

        self._section_label(fr, "HTTP Listener")

        card = self._card(fr)

        # Port row
        r1 = tk.Frame(card, bg=t["bg3"])
        r1.pack(fill="x", pady=4)
        tk.Label(
            r1,
            text="Listen port",
            bg=t["bg3"],
            fg=t["fg2"],
            font=_ui(10),
            width=18,
            anchor="w",
        ).pack(side="left")
        self._port_var = tk.StringVar(value=str(cfg["port"]))
        e = tk.Entry(
            r1,
            textvariable=self._port_var,
            width=8,
            bg=t["bg4"],
            fg=t["fg"],
            insertbackground=t["acc"],
            relief="flat",
            font=_mono(10),
            highlightthickness=1,
            highlightbackground=t["border"],
        )
        e.pack(side="left", padx=(0, 10))
        tk.Label(r1, text="default 8080", bg=t["bg3"], fg=t["fg3"], font=_ui(9)).pack(
            side="left"
        )

        # Theme
        r2 = tk.Frame(card, bg=t["bg3"])
        r2.pack(fill="x", pady=4)
        tk.Label(
            r2,
            text="Theme",
            bg=t["bg3"],
            fg=t["fg2"],
            font=_ui(10),
            width=18,
            anchor="w",
        ).pack(side="left")
        self._theme_var = tk.StringVar(value=cfg.get("theme", "dark"))
        for v, lbl in [("dark", "Dark"), ("light", "Light")]:
            rb = tk.Radiobutton(
                r2,
                text=lbl,
                variable=self._theme_var,
                value=v,
                bg=t["bg3"],
                fg=t["fg"],
                selectcolor=t["bg4"],
                activebackground=t["bg3"],
                font=_ui(10),
            )
            rb.pack(side="left", padx=8)

        self._chk_notify = self._checkbox(
            card, "Show desktop notifications", "show_notify"
        )
        self._chk_log = self._checkbox(
            card, "Log scans to  ~/.linkscanpc/scans.log", "log_scans"
        )
        self._chk_auto = self._checkbox(
            card, "Auto-start server on launch", "auto_start"
        )

        # Divider
        tk.Frame(fr, bg=t["border"], height=1).pack(fill="x", pady=10)

        self._section_label(fr, "API Endpoints")
        ep_card = self._card(fr)

        for method, path, desc in [
            ("POST", "/scan", "Receive barcode scan from Android app"),
            ("GET", "/ping", "Health-check — returns {status: ok}"),
        ]:
            row = tk.Frame(ep_card, bg=t["bg3"])
            row.pack(fill="x", pady=3)
            method_color = t["acc"] if method == "POST" else t["green"]
            method_bg = t["acc_dim"] if method == "POST" else t["green_dim"]
            tk.Label(
                row,
                text=method,
                bg=method_bg,
                fg=method_color,
                font=_mono(9, "bold"),
                width=6,
                pady=2,
            ).pack(side="left", padx=(0, 10))
            tk.Label(
                row,
                text=path,
                bg=t["bg3"],
                fg=t["fg"],
                font=_mono(10, "bold"),
                width=10,
                anchor="w",
            ).pack(side="left")
            tk.Label(row, text=desc, bg=t["bg3"], fg=t["fg3"], font=_ui(9)).pack(
                side="left", padx=6
            )

        # Save button
        tk.Frame(fr, bg=t["bg"], height=12).pack()
        save_btn = tk.Label(
            fr,
            text="  Save Settings  ",
            bg=t["acc"],
            fg=t["on_acc"],
            font=_ui(10, "bold"),
            pady=8,
            cursor="hand2",
        )
        save_btn.pack(anchor="w")
        save_btn.bind("<Button-1>", lambda e: self._save())
        save_btn.bind("<Enter>", lambda e: save_btn.configure(bg=T()["acc_hover"]))
        save_btn.bind("<Leave>", lambda e: save_btn.configure(bg=T()["acc"]))

    # ── Keyboard ──────────────────────────────────────────────────────────────
    def _build_keyboard(self):
        t = T()
        fr = tk.Frame(self._content, bg=t["bg"])
        self._page_frames["keyboard"] = fr

        self._section_label(fr, "Keystroke Wedge")

        if not HAS_KEYBOARD:
            warn = tk.Label(
                fr,
                text="⚠  pynput not installed — keystroke output disabled.",
                bg=t["amber_dim"],
                fg=t["amber"],
                font=_ui(9),
                pady=6,
                padx=10,
                anchor="w",
            )
            warn.pack(fill="x", pady=(0, 8))

        card = self._card(fr)

        # Prefix
        r1 = tk.Frame(card, bg=t["bg3"])
        r1.pack(fill="x", pady=4)
        tk.Label(
            r1,
            text="Prefix string",
            bg=t["bg3"],
            fg=t["fg2"],
            font=_ui(10),
            width=18,
            anchor="w",
        ).pack(side="left")
        self._prefix_var = tk.StringVar(value=cfg.get("prefix", ""))
        tk.Entry(
            r1,
            textvariable=self._prefix_var,
            width=22,
            bg=t["bg4"],
            fg=t["fg"],
            insertbackground=t["acc"],
            relief="flat",
            font=_mono(10),
            highlightthickness=1,
            highlightbackground=t["border"],
        ).pack(side="left")
        tk.Label(
            r1, text="typed before each barcode", bg=t["bg3"], fg=t["fg3"], font=_ui(9)
        ).pack(side="left", padx=8)

        # Suffix
        r2 = tk.Frame(card, bg=t["bg3"])
        r2.pack(fill="x", pady=4)
        tk.Label(
            r2,
            text="Send after scan",
            bg=t["bg3"],
            fg=t["fg2"],
            font=_ui(10),
            width=18,
            anchor="w",
        ).pack(side="left")
        self._suffix_var = tk.StringVar(value=cfg.get("suffix", "enter"))
        sfx = ttk.Combobox(
            r2,
            textvariable=self._suffix_var,
            width=10,
            values=["enter", "tab", "custom", "none"],
            state="readonly",
            font=_mono(10),
        )
        sfx.pack(side="left")
        sfx.bind("<<ComboboxSelected>>", self._on_suffix_change)

        # Custom suffix
        r3 = tk.Frame(card, bg=t["bg3"])
        r3.pack(fill="x", pady=4)
        tk.Label(
            r3,
            text="Custom suffix",
            bg=t["bg3"],
            fg=t["fg2"],
            font=_ui(10),
            width=18,
            anchor="w",
        ).pack(side="left")
        self._custom_sfx_var = tk.StringVar(value=cfg.get("custom_suffix", ""))
        self._custom_sfx_entry = tk.Entry(
            r3,
            textvariable=self._custom_sfx_var,
            width=22,
            bg=t["bg4"],
            fg=t["fg"],
            insertbackground=t["acc"],
            relief="flat",
            font=_mono(10),
            highlightthickness=1,
            highlightbackground=t["border"],
        )
        self._custom_sfx_entry.pack(side="left")
        self._on_suffix_change()

        # Divider
        tk.Frame(fr, bg=t["border"], height=1).pack(fill="x", pady=12)

        self._section_label(fr, "Data Flow")
        flow_card = self._card(fr)
        flow_items = [
            ("Android app", t["bg4"], t["fg2"]),
            ("→", t["bg3"], t["fg3"]),
            ("WiFi", t["bg4"], t["fg2"]),
            ("→", t["bg3"], t["fg3"]),
            ("HTTP :8080", t["bg4"], t["fg2"]),
            ("→", t["bg3"], t["fg3"]),
            ("Wedge", t["acc_dim"], t["acc"]),
            ("→", t["bg3"], t["fg3"]),
            ("Active window", t["bg4"], t["fg2"]),
        ]
        flow_row = tk.Frame(flow_card, bg=t["bg3"])
        flow_row.pack(fill="x")
        for text, bg, fg in flow_items:
            tk.Label(
                flow_row, text=text, bg=bg, fg=fg, font=_mono(9), padx=6, pady=4
            ).pack(side="left", padx=1)

    # ── Helpers ───────────────────────────────────────────────────────────────
    def _section_label(self, parent, text):
        t = T()
        tk.Label(
            parent, text=text.upper(), bg=t["bg"], fg=t["fg3"], font=_ui(8, "bold")
        ).pack(anchor="w", pady=(0, 6))

    def _card(self, parent):
        t = T()
        outer = tk.Frame(
            parent, bg=t["bg3"], highlightthickness=1, highlightbackground=t["border"]
        )
        outer.pack(fill="x", pady=(0, 10))
        inner = tk.Frame(outer, bg=t["bg3"], padx=14, pady=10)
        inner.pack(fill="x")
        return inner

    def _checkbox(self, parent, text, key):
        t = T()
        var = tk.BooleanVar(value=cfg.get(key, False))
        cb = tk.Checkbutton(
            parent,
            text=text,
            variable=var,
            bg=t["bg3"],
            fg=t["fg"],
            selectcolor=t["bg4"],
            activebackground=t["bg3"],
            font=_ui(10),
        )
        cb.pack(anchor="w", pady=3)
        return var

    def _mk_btn(self, parent, label, cmd):
        t = T()
        btn = tk.Label(
            parent,
            text=f"  {label}  ",
            bg=t["bg4"],
            fg=t["fg2"],
            font=_ui(9),
            pady=4,
            cursor="hand2",
            relief="flat",
            highlightthickness=1,
            highlightbackground=t["border"],
        )
        btn.bind("<Button-1>", lambda e: cmd())
        btn.bind("<Enter>", lambda e: btn.configure(bg=T()["border2"]))
        btn.bind("<Leave>", lambda e: btn.configure(bg=T()["bg4"]))
        return btn

    # ── Theme application ─────────────────────────────────────────────────────
    def _apply_theme(self):
        t = T()
        style = ttk.Style(self.root)
        style.theme_use("clam")

        style.configure("TFrame", background=t["bg"])
        style.configure("TLabel", background=t["bg"], foreground=t["fg"], font=_ui(10))
        style.configure(
            "TButton",
            background=t["bg4"],
            foreground=t["fg"],
            font=_ui(10),
            relief="flat",
            borderwidth=0,
        )
        style.map("TButton", background=[("active", t["border2"])])
        style.configure(
            "TEntry",
            fieldbackground=t["bg4"],
            foreground=t["fg"],
            insertcolor=t["acc"],
            bordercolor=t["border"],
            font=_mono(10),
        )
        style.configure(
            "TCombobox",
            fieldbackground=t["bg4"],
            foreground=t["fg"],
            font=_mono(10),
            bordercolor=t["border"],
        )
        style.map(
            "TCombobox",
            fieldbackground=[("readonly", t["bg4"])],
            foreground=[("readonly", t["fg"])],
        )
        style.configure(
            "TCheckbutton", background=t["bg3"], foreground=t["fg"], font=_ui(10)
        )
        style.map(
            "TCheckbutton",
            background=[("active", t["bg3"])],
            foreground=[("active", t["fg"])],
        )
        style.configure("TNotebook", background=t["bg"], borderwidth=0)
        style.configure(
            "TNotebook.Tab",
            background=t["bg3"],
            foreground=t["fg2"],
            font=_ui(10),
            padding=[12, 6],
        )
        style.map(
            "TNotebook.Tab",
            background=[("selected", t["bg"])],
            foreground=[("selected", t["acc"])],
        )

        # Treeview
        style.configure(
            "Treeview",
            background=t["bg3"],
            foreground=t["fg"],
            fieldbackground=t["bg3"],
            rowheight=24,
            font=_mono(9),
        )
        style.configure(
            "Treeview.Heading",
            background=t["bg4"],
            foreground=t["fg3"],
            font=_ui(9, "bold"),
            relief="flat",
        )
        style.map(
            "Treeview",
            background=[("selected", t["sel"])],
            foreground=[("selected", t["fg"])],
        )
        style.configure(
            "Vertical.TScrollbar",
            background=t["bg4"],
            troughcolor=t["bg3"],
            bordercolor=t["border"],
            arrowcolor=t["fg3"],
        )

        self.root.option_add("*TCombobox*Listbox.background", t["bg4"])
        self.root.option_add("*TCombobox*Listbox.foreground", t["fg"])
        self.root.option_add("*TCombobox*Listbox.selectBackground", t["sel"])
        self.root.option_add("*TCombobox*Listbox.selectForeground", t["fg"])

    # ── Suffix change ─────────────────────────────────────────────────────────
    def _on_suffix_change(self, *_):
        is_custom = self._suffix_var.get() == "custom"
        self._custom_sfx_entry.configure(state="normal" if is_custom else "disabled")

    # ── Save ──────────────────────────────────────────────────────────────────
    def _save(self):
        try:
            port = int(self._port_var.get() or 8080)
        except ValueError:
            messagebox.showerror("Invalid port", "Port must be a number.")
            return

        cfg["port"] = port
        cfg["suffix"] = self._suffix_var.get()
        cfg["prefix"] = self._prefix_var.get()
        cfg["custom_suffix"] = self._custom_sfx_var.get()
        cfg["show_notify"] = self._chk_notify.get()
        cfg["log_scans"] = self._chk_log.get()
        cfg["auto_start"] = self._chk_auto.get()
        cfg["theme"] = self._theme_var.get()
        save_settings(cfg)

        self._stat_port.set(str(cfg["port"]))
        self._port_chip.configure(text=f":{cfg['port']}")
        self._apply_theme()

        if tray_icon:
            try:
                tray_icon.icon = make_tray_image(active=server_running)
            except Exception:
                pass

        messagebox.showinfo(
            "Saved",
            "Settings saved.\nRestart the server for port changes to take effect.",
        )

    # ── Log actions ───────────────────────────────────────────────────────────
    def _clear_log(self):
        if messagebox.askyesno(
            "Clear Log", "Delete all scan history from this session?"
        ):
            scan_history.clear()
            for tree in (self._log_tree, self._feed_tree):
                for row in tree.get_children():
                    tree.delete(row)
            self._log_count_var.set("0 records")

    def _export_log(self):
        import tkinter.filedialog as fd

        path = fd.asksaveasfilename(
            defaultextension=".tsv", filetypes=[("TSV", "*.tsv"), ("All", "*")]
        )
        if path:
            with open(path, "w") as f:
                f.write("Timestamp\tFormat\tBarcode\n")
                for e in scan_history:
                    f.write(f"{e['time']}\t{e['format']}\t{e['barcode']}\n")
            messagebox.showinfo(
                "Exported", f"Saved {len(scan_history)} records to:\n{path}"
            )

    def _copy_row(self, event):
        tree = event.widget
        sel = tree.selection()
        if sel:
            vals = tree.item(sel[0], "values")
            self.root.clipboard_clear()
            self.root.clipboard_append(vals[2] if vals else "")

    # ── Queue polling ─────────────────────────────────────────────────────────
    def _poll_queue(self):
        try:
            while True:
                msg = ui_queue.get_nowait()
                kind = msg[0]
                if kind == "scan":
                    entry = msg[1]
                    t = T()
                    # dashboard
                    self._last_var.set(entry["barcode"])
                    self._last_ts.set(entry["time"])
                    self._stat_count.set(str(scan_count))
                    self._live_dot.configure(fg=t["green"])
                    self._feed_tree.insert(
                        "", 0, values=(entry["time"], entry["format"], entry["barcode"])
                    )
                    kids = self._feed_tree.get_children()
                    if len(kids) > 50:
                        self._feed_tree.delete(kids[-1])
                    # log
                    self._log_tree.insert(
                        "", 0, values=(entry["time"], entry["format"], entry["barcode"])
                    )
                    kids2 = self._log_tree.get_children()
                    if len(kids2) > 500:
                        self._log_tree.delete(kids2[-1])
                    self._log_count_var.set(f"{len(scan_history)} records")
                    if tray_icon:
                        try:
                            tray_icon.title = f"Last: {entry['barcode'][:30]}"
                        except Exception:
                            pass

                elif kind == "status":
                    running = msg[1]
                    t = T()
                    if running:
                        self._sb_status.configure(
                            text="● ONLINE", bg=t["green_dim"], fg=t["green"]
                        )
                        self._toggle_btn.configure(
                            text="■  Stop Server", bg=t["red_dim"], fg=t["red"]
                        )
                        self._server_start_time = time.time()
                        self._tick_uptime()
                    else:
                        self._sb_status.configure(
                            text="● OFFLINE", bg=t["red_dim"], fg=t["red"]
                        )
                        self._toggle_btn.configure(
                            text="▶  Start Server", bg=t["acc_dim"], fg=t["acc"]
                        )
                        self._uptime_label.configure(text="")
                        self._server_start_time = None
                        if self._uptime_job:
                            self.root.after_cancel(self._uptime_job)
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

    def _tick_uptime(self):
        if self._server_start_time and server_running:
            elapsed = int(time.time() - self._server_start_time)
            m, s = divmod(elapsed, 60)
            h, m = divmod(m, 60)
            txt = f"{h}h {m:02d}m {s:02d}s" if h else f"{m}m {s:02d}s"
            self._uptime_label.configure(text=txt)
            self._uptime_job = self.root.after(1000, self._tick_uptime)

    # ── Visibility ────────────────────────────────────────────────────────────
    def _hide(self):
        self.root.withdraw()

    def show(self):
        self.root.deiconify()
        self.root.focus_force()

    @staticmethod
    def _local_ip():
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
        item("Open Dashboard", open_settings, default=True),
        item("─────────────", lambda: None, enabled=False),
        item("Start Server", lambda: toggle_server() if not server_running else None),
        item("Stop Server", lambda: toggle_server() if server_running else None),
        item("─────────────", lambda: None, enabled=False),
        item("Quit", quit_app),
    )
    tray_icon = pystray.Icon("linkscanpc", icon=img, title="LinkScanPC", menu=menu)
    return tray_icon


# ── Entry point ───────────────────────────────────────────────────────────────
def main():
    global settings_win

    settings_win = SettingsWindow()

    tray = build_tray()
    t = threading.Thread(target=tray.run, daemon=True)
    t.start()

    if cfg.get("auto_start"):
        srv_t = threading.Thread(target=start_server, daemon=True)
        srv_t.start()

    settings_win.run()


if __name__ == "__main__":
    main()
