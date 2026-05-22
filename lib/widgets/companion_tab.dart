import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class CompanionTab extends StatelessWidget {
  const CompanionTab({super.key});

  static const String _pythonScript = '''# =========================================================================
#                 📱 LINKSCAN PRO WIFI RECEIVER SERVER 📱
# =========================================================================
# Runs a frictionless local HTTP server to receive scans wirelessly.
# Emulates a keyboard device to pipe barcode values directly to cursor focus.
#
# Prerequisite: pip install pyautogui (optional, for auto-typing integration)
# To run: python receiver.py
# =========================================================================

import http.server
import json
import socket
import sys

DISABLE_KEYBOARD_EMULATION = False
try:
    import pyautogui
    pyautogui.PAUSE = 0.01 
    print("[INFO] pyautogui detected! Barcodes will type into any open app.")
except ImportError:
    try:
        from pynput.keyboard import Controller
        keyboard = Controller()
        print("[INFO] pynput detected! Barcodes will type into any open app.")
        pyautogui = None
    except ImportError:
        DISABLE_KEYBOARD_EMULATION = True
        print("[WARN] pyautogui/pynput not found. Barcodes will only log to console.")
        print("       To enable auto-typing directly into Excel, Notebook, or sheets run:")
        print("       pip install pyautogui")

class BarcodeReceiverHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/ping':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(b'{"status": "ok"}')
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        if self.path == '/scan':
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            try:
                data = json.loads(post_data.decode('utf-8'))
                barcode = data.get('barcode', '')
                barcode_format = data.get('format', 'Barcode')
                print(f"[SCAN] Scanned: {barcode} | Type: {barcode_format}")
                
                # Send HTTP OK immediately to release mobile client thread
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(b'{"status": "received"}')
                
                # Emulate keystroke typing
                if not DISABLE_KEYBOARD_EMULATION:
                    if 'pyautogui' in sys.modules and pyautogui is not None:
                        pyautogui.write(barcode)
                        pyautogui.press('enter')
                    elif 'pynput' in sys.modules:
                        keyboard.type(barcode)
                        from pynput.keyboard import Key
                        keyboard.press(Key.enter)
                        keyboard.release(Key.enter)
            except Exception as e:
                print(f"[ERR] Failed to process scan: {e}")
                self.send_response(400)
                self.end_headers()
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        pass

def get_local_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(('8.8.8.8', 1))
        local_ip = s.getsockname()[0]
    except Exception:
        local_ip = '127.0.0.1'
    finally:
        s.close()
    return local_ip

def run_server(port=8080):
    local_ip = get_local_ip()
    httpd = http.server.HTTPServer(('', port), BarcodeReceiverHandler)
    print("=" * 66)
    print("  LinkScan Pro Companion server is live and listening on local network!")
    print("=" * 66)
    print(f"  PC Local IP Address to enter in phone:  \\033[92m{local_ip}\\033[0m")
    print(f"  Target Port Number:                    \\033[92m{port}\\033[0m")
    print(f"  Status Check URL:                       http://{local_ip}:{port}/ping")
    print("=" * 66)
    print("  Place cursor anywhere in Excel, Google Sheets, or Notepad to start typing...")
    print("  Exit server anytime by pressing Ctrl + C.")
    print("=" * 66)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\\nCompanion server shut down.")
        httpd.server_close()

if __name__ == '__main__':
    run_server(8080)''';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          'DESKTOP COMPANION SETUP',
          style: TextStyle(
            color: polishPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 14.0,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4.0),
        const Text(
          'Generate wireless keystrokes onto your PC instantly by following our 3-step guide.',
          style: TextStyle(
            color: polishOnSurfaceVariant,
            fontSize: 13.0,
          ),
        ),
        const SizedBox(height: 16.0),

        // Step 1: Copy script card
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
            side: BorderSide(color: polishOutline.withOpacity(0.4), width: 1.0),
          ),
          color: polishSurface,
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '1. Download and Copy Script',
                  style: TextStyle(fontWeight: FontWeight.bold, color: polishPrimary, fontSize: 15.0),
                ),
                const SizedBox(height: 6.0),
                const Text(
                  'Tap the copy button below to save the clean python companion receiver onto your clipboard.',
                  style: TextStyle(color: polishOnSurfaceVariant, fontSize: 12.0),
                ),
                const SizedBox(height: 16.0),
                SizedBox(
                  width: double.infinity,
                  height: 44.0,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: polishPrimary,
                      foregroundColor: polishOnPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _pythonScript));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Python Companion Script copied!')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 18.0),
                    label: const Text(
                      'Copy Desktop Python Script',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16.0),

        // Step 2: Create receiver card
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
            side: BorderSide(color: polishOutline.withOpacity(0.4), width: 1.0),
          ),
          color: polishSurface,
          elevation: 0,
          child: const Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '2. Create and run on PC',
                  style: TextStyle(fontWeight: FontWeight.bold, color: polishPrimary, fontSize: 15.0),
                ),
                SizedBox(height: 8.0),
                Text(
                  '• Save copied content into a file called receiver.py on your computer.\n'
                  '• (Optional) Install auto-typing library via terminal: pip install pyautogui pynput\n'
                  '• Start the server by running standard python: python receiver.py\n'
                  '• The script terminal will print your PC\'s IP address (e.g. 192.168.1.15).',
                  style: TextStyle(color: polishOnSurfaceVariant, fontSize: 12.0, height: 1.6),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16.0),

        // Step 3: Input settings card
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
            side: BorderSide(color: polishOutline.withOpacity(0.4), width: 1.0),
          ),
          color: polishSurface,
          elevation: 0,
          child: const Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '3. Input values in Settings',
                  style: TextStyle(fontWeight: FontWeight.bold, color: polishPrimary, fontSize: 15.0),
                ),
                SizedBox(height: 8.0),
                Text(
                  'Head to the Settings tab in this App. Enter your PC\'s IP address and Port (usually 8080). Make sure both your phone and PC are connected to the exact same Wi-Fi SSID network, and press Test Connection!',
                  style: TextStyle(color: polishOnSurfaceVariant, fontSize: 12.0, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
