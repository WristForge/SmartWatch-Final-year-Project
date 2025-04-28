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
  bool isDarkMode = true;
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
      isDarkMode = prefs.getBool('darkMode') ?? true;
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

  void _toggleDarkMode(bool value) {
    setState(() => isDarkMode = value);
    _updatePreference('darkMode', value);
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
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.bloodtype,
                    color: isDarkMode ? Colors.white : Colors.black),
                title: Text('Export SpO₂ Logs',
                    style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black)),
                onTap: () {
                  Navigator.pop(context);
                  _exportSpecificLogs('spo2_readings');
                },
              ),
              ListTile(
                leading: Icon(Icons.favorite,
                    color: isDarkMode ? Colors.white : Colors.black),
                title: Text('Export Heart Rate Logs',
                    style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black)),
                onTap: () {
                  Navigator.pop(context);
                  _exportSpecificLogs('heart_rate_readings');
                },
              ),
              ListTile(
                leading: Icon(Icons.directions_walk,
                    color: isDarkMode ? Colors.white : Colors.black),
                title: Text('Export Step Count Logs',
                    style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black)),
                onTap: () {
                  Navigator.pop(context);
                  _exportSpecificLogs('step_counts');
                },
              ),
              ListTile(
                leading: Icon(Icons.thermostat,
                    color: isDarkMode ? Colors.white : Colors.black),
                title: Text('Export Temperature Logs',
                    style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black)),
                onTap: () {
                  Navigator.pop(context);
                  _exportSpecificLogs('temperature_readings');
                },
              ),
              ListTile(
                leading: Icon(Icons.compress,
                    color: isDarkMode ? Colors.white : Colors.black),
                title: Text('Export Pressure Logs',
                    style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black)),
                onTap: () {
                  Navigator.pop(context);
                  _exportSpecificLogs('pressure_readings');
                },
              ),
              ListTile(
                leading: Icon(Icons.landscape,
                    color: isDarkMode ? Colors.white : Colors.black),
                title: Text('Export Altitude Logs',
                    style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black)),
                onTap: () {
                  Navigator.pop(context);
                  _exportSpecificLogs('altitude_readings');
                },
              ),
            ],
          ),
        );
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
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
        titleTextStyle: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
          fontSize: 20,
        ),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text('Step Count Notifications',
                style:
                    TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
            value: stepNotifications,
            onChanged: (value) {
              setState(() => stepNotifications = value);
              _updatePreference('stepNotifications', value);
            },
          ),
          SwitchListTile(
            title: Text('Heart Rate Alerts',
                style:
                    TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
            value: heartRateNotifications,
            onChanged: (value) {
              setState(() => heartRateNotifications = value);
              _updatePreference('heartRateNotifications', value);
            },
          ),
          SwitchListTile(
            title: Text('Bluetooth',
                style:
                    TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
            value: isBluetoothOn,
            onChanged: _toggleBluetooth,
          ),
          SwitchListTile(
            title: Text('Dark Mode',
                style:
                    TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
            value: isDarkMode,
            onChanged: _toggleDarkMode,
          ),
          ListTile(
            title: Text('Export Logs',
                style:
                    TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
            leading: Icon(Icons.download,
                color: isDarkMode ? Colors.white : Colors.black),
            onTap: _exportLogs,
          ),
          ListTile(
            title: Text('Reset Step Count',
                style: TextStyle(color: Colors.redAccent)),
            onTap: _clearStepCount,
          ),
          Divider(color: isDarkMode ? Colors.white24 : Colors.black26),
          ListTile(
            title: Text('App Version 1.0.0',
                style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54)),
            subtitle: Text('Wrist Forge - Final Year Project',
                style: TextStyle(
                    color: isDarkMode ? Colors.white30 : Colors.black26)),
          ),
        ],
      ),
    );
  }
}
