import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scan_item.dart';
import '../database/db_helper.dart';
import '../network/api_client.dart';

class BarcodeViewModel extends ChangeNotifier {
  late SharedPreferences _prefs;
  final _apiClient = ApiClient();

  // Settings properties
  String _serverIp = '192.168.1.100';
  String get serverIp => _serverIp;

  int _serverPort = 8080;
  int get serverPort => _serverPort;

  double _scanDelayMs = 500.0;
  double get scanDelayMs => _scanDelayMs;

  bool _soundEnabled = true;
  bool get soundEnabled => _soundEnabled;

  bool _vibrationEnabled = true;
  bool get vibrationEnabled => _vibrationEnabled;

  // Real-time Scanning Cooldown States
  bool _isCoolingDown = false;
  bool get isCoolingDown => _isCoolingDown;

  double _cooldownProgress = 1.0;
  double get cooldownProgress => _cooldownProgress;

  // Scanning Status Feedback
  String? _lastScannedValue;
  String? get lastScannedValue => _lastScannedValue;

  String? _lastScannedFormat;
  String? get lastScannedFormat => _lastScannedFormat;

  // Test ping response messages
  String? _connectionStatusMessage;
  String? get connectionStatusMessage => _connectionStatusMessage;

  bool _isTestingConnection = false;
  bool get isTestingConnection => _isTestingConnection;

  // Scan history list
  List<ScanItem> _scanHistory = [];
  List<ScanItem> get scanHistory => _scanHistory;

  // Timestamps to prevent immediate repeat scans
  final Map<String, int> _lastScanTimestamps = {};
  Timer? _cooldownTimer;

  BarcodeViewModel() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    _serverIp = _prefs.getString('server_ip') ?? '192.168.1.100';
    _serverPort = _prefs.getInt('server_port') ?? 8080;
    _scanDelayMs = _prefs.getDouble('scan_delay_ms') ?? 500.0;
    _soundEnabled = _prefs.getBool('sound_enabled') ?? true;
    _vibrationEnabled = _prefs.getBool('vibration_enabled') ?? true;

    await refreshHistory();
    notifyListeners();
  }

  Future<void> refreshHistory() async {
    _scanHistory = await DbHelper.instance.getAllScans();
    notifyListeners();
  }

  Future<void> updateServerIp(String ip) async {
    _serverIp = ip;
    await _prefs.setString('server_ip', ip);
    notifyListeners();
  }

  Future<void> updateServerPort(int port) async {
    _serverPort = port;
    await _prefs.setInt('server_port', port);
    notifyListeners();
  }

  Future<void> updateScanDelay(double delayMs) async {
    _scanDelayMs = delayMs;
    await _prefs.setDouble('scan_delay_ms', delayMs);
    notifyListeners();
  }

  Future<void> updateSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    await _prefs.setBool('sound_enabled', enabled);
    notifyListeners();
  }

  Future<void> updateVibrationEnabled(bool enabled) async {
    _vibrationEnabled = enabled;
    await _prefs.setBool('vibration_enabled', enabled);
    notifyListeners();
  }

  Future<void> clearHistory() async {
    await DbHelper.instance.deleteAllScans();
    await refreshHistory();
  }

  Future<void> deleteScan(int id) async {
    await DbHelper.instance.deleteScan(id);
    await refreshHistory();
  }

  Future<void> testConnection() async {
    _isTestingConnection = true;
    _connectionStatusMessage = 'Pinging companion PC server at http://$_serverIp:$_serverPort/ping...';
    notifyListeners();

    try {
      await _apiClient.pingServer(ipAddress: _serverIp, port: _serverPort);
      _connectionStatusMessage = 'Connected! Companion PC server is active.';
    } catch (e) {
      _connectionStatusMessage = 'Ping failed: ${e.toString()}\nEnsure your companion PC script is running on IP: $_serverIp, port: $_serverPort, and that both devices are connected to the exact same Wi-Fi SSID network.';
    } finally {
      _isTestingConnection = false;
      notifyListeners();
    }
  }

  void onBarcodeScanned(String barcode, String format) {
    if (_isCoolingDown) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final lastTime = _lastScanTimestamps[barcode] ?? 0;
    if (now - lastTime < _scanDelayMs) {
      return; // prevent duplicate scanning of same code too quickly
    }

    _lastScanTimestamps[barcode] = now;
    _lastScannedValue = barcode;
    _lastScannedFormat = format;

    _triggerScanFeedback();
    _startCooldown();

    // Save and send in background
    _processBarcodeScan(barcode, format);
    notifyListeners();
  }

  Future<void> _processBarcodeScan(String barcode, String format) async {
    final newItem = ScanItem(
      barcode: barcode,
      format: format,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      sentSuccessfully: false,
    );

    final id = await DbHelper.instance.insertScan(newItem);
    await refreshHistory();

    try {
      await _apiClient.sendBarcode(
        ipAddress: _serverIp,
        port: _serverPort,
        barcode: barcode,
        format: format,
      );
      await DbHelper.instance.updateSentStatus(id, true);
      await refreshHistory();
    } catch (e) {
      if (kDebugMode) {
        print("Failed to sync barcode: $e");
      }
    }
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    _isCoolingDown = true;
    _cooldownProgress = 1.0;

    final totalTime = _scanDelayMs.toInt();
    const intervals = 20;
    final totalSteps = (totalTime / intervals).ceil();
    int currentStep = totalSteps;

    _cooldownTimer = Timer.periodic(const Duration(milliseconds: intervals), (timer) {
      currentStep--;
      if (currentStep <= 0) {
        _isCoolingDown = false;
        _cooldownProgress = 0.0;
        timer.cancel();
      } else {
        _cooldownProgress = currentStep / totalSteps;
      }
      notifyListeners();
    });
  }

  void _triggerScanFeedback() {
    if (_vibrationEnabled) {
      HapticFeedback.lightImpact();
    }
    if (_soundEnabled) {
      const MethodChannel('com.example.wifi_barcode_scanner/beep').invokeMethod('beep').catchError((e) {
        if (kDebugMode) {
          print("Error playing beep: $e");
        }
      });
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }
}
