import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class BluetoothService {
  final FlutterBluetoothSerial bluetooth = FlutterBluetoothSerial.instance;
  BluetoothConnection? connection;
  final DatabaseReference database =
      FirebaseDatabase.instance.ref("smartwatch_data");

  String _buffer = "";
  int _currentHourlyStepCount = 0;
  String _currentHour = _getCurrentHourString();

  // Callbacks for UI update (can be used to notify UI when the app is in the foreground)
  Function(int)? onStepCountReceived;
  Function(int)? onHeartRateReceived;
  Function(double)? onSpO2Received;
  Function(double)? onTemperatureReceived;
  Function(double)? onPressureReceived;
  Function(double)? onAltitudeReceived;

  static String _getCurrentHourString() {
    final now = DateTime.now();
    return DateFormat('yyyy-MM-dd_HH').format(now); // Example: "2025-04-27_14"
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

    List<String> lines = _buffer.split('\n');
    _buffer = lines.removeLast(); // Save incomplete line

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
        double spo2 = double.parse(spo2String); // Parse as double

        _storeSpO2(spo2);

        if (onSpO2Received != null) {
          onSpO2Received!(spo2);
        }

        _saveSpO2ToPrefs(spo2); // Save SpO2 as double in SharedPreferences
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
      _pushCurrentStepCount(); // Push last hour's data
      _currentHour = nowHour;
      _currentHourlyStepCount = 0;
    }

    _currentHourlyStepCount += steps;
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
      "spo2_percentage": spo2, // Store as double
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

  // Save SpO2 to SharedPreferences as double
  Future<void> _saveSpO2ToPrefs(double spo2) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('spo2', spo2); // Save SpO2 as double
  }

  // Save Heart Rate to SharedPreferences as int
  Future<void> _saveHeartRateToPrefs(int bpm) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('heart_rate', bpm);
  }

  void disconnect() {
    if (connection != null && connection!.isConnected) {
      connection?.finish();
      print("🔌 Bluetooth connection finished");
    }
  }

  void onStartService(ServiceInstance service) {
    final bluetoothService = BluetoothService();
    bluetoothService.scanAndConnect();
  }

  Future<void> startBluetoothService() async {
    // Start background service
    final service = FlutterBackgroundService();
    service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStartService,
        autoStart: true,
        isForegroundMode: true, // <-- Added this line
        initialNotificationContent: 'Preparing...',
        initialNotificationTitle: 'Smartwatch Bluetooth Service',
        notificationChannelId: 'smartwatch_bluetooth_service_channel',
        foregroundServiceNotificationId: 123456,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground:
            onStartService, // This is for when the app is in the foreground
      ),
    );
    service.startService();
  }
}
