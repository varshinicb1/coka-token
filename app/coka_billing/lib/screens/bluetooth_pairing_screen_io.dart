import 'dart:io';
import 'package:logging/logging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

import '../theme/app_colors.dart';
import '../services/bluetooth_printer_service_io.dart';
import '../services/usb_printer_service.dart';

final _log = Logger('BluetoothPairingScreen');

class BluetoothPairingScreen extends StatefulWidget {
  const BluetoothPairingScreen({super.key});

  @override
  State<BluetoothPairingScreen> createState() => _BluetoothPairingScreenState();
}

class _BluetoothPairingScreenState extends State<BluetoothPairingScreen> {
  final _service = BluetoothPrinterService();

  bool _isScanning = false;
  bool _permissionDenied = false;
  BluetoothDevice? _selectedDevice;
  List<UsbDevice> _usbDevices = [];
  UsbDevice? _selectedUsb;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      _initBluetooth();
    } else if (Platform.isWindows) {
      _scanUsbDevices();
    }
  }

  Future<void> _initBluetooth() async {
    if (!Platform.isAndroid) return;
    try {
      final perms = await _requestPermissions();
      if (!perms) return;
      await FlutterBluetoothSerial.instance.requestEnable();
    } catch (e, st) {
      _log.warning('Bluetooth init failed', e, st);
    }
  }

  Future<bool> _requestPermissions() async {
    if (!Platform.isAndroid) return false;
    try {
      var status = await Permission.bluetoothScan.status;
      if (!status.isGranted) {
        status = await Permission.bluetoothScan.request();
      }
      var connStatus = await Permission.bluetoothConnect.status;
      if (!connStatus.isGranted) {
        connStatus = await Permission.bluetoothConnect.request();
      }
      var locStatus = await Permission.location.status;
      if (!locStatus.isGranted) {
        locStatus = await Permission.location.request();
      }
      final granted = status.isGranted && connStatus.isGranted;
      if (mounted) {
        setState(() => _permissionDenied = !granted);
      }
      return granted;
    } catch (e, st) {
      _log.warning('Permission request failed', e, st);
      return false;
    }
  }

  Future<void> _startScan() async {
    final perms = await _requestPermissions();
    if (!perms) return;

    setState(() => _isScanning = true);
    try {
      await _service.startDiscovery();
    } catch (e, st) {
      _log.warning('Device scan failed', e, st);
    }
    if (mounted) setState(() => _isScanning = false);
  }

  Future<void> _scanUsbDevices() async {
    setState(() => _isScanning = true);
    try {
      final devices = await _service.usb.enumerateDevices();
      if (mounted) setState(() => _usbDevices = devices);
    } catch (e, st) {
      _log.warning('USB scan failed', e, st);
    }
    if (mounted) setState(() => _isScanning = false);
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() => _selectedDevice = device);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final success = await _service.connect(device);

    if (!mounted) return;
    Navigator.pop(context);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connected to ${device.name ?? device.address}'),
          backgroundColor: AppColors.successGreen,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to connect. Please try again.'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      setState(() => _selectedDevice = null);
    }
  }

  Future<void> _connectToUsb(UsbDevice device) async {
    setState(() => _selectedUsb = device);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final success = await _service.connectUsb(device.portName);

    if (!mounted) return;
    Navigator.pop(context);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connected to ${device.portName} - ${device.description}'),
          backgroundColor: AppColors.successGreen,
        ),
      );
      Navigator.pop(context, device.portName);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to connect. Make sure the printer is plugged in and powered on.'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      setState(() => _selectedUsb = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (Platform.isAndroid) {
      return _buildAndroidView(theme, isDark);
    } else if (Platform.isWindows) {
      return _buildWindowsView(theme, isDark);
    }
    return const Scaffold(body: SizedBox.shrink());
  }

  Widget _buildAndroidView(ThemeData theme, bool isDark) {
    final devices = _service.discoveredDevices;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pair Bluetooth Printer'),
        actions: [
          IconButton(
            icon: _isScanning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.bluetooth_searching),
            onPressed: _isScanning ? null : _startScan,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isScanning)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(
                    'Scanning for printers...',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          else if (_permissionDenied)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 64,
                        color: AppColors.cokaAmber,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Bluetooth permissions denied',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Grant Bluetooth permissions in Settings to scan for printers.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _startScan,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (devices.isEmpty)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bluetooth_disabled,
                        size: 64,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No printers found',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap scan to discover.',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                itemCount: devices.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final device = devices[index];
                  final isSelected = _selectedDevice?.address == device.address;

                  return Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _connectToDevice(device),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.primary.withValues(alpha: 0.15)
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.grey.withValues(alpha: 0.08)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.print,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    device.name ?? 'Unknown Printer',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    device.address,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: theme.colorScheme.primary,
                                size: 22,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          if (devices.isNotEmpty)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _selectedDevice == null
                        ? null
                        : () => _connectToDevice(_selectedDevice!),
                    icon: const Icon(Icons.link),
                    label: const Text('Connect'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWindowsView(ThemeData theme, bool isDark) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect USB Printer'),
        actions: [
          IconButton(
            icon: _isScanning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isScanning ? null : _scanUsbDevices,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                Text(
                  'Connect your ESC/POS thermal printer via USB.',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tip: If the printer is not listed, try:\n'
                  '1. Use a USB cable that supports data (not charge-only)\n'
                  '2. Power the printer ON before connecting USB\n'
                  '3. Pair via Bluetooth in Windows Settings first',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (_isScanning)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_usbDevices.isEmpty)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.usb,
                        size: 64,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No USB printers found',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Make sure the printer is plugged in via USB and powered on.\n'
                        'Tap refresh to scan again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: _usbDevices.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final device = _usbDevices[index];
                  final isSelected = _selectedUsb?.portName == device.portName;

                  return Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _connectToUsb(device),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.primary.withValues(alpha: 0.15)
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.grey.withValues(alpha: 0.08)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.usb,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    device.description.split('(').first.trim(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    device.portName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: theme.colorScheme.primary,
                                size: 22,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          if (_usbDevices.isNotEmpty)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _selectedUsb == null
                        ? null
                        : () => _connectToUsb(_selectedUsb!),
                    icon: const Icon(Icons.link),
                    label: const Text('Connect'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
