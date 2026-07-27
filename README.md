# LinkScan Pro (v1.0.1)

LinkScan Pro turns your mobile device into a high-speed, wireless hardware barcode scanner. Using local network connectivity, it pipes barcode and QR code transmissions directly to your cursor focus on any PC or laptop running our friction-free companion server.

---

## Key Features

* **Frictionless Wireless Scan Syncing**
  Type codes directly into Excel, Google Sheets, databases, or Notepad over local Wi-Fi.
* **Natively Managed Desktop Companion**
  On Windows, download, run, stop, and monitor the companion process (**LinkScanPC**) directly inside the application's interactive terminal tab.
* **Live Camera Flash Support**
  Toggle the camera flash to read barcodes in low-light warehouse conditions.
* **Offline SQLite Scan Logs**
  Access scan history and sync statuses anywhere, even when disconnected.
* **Anti-Duplicate Cooldown Control**
  Customizable sliding window filters out accidental double scans seamlessly.

---

## LinkScanPC Companion Server

The desktop companion receiver runs a local HTTP server that emulates keyboard inputs to type barcode inputs at cursor focus.

### Natively on Windows
Within the **Companion** tab of the Windows app, you can:
1. Click **Download LinkScanPC.exe** to download the latest executable from GitHub releases.
2. Click **Start Companion** to run it.
3. View logs in real-time within the app's terminal emulator interface.
4. Stop or delete the executable easily.

### Python / Cross-Platform Fallback
For macOS, Linux, or custom setups:
1. Download the `link_scan_pc.py` script from the GitHub repository.
2. Install dependencies:
   ```bash
   pip install pyautogui pynput
   ```
3. Run the script:
   ```bash
   python link_scan_pc.py
   ```

### Settings & Configuration
By default, the server runs on port **8080**. All tray status, custom ports, and auto-typing settings are saved locally at:
* Windows: `%USERPROFILE%\.linkscanpc\settings.json`
* macOS/Linux: `~/.linkscanpc/settings.json`

---

## Open Source Repository

Access source code, documentation, submit bug reports, or contribute to the project on GitHub:
**[github.com/s4rrar/link-scan](https://github.com/s4rrar/link-scan)**

---
*Made by [@s4rrar](https://github.com/s4rrar) for faster workflows.*