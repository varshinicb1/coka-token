import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:logging/logging.dart';

final _log = Logger('UsbPrinterService');

final DynamicLibrary _kernel32 = DynamicLibrary.open('kernel32.dll');

final Pointer<Void> Function(Pointer<Int8>, int, int, Pointer<Void>, int, int,
        Pointer<Void>) _createFile = _kernel32
    .lookupFunction<
        Pointer<Void> Function(Pointer<Int8>, Uint32, Uint32, Pointer<Void>,
            Uint32, Uint32, Pointer<Void>),
        Pointer<Void> Function(Pointer<Int8>, int, int, Pointer<Void>, int, int,
            Pointer<Void>)>('CreateFileA');

final int Function(Pointer<Void>, Pointer<Void>, int, Pointer<Uint32>,
        Pointer<Void>) _writeFile = _kernel32
    .lookupFunction<
        Int32 Function(Pointer<Void>, Pointer<Void>, Uint32, Pointer<Uint32>,
            Pointer<Void>),
        int Function(Pointer<Void>, Pointer<Void>, int, Pointer<Uint32>,
            Pointer<Void>)>('WriteFile');

final int Function(Pointer<Void>) _closeHandle = _kernel32
    .lookupFunction<Int32 Function(Pointer<Void>),
        int Function(Pointer<Void>)>('CloseHandle');

const int _genericWrite = 0x40000000;
const int _openExisting = 3;

class UsbDevice {
  final String portName;
  final String description;
  UsbDevice({required this.portName, required this.description});
}

class UsbPrinterService {
  static final UsbPrinterService _instance = UsbPrinterService._internal();
  factory UsbPrinterService() => _instance;
  UsbPrinterService._internal();

  Pointer<Void>? _handle;
  String? _connectedPort;
  bool get isConnected => _handle != null;
  String? get connectedPort => _connectedPort;

  bool get isSupported => Platform.isWindows;

  Future<List<UsbDevice>> enumerateDevices() async {
    final devices = <UsbDevice>[];
    try {
      final result = await Process.run(
        'powershell',
        [
          '-NoProfile',
          '-Command',
          r'''Get-PnpDevice -Class Ports -ErrorAction SilentlyContinue | Where-Object { $_.FriendlyName -match "COM\d+" } | ForEach-Object {
    $name = $_.FriendlyName
    $port = [regex]::Match($name, "COM\d+").Value
    $instanceId = $_.InstanceId
    $desc = if ($instanceId -match "([A-F0-9]{12})") { $matches[1] } else { "" }
    [PSCustomObject]@{ PortName = $port; Description = $name; BluetoothAddr = $desc }
} | ConvertTo-Json''',
        ],
      );
      if (result.exitCode != 0) return devices;

      final jsonStr = result.stdout.toString().trim();
      if (jsonStr.isEmpty) return devices;

      final dynamic parsed;
      try {
        parsed = jsonDecode(jsonStr);
      } catch (_) {
        return devices;
      }

      final list = (parsed is List) ? parsed : [parsed];
      for (final entry in list) {
        final portName = entry['PortName'] as String? ?? '';
        final description = entry['Description'] as String? ?? '';
        if (portName.isNotEmpty) {
          devices.add(UsbDevice(
            portName: portName,
            description: description,
          ));
        }
      }
    } catch (e, st) {
      _log.warning('Failed to enumerate serial devices', e, st);
    }
    return devices;
  }

  Future<String?> findVeerPort() async {
    try {
      final tempDir = Directory.systemTemp;
      final scriptFile = '${tempDir.path}\\find_veer_port.ps1';
      File(scriptFile).writeAsStringSync(r'''
$bt = Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object { $_.Class -eq 'Bluetooth' -and $_.Status -eq 'OK' }
$veer = $bt | Where-Object { $_.FriendlyName -match 'Veer|Seznik|Seiznik' } | Select-Object -First 1
if (-not $veer) { exit }
$addr = if ($veer.InstanceId -match 'DEV_([A-F0-9]+)') { $matches[1] } else { exit }
$port = Get-PnpDevice -Class Ports -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'OK' -and $_.InstanceId -match $addr } | Select-Object -First 1
if (-not $port) { exit }
[regex]::Match($port.FriendlyName, 'COM\d+').Value
''');
      final result = await Process.run(
        'powershell',
        ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', scriptFile],
      );
      File(scriptFile).deleteSync();
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
    } catch (e, st) {
      _log.warning('Failed to find Veer COM port', e, st);
    }
    return null;
  }

  Future<bool> connect(String portName) async {
    if (_handle != null) {
      await disconnect();
    }
    try {
      final path = '\\\\.\\$portName'.toNativeUtf8();
      _handle = _createFile(
        path.cast<Int8>(),
        _genericWrite,
        0,
        nullptr,
        _openExisting,
        0,
        nullptr,
      );
      calloc.free(path);

      if (_handle == nullptr || _handle!.address == -1) {
        _handle = null;
        _connectedPort = null;
        return false;
      }

      _connectedPort = portName;
      return true;
    } catch (e, st) {
      _log.warning('Failed to connect to $portName', e, st);
      _handle = null;
      _connectedPort = null;
      return false;
    }
  }

  Future<void> disconnect() async {
    if (_handle != null) {
      _closeHandle(_handle!);
      _handle = null;
    }
    _connectedPort = null;
  }

  Future<bool> printReceipt(List<String> lines) async {
    if (_handle == null) return false;

    try {
      final text = '${lines.join('\r\n')}\r\n';
      final bytes = utf8.encode(text);
      final cut = [0x1D, 0x56, 0x00];
      final cashDrawer = [0x1B, 0x70, 0x00, 0x19, 0xFA];

      final allData = Uint8List(bytes.length + cut.length + cashDrawer.length);
      allData.setRange(0, bytes.length, bytes);
      allData.setRange(bytes.length, bytes.length + cut.length, cut);
      allData.setRange(bytes.length + cut.length, allData.length, cashDrawer);

      final ptr = calloc.allocate<Uint8>(allData.length);
      for (var i = 0; i < allData.length; i++) {
        ptr[i] = allData[i];
      }

      final bytesWritten = calloc<Uint32>();
      final result = _writeFile(
        _handle!,
        ptr.cast<Void>(),
        allData.length,
        bytesWritten,
        nullptr,
      );

      calloc.free(ptr);
      calloc.free(bytesWritten);

      await Future.delayed(const Duration(milliseconds: 200));
      return result != 0;
    } catch (e, st) {
      _log.warning('USB print failed', e, st);
      return false;
    }
  }

  void dispose() {
    disconnect();
  }
}
