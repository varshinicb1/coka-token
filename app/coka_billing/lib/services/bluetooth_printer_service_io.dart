import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:logging/logging.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'usb_printer_service.dart';

final _log = Logger('BluetoothPrinterService');

class BluetoothDeviceProxy {
  final String name;
  final String address;
  BluetoothDeviceProxy({this.name = '', this.address = ''});
}

class BluetoothPrinterService {
  static final BluetoothPrinterService _instance =
      BluetoothPrinterService._internal();

  factory BluetoothPrinterService() => _instance;

  BluetoothPrinterService._internal();

  BluetoothConnection? _connection;
  bool _isConnected = false;
  BluetoothDevice? _connectedDevice;
  final List<BluetoothDevice> _discoveredDevices = [];
  final UsbPrinterService _usb = UsbPrinterService();

  bool get isSupported => Platform.isAndroid || Platform.isWindows;
  bool get isWindowsUsb => Platform.isWindows;

  BluetoothConnection? get connection => _connection;
  bool get isConnected =>
      Platform.isAndroid ? _isConnected : _usb.isConnected;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  List<BluetoothDevice> get discoveredDevices =>
      List.unmodifiable(_discoveredDevices);
  List<BluetoothDevice> get pairedDevices => _discoveredDevices;
  UsbPrinterService get usb => _usb;

  Future<bool> startDiscovery() async {
    if (Platform.isWindows) return false;
    try {
      if (Platform.isAndroid) {
        try {
          await FlutterBluetoothSerial.instance.requestEnable();
        } catch (e, st) {
          _log.fine('Bluetooth enable request failed', e, st);
        }
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
    } catch (e, st) {
      _log.warning('Device discovery failed', e, st);
      return false;
    }
  }

  Future<bool> connect(BluetoothDevice device) async {
    if (Platform.isWindows) return false;
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
    } catch (e, st) {
      _log.warning('Bluetooth connect failed', e, st);
      _isConnected = false;
      _connection = null;
      _connectedDevice = null;
      return false;
    }
  }

  Future<List<String>> enumerateUsbPorts() async {
    if (!Platform.isWindows) return [];
    final devices = await _usb.enumerateDevices();
    return devices.map((d) => d.portName).toList();
  }

  Future<String?> findVeerPort() async {
    if (!Platform.isWindows) return null;
    return _usb.findVeerPort();
  }

  Future<bool> connectUsb(String portName) async {
    if (!Platform.isWindows) return false;
    return _usb.connect(portName);
  }

  Future<void> disconnect() async {
    if (Platform.isAndroid) {
      try {
        await _connection?.close();
      } catch (e, st) {
        _log.fine('Disconnect error', e, st);
      }
      _connection = null;
      _isConnected = false;
      _connectedDevice = null;
    } else if (Platform.isWindows) {
      await _usb.disconnect();
    }
  }

  Future<bool> printReceipt(List<String> lines) async {
    if (Platform.isAndroid) {
      if (_connection == null || !_isConnected) return false;

      try {
        for (final line in lines) {
          final bytes = utf8.encode('$line\r\n');
          final data = Uint8List.fromList(bytes);
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
      } catch (e, st) {
        _log.warning('Print failed', e, st);
        return false;
      }
    } else if (Platform.isWindows) {
      return _usb.printReceipt(lines);
    }
    return false;
  }

  void dispose() {
    disconnect();
    _discoveredDevices.clear();
  }
}
