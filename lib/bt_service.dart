import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';
import 'package:firebase_database/firebase_database.dart';

class BluetoothService {
  final FlutterBluetoothSerial bluetooth = FlutterBluetoothSerial.instance;
  BluetoothConnection? connection;
  Function(int)? onStepCountReceived;
  final DatabaseReference database =
      FirebaseDatabase.instance.ref("smartwatch_data");

  String _buffer =
      ""; // Buffer for handling multi-part or newline-separated data

  Future<void> requestBluetoothPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    statuses.forEach((permission, status) {
      print('Permission $permission = $status');
    });
  }

  Future<void> scanAndConnect() async {
    await requestBluetoothPermissions();

    try {
      List<BluetoothDevice> devices = await bluetooth.getBondedDevices();

      for (var device in devices) {
        print("Found bonded device: ${device.name} @ ${device.address}");
        if (device.name == "HC-05") {
          print("Trying to connect to ${device.name}");
          await _connectToDevice(device);
          break;
        }
      }
    } catch (e) {
      print("Error during scanning or connection: $e");
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      connection = await BluetoothConnection.toAddress(device.address);
      print('✅ Connected to ${device.name}');

      connection!.input!.listen((data) {
        _handleData(data);
      }).onDone(() {
        print('🔌 Disconnected from device');
      });
    } catch (error) {
      print('❌ Connection error: $error');
    }
  }

  void _handleData(Uint8List data) {
    _buffer += String.fromCharCodes(data);

    // Split into lines, remove the last one if it's incomplete
    List<String> lines = _buffer.split('\n');
    _buffer = lines.removeLast(); // Save incomplete line

    for (String line in lines) {
      line = line.trim();
      if (line.isNotEmpty) {
        try {
          int stepCount = int.parse(line);
          print("✅ Parsed step count: $stepCount");
          _storeDataInFirebase(stepCount);
          onStepCountReceived?.call(stepCount);
        } catch (e) {
          print("❌ Could not parse line '$line': $e");
        }
      }
    }
  }

  void _storeDataInFirebase(int stepCount) {
    database.push().set({
      "timestamp": DateTime.now().toIso8601String(),
      "step_count": stepCount,
    }).then((_) {
      print("✅ Data saved to Firebase");
    }).catchError((error) {
      print("❌ Failed to save data: $error");
    });
  }

  void disconnect() {
    if (connection != null && connection!.isConnected) {
      connection?.finish();
      print("🔌 Bluetooth connection finished");
    }
  }
}
