# AGENTS.md — LinkScan Pro

## Project overview

Flutter app (SDK `^3.11.0`) that turns a phone into a wireless barcode scanner. Scanned codes are sent via HTTP to a companion PC server (`link-to-pc/link_scan_pc.py`) which types them at the cursor.

## Architecture

- **State management**: raw `ChangeNotifier` + `ListenableBuilder` — no Provider/Riverpod/Bloc. Single `BarcodeViewModel` passed via constructor.
- **Layering**: `lib/viewmodels/barcode_viewmodel.dart` ←→ `lib/widgets/`, `lib/network/`, `lib/database/`, `lib/models/`, `lib/theme/`
- **Entrypoint**: `lib/main.dart` — creates `BarcodeViewModel`, wraps `MyApp`
- **Routing**: no named routes — only `Navigator.push(MaterialPageRoute(...))` for settings screen
- **No code generation**, no localization

## Key packages

- `mobile_scanner` — camera-based barcode scanning
- `sqflite` + `path` — offline scan history
- `http` — send scans to companion PC at `POST http://<ip>:<port>/scan`
- `shared_preferences` — persist settings
- `wakelock_plus` — keep screen on during scans
- `google_fonts`, `flutter_svg` — UI polish
- Companion PC discovery: UDP broadcast on port 35912

## Companion server (`link-to-pc/`)

- Python HTTP server (`link_scan_pc.py`) that receives barcodes and types them via `pynput`
- Build standalone `.exe`: `cd link-to-pc && builder.bat` (uses PyInstaller)
- Dependencies: `pip install -r link-to-pc/requirements.txt`

## Testing

- Single smoke test at `test/widget_test.dart`
- **Must init sqflite FFI before test**: call `sqfliteFfiInit()` + `databaseFactory = databaseFactoryFfi` at top of `main()`
- Mock SharedPreferences via `SharedPreferences.setMockInitialValues({})`
- Run: `flutter test`
- Run single file: `flutter test test/widget_test.dart`
- No formatter/typecheck beyond `flutter analyze` and default `dart format`

## Common commands

| Action | Command |
|--------|---------|
| Analyze | `flutter analyze` |
| Format | `dart format .` |
| Test | `flutter test` |
| Run (desktop) | `flutter run -d windows` (or `linux`, `macos`) |
| Run (mobile) | `flutter run` (with device connected) |
| Build APK | `flutter build apk` |
| Launcher icons | `flutter pub run flutter_launcher_icons` |
| Native splash | `flutter pub run flutter_native_splash:create` |

## Gotchas

- Tests that touch the DB need `sqflite_common_ffi` and the two init lines above — easy to miss
- Virtual keyboard beep uses `MethodChannel('com.linkscan.org/beep')` — only works on real devices, not in tests
- `BarcodeViewModel` calls `SharedPreferences.getInstance()` on construction — test must mock prefs first
- Companion PC must be running on the same LAN; UDP discovery uses broadcast on port 35912
- HTTP requests to companion PC have a 2-second timeout
- `link-to-pc/dist/`, `link-to-pc/build/`, `link-to-pc/*.spec` are gitignored
