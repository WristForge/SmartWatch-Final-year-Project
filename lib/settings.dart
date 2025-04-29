import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'bt_service.dart'; // Adjust path if needed

class SettingsScreen extends StatefulWidget {
  final BluetoothService bluetoothService;

  SettingsScreen({required this.bluetoothService});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool stepNotifications = true;
  bool heartRateNotifications = true;
  bool isBluetoothOn = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      stepNotifications = prefs.getBool('stepNotifications') ?? true;
      heartRateNotifications = prefs.getBool('heartRateNotifications') ?? true;
      isBluetoothOn = prefs.getBool('bluetooth') ?? true;
    });

    if (isBluetoothOn) {
      widget.bluetoothService.scanAndConnect();
    }
  }

  Future<void> _updatePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _clearStepCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('lastStepCount');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Step count reset")),
    );
  }

  void _toggleBluetooth(bool value) {
    setState(() => isBluetoothOn = value);
    _updatePreference('bluetooth', value);

    if (value) {
      widget.bluetoothService.scanAndConnect();
    } else {
      widget.bluetoothService.disconnect();
    }
  }

  void _exportLogs() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildExportTile(
                  Icons.bloodtype, 'Export SpO₂ Logs', 'spo2_readings'),
              _buildExportTile(Icons.favorite, 'Export Heart Rate Logs',
                  'heart_rate_readings'),
              _buildExportTile(Icons.directions_walk, 'Export Step Count Logs',
                  'step_counts'),
              _buildExportTile(Icons.thermostat, 'Export Temperature Logs',
                  'temperature_readings'),
              _buildExportTile(
                  Icons.compress, 'Export Pressure Logs', 'pressure_readings'),
              _buildExportTile(
                  Icons.landscape, 'Export Altitude Logs', 'altitude_readings'),
            ],
          ),
        );
      },
    );
  }

  ListTile _buildExportTile(IconData icon, String title, String logType) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.pop(context);
        _exportSpecificLogs(logType);
      },
    );
  }

  Future<void> _exportSpecificLogs(String logType) async {
    try {
      final databaseRef =
          FirebaseDatabase.instance.ref('smartwatch_data/$logType');
      final snapshot = await databaseRef.get();

      if (!snapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No logs available to export')),
        );
        return;
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      final logBuffer = StringBuffer();

      data.forEach((key, value) {
        final reading = value as Map;

        if (logType == 'spo2_readings') {
          final timestamp = reading['timestamp'];
          final spo2 = reading['spo2_percentage'];
          logBuffer.writeln('Timestamp: $timestamp, SpO₂: $spo2%');
        } else if (logType == 'heart_rate_readings') {
          final timestamp = reading['timestamp'];
          final heartRate = reading['heart_rate'];
          logBuffer
              .writeln('Timestamp: $timestamp, Heart Rate: $heartRate bpm');
        } else if (logType == 'step_counts') {
          final steps = reading['steps'];
          final date = key;
          logBuffer.writeln('Date: $date, Steps: $steps');
        } else if (logType == 'temperature_readings') {
          final timestamp = reading['timestamp'];
          final temperature = reading['temperature'];
          logBuffer
              .writeln('Timestamp: $timestamp, Temperature: $temperature °C');
        } else if (logType == 'pressure_readings') {
          final timestamp = reading['timestamp'];
          final pressure = reading['pressure'];
          logBuffer.writeln('Timestamp: $timestamp, Pressure: $pressure hPa');
        } else if (logType == 'altitude_readings') {
          final timestamp = reading['timestamp'];
          final altitude = reading['altitude'];
          logBuffer
              .writeln('Timestamp: $timestamp, Altitude: $altitude meters');
        }
      });

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$logType.txt');
      await file.writeAsString(logBuffer.toString());

      await Share.shareXFiles([XFile(file.path)],
          text: 'Here are the exported logs: $logType');
    } catch (e) {
      print('Error exporting logs: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export logs')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text('Step Count Notifications',
                style: TextStyle(color: Colors.white)),
            value: stepNotifications,
            onChanged: (value) {
              setState(() => stepNotifications = value);
              _updatePreference('stepNotifications', value);
            },
          ),
          SwitchListTile(
            title: Text('Heart Rate Alerts',
                style: TextStyle(color: Colors.white)),
            value: heartRateNotifications,
            onChanged: (value) {
              setState(() => heartRateNotifications = value);
              _updatePreference('heartRateNotifications', value);
            },
          ),
          SwitchListTile(
            title: Text('Bluetooth', style: TextStyle(color: Colors.white)),
            value: isBluetoothOn,
            onChanged: _toggleBluetooth,
          ),
          ListTile(
            title: Text('Export Logs', style: TextStyle(color: Colors.white)),
            leading: Icon(Icons.download, color: Colors.white),
            onTap: _exportLogs,
          ),
          ListTile(
            title: Text('Reset Step Count',
                style: TextStyle(color: Colors.redAccent)),
            onTap: _clearStepCount,
          ),
          Divider(color: Colors.white24),
          ListTile(
            title: Text('App Version 1.0.0',
                style: TextStyle(color: Colors.white70)),
            subtitle: Text('Wrist Forge - Final Year Project',
                style: TextStyle(color: Colors.white30)),
          ),
        ],
      ),
    );
  }
}
