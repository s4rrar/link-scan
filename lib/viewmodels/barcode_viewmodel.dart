import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scan_item.dart';
import '../database/db_helper.dart';
import '../network/api_client.dart';
import '../theme/app_styles.dart';
import '../theme/app_theme.dart';

enum ConnectionStatus { connected, failed, ready }

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

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  PrimaryColorOption _primaryColor = PrimaryColorOption.blue;
  PrimaryColorOption get primaryColor => _primaryColor;

  Color _customColor = const Color(0xFF10B981);
  Color get customColor => _customColor;

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

  // Connection status
  ConnectionStatus _connectionStatus = ConnectionStatus.ready;
  ConnectionStatus get connectionStatus => _connectionStatus;

  // Test ping response messages
  String? _connectionStatusMessage;
  String? get connectionStatusMessage => _connectionStatusMessage;

  bool _isTestingConnection = false;
  bool get isTestingConnection => _isTestingConnection;

  Timer? _pingTimer;
  Timer? _failureTimer;

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
    _isDarkMode = _prefs.getBool('dark_mode_enabled') ?? false;

    final colorName = _prefs.getString('primary_color_option') ?? 'Classic Blue';
    _primaryColor = PrimaryColorOption.values.firstWhere(
      (e) => e.name == colorName,
      orElse: () => PrimaryColorOption.blue,
    );

    final customColorInt = _prefs.getInt('custom_color_value') ?? const Color(0xFF10B981).value;
    _customColor = Color(customColorInt);
    AppThemeState.customColorValue = _customColor;

    await refreshHistory();
    _startPeriodicPing();
    notifyListeners();
  }

  void _startPeriodicPing() {
    _pingTimer?.cancel();
    _ping();
    _pingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _ping());
  }

  Future<void> _ping() async {
    try {
      await _apiClient.pingServer(ipAddress: _serverIp, port: _serverPort);
      _failureTimer?.cancel();
      if (_connectionStatus != ConnectionStatus.connected) {
        _connectionStatus = ConnectionStatus.connected;
        notifyListeners();
      }
    } catch (_) {
      if (_connectionStatus == ConnectionStatus.connected) {
        _connectionStatus = ConnectionStatus.failed;
        notifyListeners();
        _failureTimer?.cancel();
        _failureTimer = Timer(const Duration(seconds: 3), () {
          _connectionStatus = ConnectionStatus.ready;
          notifyListeners();
        });
      }
    }
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

  Future<void> updateDarkMode(bool enabled) async {
    _isDarkMode = enabled;
    await _prefs.setBool('dark_mode_enabled', enabled);
    notifyListeners();
  }

  Future<void> updatePrimaryColor(PrimaryColorOption color) async {
    _primaryColor = color;
    await _prefs.setString('primary_color_option', color.name);
    notifyListeners();
  }

  Future<void> updateCustomColor(Color color) async {
    _customColor = color;
    await _prefs.setInt('custom_color_value', color.value);
    AppThemeState.customColorValue = color;
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
      _failureTimer?.cancel();
      _connectionStatus = ConnectionStatus.connected;
    } catch (e) {
      _connectionStatusMessage = 'Ping failed: ${e.toString()}\nEnsure your companion PC script is running on IP: $_serverIp, port: $_serverPort, and that both devices are connected to the exact same Wi-Fi SSID network.';
      if (_connectionStatus != ConnectionStatus.failed) {
        _connectionStatus = ConnectionStatus.failed;
      }
      _failureTimer?.cancel();
      _failureTimer = Timer(const Duration(seconds: 3), () {
        _connectionStatus = ConnectionStatus.ready;
        notifyListeners();
      });
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
      const MethodChannel('com.linkscan.org/beep').invokeMethod('beep').catchError((e) {
        if (kDebugMode) {
          print("Error playing beep: $e");
        }
      });
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _pingTimer?.cancel();
    _failureTimer?.cancel();
    super.dispose();
  }
}
