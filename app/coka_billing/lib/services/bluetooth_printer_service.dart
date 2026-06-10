import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothPrinterService {
  static final BluetoothPrinterService _instance =
      BluetoothPrinterService._internal();

  factory BluetoothPrinterService() => _instance;

  BluetoothPrinterService._internal();

  BluetoothConnection? _connection;
  bool _isConnected = false;
  BluetoothDevice? _connectedDevice;
  final List<BluetoothDevice> _discoveredDevices = [];

  bool get isSupported => Platform.isAndroid;

  BluetoothConnection? get connection => _connection;
  bool get isConnected => _isConnected;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  List<BluetoothDevice> get discoveredDevices =>
      List.unmodifiable(_discoveredDevices);
  List<BluetoothDevice> get pairedDevices => _discoveredDevices;

  Future<bool> startDiscovery() async {
    try {
      if (Platform.isAndroid) {
        try {
          await FlutterBluetoothSerial.instance.requestEnable();
        } catch (_) {}
      }

      _discoveredDevices.clear();

      if (await FlutterBluetoothSerial.instance.isEnabled != true) {
        return false;
      }

      final bonded = await FlutterBluetoothSerial.instance.getBondedDevices();
      for (final device in bonded) {
        if (!_discoveredDevices.contains(device)) {
          _discoveredDevices.add(device);
        }
      }

      final subscription =
          FlutterBluetoothSerial.instance.startDiscovery().listen((result) {
        if (!_discoveredDevices.contains(result.device)) {
          _discoveredDevices.add(result.device);
        }
      });

      await Future.delayed(const Duration(seconds: 6));
      await subscription.cancel();

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> connect(BluetoothDevice device) async {
    try {
      final connection =
          await BluetoothConnection.toAddress(device.address);
      _connection = connection;
      _connectedDevice = device;
      _isConnected = true;

      connection.input!.listen(
        (data) {},
        onError: (_) => disconnect(),
        onDone: () => disconnect(),
      );

      return true;
    } catch (_) {
      _isConnected = false;
      _connection = null;
      _connectedDevice = null;
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _connection?.close();
    } catch (_) {}
    _connection = null;
    _isConnected = false;
    _connectedDevice = null;
  }

  Future<bool> printReceipt(List<String> lines) async {
    if (_connection == null || !_isConnected) return false;

    try {
      for (final line in lines) {
        final bytes = utf8.encode('$line\n');
        final data = Uint8List.fromList([...bytes, 0x0D, 0x0A]);
        _connection!.output.add(data);
        await _connection!.output.allSent;
      }

      await Future.delayed(const Duration(milliseconds: 200));

      final cut = Uint8List.fromList([0x1D, 0x56, 0x00]);
      _connection!.output.add(cut);
      await _connection!.output.allSent;

      final cashDrawer = Uint8List.fromList([0x1B, 0x70, 0x00, 0x19, 0xFA]);
      _connection!.output.add(cashDrawer);
      await _connection!.output.allSent;

      return true;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    disconnect();
    _discoveredDevices.clear();
  }
}
