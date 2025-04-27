import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    } else {
      //widget.bluetoothService.disconnect();
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
      //widget.bluetoothService.disconnect();
    }
  }

  void _exportLogs() {
    // Placeholder logic
    print("Logs exported!");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Logs exported successfully!")),
    );
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
