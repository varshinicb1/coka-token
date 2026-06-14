class BluetoothDeviceProxy {
  final String name;
  final String address;
  BluetoothDeviceProxy({this.name = '', this.address = ''});
}

class BluetoothPrinterService {
  static final BluetoothPrinterService _instance = BluetoothPrinterService._internal();
  factory BluetoothPrinterService() => _instance;
  BluetoothPrinterService._internal();

  bool get isSupported => false;
  bool get isConnected => false;
  BluetoothDeviceProxy? get connectedDevice => null;
  List<BluetoothDeviceProxy> get discoveredDevices => [];
  List<BluetoothDeviceProxy> get pairedDevices => [];

  Future<bool> startDiscovery() async => false;
  Future<bool> connect(BluetoothDeviceProxy device) async => false;
  Future<void> disconnect() async {}
  Future<bool> printReceipt(List<String> lines) async => false;
  void dispose() {}
}
