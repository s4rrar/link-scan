import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../theme/app_styles.dart';
import '../viewmodels/barcode_viewmodel.dart';

class CompanionTab extends StatefulWidget {
  final BarcodeViewModel viewModel;
  const CompanionTab({super.key, required this.viewModel});

  @override
  State<CompanionTab> createState() => _CompanionTabState();
}

class _CompanionTabState extends State<CompanionTab> {
  bool _isWindows = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _downloadStatusText = '';
  io.Process? _process;
  bool _isRunning = false;
  final List<String> _logs = [];
  String? _exePath;
  bool _exeExists = false;
  final ScrollController _logScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _isWindows = !kIsWeb && io.Platform.isWindows;
    if (_isWindows) {
      _initExePath();
    }
  }

  @override
  void dispose() {
    // If the process is running, we don't force kill it, but standard practice in Flutter
    // desktop is to dispose controllers. If we want it to die with app exit, the OS will clean it up.
    _logScrollController.dispose();
    super.dispose();
  }

  Future<void> _initExePath() async {
    try {
      final directory = await getApplicationSupportDirectory();
      setState(() {
        _exePath = p.join(directory.path, 'LinkScanPC.exe');
      });
      _checkExeExists();
    } catch (e) {
      _addLog('Error initializing path directory: $e');
    }
  }

  void _checkExeExists() {
    if (_exePath == null) return;
    final file = io.File(_exePath!);
    setState(() {
      _exeExists = file.existsSync();
    });
  }

  void _addLog(String message) {
    if (!mounted) return;
    setState(() {
      final lines = message.split('\n');
      for (var line in lines) {
        if (line.trim().isNotEmpty ||
            _logs.isEmpty ||
            _logs.last.trim().isNotEmpty) {
          _logs.add(line);
        }
      }
      if (_logs.length > 300) {
        _logs.removeRange(0, _logs.length - 300);
      }
    });

    // Smooth scrolling to the end of logs
    Future.microtask(() {
      if (_logScrollController.hasClients) {
        _logScrollController.animateTo(
          _logScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _downloadExe() async {
    if (_exePath == null) return;
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _downloadStatusText = 'Connecting to GitHub...';
      _logs.clear();
    });
    _addLog('[DOWNLOAD] Requesting LinkScanPC.exe from GitHub releases...');

    final primaryUrl =
        'https://github.com/s4rrar/link-scan-pc/releases/latest/download/LinkScanPC.exe';
    final fallbackUrl =
        'https://github.com/s4rrar/link-scan/releases/latest/download/LinkScanPC.exe';

    try {
      bool success = await _downloadFile(primaryUrl);
      if (!success) {
        _addLog(
          '[DOWNLOAD] Primary target returned 404 or failed. Trying fallback repository...',
        );
        setState(() {
          _downloadStatusText = 'Connecting to fallback...';
        });
        success = await _downloadFile(fallbackUrl);
      }

      if (success) {
        _addLog('[DOWNLOAD] Executable downloaded and saved.');
        _checkExeExists();
        _showSnackBar('LinkScanPC downloaded successfully!');
      } else {
        _addLog(
          '[ERROR] Download failed from all sources. Please try again or download manually.',
        );
        _showSnackBar('Download failed. Check network or download manually.');
      }
    } catch (e) {
      _addLog('[ERROR] Exception during download: $e');
      _showSnackBar('Download failed with error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  Future<bool> _downloadFile(String url) async {
    _addLog('[DOWNLOAD] Downloading from: $url');
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await client
          .send(request)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        _addLog('[DOWNLOAD] HTTP Error Code: ${response.statusCode}');
        return false;
      }

      final totalBytes = response.contentLength ?? 0;
      if (totalBytes > 0) {
        _addLog(
          '[DOWNLOAD] Total File Size: ${(totalBytes / 1024 / 1024).toStringAsFixed(2)} MB',
        );
      }

      final file = io.File(_exePath!);
      await file.parent.create(recursive: true);

      final sink = file.openWrite();
      int downloadedBytes = 0;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;
        if (totalBytes > 0) {
          final progress = downloadedBytes / totalBytes;
          if (mounted) {
            setState(() {
              _downloadProgress = progress;
              _downloadStatusText =
                  'Downloading: ${(progress * 100).toStringAsFixed(1)}%';
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _downloadStatusText =
                  'Downloaded ${(downloadedBytes / 1024 / 1024).toStringAsFixed(2)} MB';
            });
          }
        }
      }

      await sink.flush();
      await sink.close();
      return true;
    } catch (e) {
      _addLog('[DOWNLOAD] Error during file stream write: $e');
      return false;
    } finally {
      client.close();
    }
  }

  Future<void> _startProcess() async {
    if (_exePath == null || !_exeExists) return;
    _addLog('[SYSTEM] Starting LinkScanPC.exe process...');

    try {
      final file = io.File(_exePath!);
      final workingDir = file.parent.path;

      if (_process != null) {
        _addLog('[SYSTEM] Warning: Process is already registered.');
        return;
      }

      // Launch process in background
      final process = await io.Process.start(
        _exePath!,
        [],
        workingDirectory: workingDir,
      );

      setState(() {
        _process = process;
        _isRunning = true;
      });

      _addLog('[SYSTEM] LinkScanPC active. PID: ${process.pid}');
      _showSnackBar('LinkScanPC companion started!');

      // Read stdout safely
      process.stdout.listen(
        (bytes) {
          final text = utf8.decode(bytes, allowMalformed: true);
          _addLog(text);
        },
        onError: (err) {
          _addLog('[STDOUT ERR] $err');
        },
      );

      // Read stderr safely
      process.stderr.listen(
        (bytes) {
          final text = utf8.decode(bytes, allowMalformed: true);
          _addLog('[STDERR] $text');
        },
        onError: (err) {
          _addLog('[STDERR ERR] $err');
        },
      );

      // Wait for completion
      process.exitCode.then((code) {
        if (mounted) {
          setState(() {
            _process = null;
            _isRunning = false;
          });
          _addLog('[SYSTEM] LinkScanPC closed. Exit code: $code');
          _showSnackBar('Companion server stopped.');
        }
      });
    } catch (e) {
      _addLog('[SYSTEM ERR] Failed to start companion process: $e');
      setState(() {
        _process = null;
        _isRunning = false;
      });
      _showSnackBar('Error launching companion: $e');
    }
  }

  Future<void> _stopProcess() async {
    if (_process == null) return;
    _addLog('[SYSTEM] Terminating LinkScanPC process...');
    try {
      final success = _process!.kill();
      _addLog('[SYSTEM] Termination signal sent. Result: $success');
    } catch (e) {
      _addLog('[SYSTEM ERR] Error stopping process: $e');
    }
  }

  Future<void> _deleteExe() async {
    if (_exePath == null || !_exeExists) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = AppThemeState.isDark;
        return BackdropFilter(
          filter: AppStyles.glassBlurFilter,
          child: AlertDialog(
            backgroundColor: (isDark ? Colors.black : Colors.white).withOpacity(0.85),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
              side: BorderSide(
                color: (isDark ? Colors.white : polishPrimary).withOpacity(0.2),
                width: 1.2,
              ),
            ),
            title: const Text('Delete Companion?'),
            content: const Text(
              'Are you sure you want to remove the downloaded LinkScanPC executable? You will need to re-download it to launch it from the app again.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
    );

    if (confirm == true) {
      try {
        final file = io.File(_exePath!);
        if (file.existsSync()) {
          await file.delete();
        }
        setState(() {
          _exeExists = false;
        });
        _addLog('[SYSTEM] Executable deleted from local system.');
        _showSnackBar('LinkScanPC executable deleted.');
      } catch (e) {
        _addLog('[SYSTEM ERR] Failed to delete file: $e');
        _showSnackBar('Failed to delete: $e');
      }
    }
  }

  Future<void> _openLocation() async {
    if (_exePath == null) return;
    final file = io.File(_exePath!);
    final uri = Uri.directory(file.parent.path);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showSnackBar('Could not open folder location.');
      }
    } catch (e) {
      _showSnackBar('Error opening location: $e');
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DESKTOP COMPANION SETUP',
                        style: TextStyle(
                          color: polishPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.0,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'Sync scans instantly onto your computer with LinkScanPC server.',
                        style: TextStyle(
                          color: polishOnSurfaceVariant,
                          fontSize: 13.0,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isWindows && _exeExists && !_isRunning)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    tooltip: 'Delete Executable',
                    onPressed: _deleteExe,
                  ),
              ],
            ),
            const SizedBox(height: 16.0),

            if (_isWindows) ...[
              // Windows Interactive Section
              _buildWindowsControlPanel(),
              const SizedBox(height: 16.0),
              _buildTerminalLogsView(),
              const SizedBox(height: 20.0),
              _buildSettingsInformationCard(),
            ] else ...[
              // Fallback instructions for non-Windows (Android, iOS, Web, macOS, Linux)
              _buildNonWindowsCard(),
            ],

            const SizedBox(height: 16.0),
            _buildStepGuideCard(),
          ],
        );
      },
    );
  }

  Widget _buildWindowsControlPanel() {
    final isDark = AppThemeState.isDark;
    return GlassContainer(
      isDark: isDark,
      primaryColor: polishPrimary,
      borderRadius: AppStyles.radiusLarge,
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.laptop_windows_rounded,
                color: polishPrimary,
                size: 24.0,
              ),
              const SizedBox(width: 10.0),
              const Text(
                'Windows App Integration',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Text(
            'Manage your local LinkScanPC receiver directly from this app window. No command prompt required.',
            style: TextStyle(
              color: polishOnSurfaceVariant,
              fontSize: 13.0,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20.0),

          if (!_exeExists) ...[
            // Download section
            if (_isDownloading) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _downloadStatusText,
                        style: TextStyle(
                          color: polishPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.0,
                        ),
                      ),
                      Text(
                        '${(_downloadProgress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: polishPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: LinearProgressIndicator(
                      value: _downloadProgress > 0 ? _downloadProgress : null,
                      minHeight: 8.0,
                      backgroundColor: polishPrimaryContainer.withOpacity(
                        0.3,
                      ),
                      color: polishPrimary,
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                height: 48.0,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: polishPrimary,
                    foregroundColor: polishOnPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.0),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _downloadExe,
                  icon: const Icon(Icons.download, size: 20.0),
                  label: const Text(
                    'Download LinkScanPC.exe',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ] else ...[
            // Action buttons to start / stop / browse
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46.0,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isRunning
                            ? Colors.redAccent
                            : Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isRunning ? _stopProcess : _startProcess,
                      icon: Icon(
                        _isRunning ? Icons.stop : Icons.play_arrow,
                        size: 20.0,
                      ),
                      label: Text(
                        _isRunning ? 'Stop Companion' : 'Start Companion',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.0,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10.0),
                Container(
                  height: 46.0,
                  decoration: BoxDecoration(
                    color: polishSurfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: polishOutline.withOpacity(0.2),
                      width: 1.0,
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.folder_open),
                    tooltip: 'Open Executable Location',
                    onPressed: _openLocation,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTerminalLogsView() {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: const Color(0xFF0F1113),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: polishOutline.withOpacity(0.3), width: 1.0),
      ),
      child: Column(
        children: [
          // Terminal Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            decoration: BoxDecoration(
              color: polishSurfaceVariant.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15.0),
                topRight: Radius.circular(15.0),
              ),
              border: Border(
                bottom: BorderSide(
                  color: polishOutline.withOpacity(0.2),
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              children: [
                // Mac-style window controls
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF5F56),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFBD2E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF27C93F),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Text(
                    'LinkScanPC Console Output',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: polishOnSurfaceVariant.withOpacity(0.8),
                      fontSize: 11.0,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                if (_logs.isNotEmpty)
                  InkWell(
                    onTap: () {
                      setState(() {
                        _logs.clear();
                      });
                    },
                    child: Icon(
                      Icons.delete_sweep_outlined,
                      color: polishOnSurfaceVariant,
                      size: 16.0,
                    ),
                  ),
                const SizedBox(width: 10.0),
                // Status indicator lamp
                Container(
                  width: 8.0,
                  height: 8.0,
                  decoration: BoxDecoration(
                    color: _isRunning
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFFFC107),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (_isRunning
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFFFFC107))
                                .withOpacity(0.5),
                        blurRadius: 4.0,
                        spreadRadius: 1.0,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Logs contents
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              width: double.infinity,
              color: const Color(0xFF0F1113),
              child: _logs.isEmpty
                  ? Center(
                      child: Text(
                        'No console output active.\nLaunch the companion to view logs here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: polishOnSurfaceVariant.withOpacity(0.4),
                          fontSize: 11.0,
                          fontFamily: 'monospace',
                          height: 1.5,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _logScrollController,
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: SelectableText(
                            _logs[index],
                            style: const TextStyle(
                              color: Color(0xFFE2E2E6),
                              fontSize: 11.5,
                              fontFamily: 'monospace',
                              height: 1.4,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsInformationCard() {
    final isDark = AppThemeState.isDark;
    return GlassContainer(
      isDark: isDark,
      primaryColor: polishPrimary,
      borderRadius: AppStyles.radiusMedium,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💡 Configuration Tips',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),
          ),
          const SizedBox(height: 6.0),
          Text(
            '• By default, LinkScanPC listens on port 8080.\n'
            '• Auto-typing config and preferences are stored locally at:\n'
            '  %USERPROFILE%\\.linkscanpc\\settings.json\n'
            '• The server runs safely in your background tray context.',
            style: TextStyle(
              color: polishOnSurfaceVariant,
              fontSize: 12.0,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNonWindowsCard() {
    final isDark = AppThemeState.isDark;
    return GlassContainer(
      isDark: isDark,
      primaryColor: polishPrimary,
      borderRadius: AppStyles.radiusLarge,
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.devices, color: polishPrimary, size: 24.0),
              const SizedBox(width: 10.0),
              const Text(
                'LinkScanPC Companion',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          Text(
            'The compiled LinkScanPC executable runs directly on Windows. For non-Windows platforms, or to set up manually, you can download the latest releases from GitHub.',
            style: TextStyle(
              color: polishOnSurfaceVariant,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18.0),
          SizedBox(
            width: double.infinity,
            height: 48.0,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: polishPrimary,
                foregroundColor: polishOnPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.0),
                ),
                elevation: 0,
              ),
              onPressed: () async {
                final url = Uri.parse(
                  'https://github.com/s4rrar/link-scan/releases',
                );
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                } else {
                  _showSnackBar('Could not launch URL');
                }
              },
              icon: const Icon(Icons.open_in_new, size: 20.0),
              label: const Text(
                'Open Releases Page',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepGuideCard() {
    final isDark = AppThemeState.isDark;
    return GlassContainer(
      isDark: isDark,
      primaryColor: polishPrimary,
      borderRadius: AppStyles.radiusLarge,
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Setup Instructions',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: polishPrimary,
              fontSize: 15.0,
            ),
          ),
          const SizedBox(height: 12.0),
          _buildStepRow(
            '1',
            'Download / Start',
            'Install LinkScanPC from GitHub releases on your computer.',
          ),
          const SizedBox(height: 12.0),
          _buildStepRow(
            '2',
            'Connect to Local Wi-Fi',
            'Ensure both your computer and your phone are connected to the exact same Wi-Fi SSID network.',
          ),
          const SizedBox(height: 12.0),
          _buildStepRow(
            '3',
            'Configure IP & Port',
            'Head to the Settings tab in this App. Enter your PC\'s Local IP address and Port (usually 8080), then press Test Connection.',
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow(String stepNum, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: polishPrimaryContainer,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            stepNum,
            style: TextStyle(
              color: polishOnPrimaryContainer,
              fontWeight: FontWeight.bold,
              fontSize: 12.0,
            ),
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                description,
                style: TextStyle(
                  color: polishOnSurfaceVariant,
                  fontSize: 12.0,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
