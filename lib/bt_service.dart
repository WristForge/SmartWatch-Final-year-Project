import 'package:bluetooth_classic/bluetooth_classic.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:bluetooth_classic/models/device.dart';

class BluetoothService {
  final bluetooth = BluetoothClassic();
  final DatabaseReference database =
      FirebaseDatabase.instance.ref("smartwatch_data");

  static final BluetoothService instance = BluetoothService._internal();

  BluetoothService._internal();

  factory BluetoothService() => instance;

  String _buffer = "";
  int _currentHourlyStepCount = 0;
  String _currentHour = _getCurrentHourString();
  bool _isConnected = false;

  // Callbacks for UI update
  Function(int)? onStepCountReceived;
  Function(int)? onHeartRateReceived;
  Function(double)? onSpO2Received;
  Function(double)? onTemperatureReceived;
  Function(double)? onPressureReceived;
  Function(double)? onAltitudeReceived;

  static String _getCurrentHourString() {
    final now = DateTime.now();
    return DateFormat('yyyy-MM-dd_HH').format(now);
  }

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

  Future<bool> scanAndConnect() async {
    await requestBluetoothPermissions();

    try {
      await bluetooth.initPermissions();
      List<Device> devices = await bluetooth.getPairedDevices();

      for (var device in devices) {
        print("Found bonded device: ${device.name} @ ${device.address}");
        if (device.name == "HC-05") {
          print("Trying to connect to ${device.name}");

          await bluetooth.connect(
            device.address,
            "00001101-0000-1000-8000-00805f9b34fb", // Serial UUID
          );

          _isConnected = true;
          _listenToData();

          print("✅ Connected to HC-05");

          return _isConnected;
        }
      }
    } catch (e) {
      print("❌ Error during scanning or connection: $e");
    }
    return _isConnected;
  }

  void _listenToData() {
    bluetooth.onDeviceDataReceived().listen((Uint8List data) {
      _handleData(data);
    }, onError: (error) {
      print('❌ Error receiving data: $error');
    });
  }

  void _handleData(Uint8List data) {
    _buffer += String.fromCharCodes(data);

    List<String> lines = _buffer.split('\n');
    _buffer = lines.removeLast();

    for (String line in lines) {
      line = line.trim();
      if (line.isNotEmpty) {
        _parseAndStoreReading(line);
      }
    }
  }

  void _parseAndStoreReading(String reading) {
    print('📩 Received: $reading');

    if (reading.startsWith("Step Count:")) {
      try {
        String value = reading.split(":")[1].trim();
        int step = int.parse(value);

        _updateHourlyStepCount(step);

        if (onStepCountReceived != null) {
          onStepCountReceived!(step);
        }
      } catch (e) {
        print('❌ Failed to parse Step Count: $e');
      }
    } else if (reading.startsWith("Heart Rate:")) {
      try {
        String bpmString = reading.split(":")[1].replaceAll("BPM", "").trim();
        int bpm = int.parse(bpmString);

        _storeHeartRate(bpm);

        if (onHeartRateReceived != null) {
          onHeartRateReceived!(bpm);
        }

        _saveHeartRateToPrefs(bpm);
      } catch (e) {
        print('❌ Failed to parse Heart Rate: $e');
      }
    } else if (reading.startsWith("SpO2:")) {
      try {
        String spo2String = reading.split(":")[1].replaceAll("%", "").trim();
        double spo2 = double.parse(spo2String);

        _storeSpO2(spo2);

        if (onSpO2Received != null) {
          onSpO2Received!(spo2);
        }

        _saveSpO2ToPrefs(spo2);
      } catch (e) {
        print('❌ Failed to parse SpO2: $e');
      }
    } else if (reading.startsWith("Temperature:")) {
      try {
        String tempString = reading.split(":")[1].replaceAll("C", "").trim();
        double temp = double.parse(tempString);

        _storeTemperature(temp);

        if (onTemperatureReceived != null) {
          onTemperatureReceived!(temp);
        }
      } catch (e) {
        print('❌ Failed to parse Temperature: $e');
      }
    } else if (reading.startsWith("Pressure:")) {
      try {
        String pressureString =
            reading.split(":")[1].replaceAll("hPa", "").trim();
        double pressure = double.parse(pressureString);

        _storePressure(pressure);

        if (onPressureReceived != null) {
          onPressureReceived!(pressure);
        }
      } catch (e) {
        print('❌ Failed to parse Pressure: $e');
      }
    } else if (reading.startsWith("Altitude:")) {
      try {
        String altitudeString =
            reading.split(":")[1].replaceAll("m", "").trim();
        double altitude = double.parse(altitudeString);

        _storeAltitude(altitude);

        if (onAltitudeReceived != null) {
          onAltitudeReceived!(altitude);
        }
      } catch (e) {
        print('❌ Failed to parse Altitude: $e');
      }
    } else if (reading.contains("No finger detected")) {
      print('👆 No finger detected, skipping save.');
    }
  }

  void _updateHourlyStepCount(int steps) {
    String nowHour = _getCurrentHourString();

    if (nowHour != _currentHour) {
      _pushCurrentStepCount();
      _currentHour = nowHour;
      _currentHourlyStepCount = 0;
    }

    _currentHourlyStepCount += 1;
    print(
        "🕐 [$_currentHour] Updated hourly step count: $_currentHourlyStepCount");

    _updateStepCountInFirebase();
  }

  void _pushCurrentStepCount() {
    if (_currentHourlyStepCount > 0) {
      database.child("step_counts").child(_currentHour).set({
        "step_count": _currentHourlyStepCount,
        "timestamp": DateTime.now().toIso8601String(),
      }).then((_) {
        print("✅ Hourly step count pushed to Firebase");
      }).catchError((error) {
        print("❌ Failed to push hourly data: $error");
      });
    }
  }

  void _updateStepCountInFirebase() {
    database.child("step_counts").child(_currentHour).update({
      "step_count": _currentHourlyStepCount,
      "timestamp": DateTime.now().toIso8601String(),
    }).catchError((error) {
      print("❌ Failed to update step count: $error");
    });
  }

  void _storeHeartRate(int bpm) {
    database.child("heart_rate_readings").push().set({
      "heart_rate_bpm": bpm,
      "timestamp": DateTime.now().toIso8601String(),
    });
  }

  void _storeSpO2(double spo2) {
    database.child("spo2_readings").push().set({
      "spo2_percentage": spo2,
      "timestamp": DateTime.now().toIso8601String(),
    });
  }

  void _storeTemperature(double temp) {
    database.child("temperature_readings").push().set({
      "temperature_celsius": temp,
      "timestamp": DateTime.now().toIso8601String(),
    });
  }

  void _storePressure(double pressure) {
    database.child("pressure_readings").push().set({
      "pressure_hpa": pressure,
      "timestamp": DateTime.now().toIso8601String(),
    });
  }

  void _storeAltitude(double altitude) {
    database.child("altitude_readings").push().set({
      "altitude_meters": altitude,
      "timestamp": DateTime.now().toIso8601String(),
    });
  }

  Future<void> _saveSpO2ToPrefs(double spo2) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('spo2', spo2);
  }

  Future<void> _saveHeartRateToPrefs(int bpm) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('heart_rate', bpm);
  }

  Future<void> disconnect() async {
    await bluetooth.disconnect();
  }
}
