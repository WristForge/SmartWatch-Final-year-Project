/*import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'logs.dart';
import 'bt_service.dart';
import 'settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final BluetoothService bluetoothService = BluetoothService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainScreen(bluetoothService: bluetoothService),
    );
  }
}

class MainScreen extends StatefulWidget {
  final BluetoothService bluetoothService;
  MainScreen({required this.bluetoothService});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  double? temperature;
  double? pressure;
  double? altitude;
  int? heartRate;
  double? spo2; // SpO2 as double
  int? stepCount;

  @override
  void initState() {
    super.initState();

    _loadSavedData(); // Load all saved sensor data

    Future.delayed(Duration.zero, () {
      widget.bluetoothService.scanAndConnect();

      widget.bluetoothService.onTemperatureReceived = (double temp) {
        setState(() {
          temperature = temp;
        });
        _saveTemperature(temp);
      };

      widget.bluetoothService.onPressureReceived = (double press) {
        setState(() {
          pressure = press;
        });
        _savePressure(press);
      };

      widget.bluetoothService.onAltitudeReceived = (double alt) {
        setState(() {
          altitude = alt;
        });
        _saveAltitude(alt);
      };

      widget.bluetoothService.onHeartRateReceived = (int hr) {
        setState(() {
          heartRate = hr;
        });
        _saveHeartRate(hr);
      };

      widget.bluetoothService.onSpO2Received = (double oxygen) {
        setState(() {
          spo2 = oxygen; // Update SpO2 as double
        });
        _saveSpO2(oxygen); // Save SpO2 as double
      };

      widget.bluetoothService.onStepCountReceived = (int steps) {
        setState(() {
          stepCount = steps;
        });
        _saveStepCount(steps);
      };
    });
  }

  @override
  void dispose() {
    widget.bluetoothService.disconnect();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _loadSavedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      temperature = prefs.getDouble('temperature');
      pressure = prefs.getDouble('pressure');
      altitude = prefs.getDouble('altitude');
      heartRate = prefs.getInt('heartRate');
      spo2 = prefs.getDouble('spo2'); // Load SpO2 as double
      stepCount = prefs.getInt('stepCount');
    });
  }

  Future<void> _saveTemperature(double temp) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('temperature', temp);
  }

  Future<void> _savePressure(double press) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('pressure', press);
  }

  Future<void> _saveAltitude(double alt) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('altitude', alt);
  }

  Future<void> _saveHeartRate(int hr) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('heartRate', hr);
  }

  Future<void> _saveSpO2(double oxygen) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('spo2', oxygen); // Save SpO2 as double
  }

  Future<void> _saveStepCount(int steps) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('stepCount', steps);
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> _pages = [
      HomeScreen(
        temperature: temperature,
        pressure: pressure,
        altitude: altitude,
        heartRate: heartRate,
        spo2: spo2,
        stepCount: stepCount,
      ),
      LogsScreen(),
      SettingsScreen(bluetoothService: widget.bluetoothService),
    ];

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.white70,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Logs'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final double? temperature;
  final double? pressure;
  final double? altitude;
  final int? heartRate;
  final double? spo2; // SpO2 as double
  final int? stepCount;

  HomeScreen({
    required this.temperature,
    required this.pressure,
    required this.altitude,
    required this.heartRate,
    required this.spo2,
    required this.stepCount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Placeholder(), // You can replace this with your app logo
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {},
          ),
        ],
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '12:45 PM', // You can update this dynamically if needed
              style: TextStyle(
                fontSize: 60,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Monday, December 16', // You can update this dynamically too
              style: TextStyle(fontSize: 18, color: Colors.black),
            ),
            SizedBox(height: 40),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: [
                StatCard(
                  icon: Icons.thermostat,
                  value: temperature != null
                      ? '${temperature!.toStringAsFixed(1)} °C'
                      : '-- °C',
                ),
                StatCard(
                  icon: Icons.cloud,
                  value: pressure != null
                      ? '${pressure!.toStringAsFixed(1)} hPa'
                      : '-- hPa',
                ),
                StatCard(
                  icon: Icons.height,
                  value: altitude != null
                      ? '${altitude!.toStringAsFixed(1)} m'
                      : '-- m',
                ),
                StatCard(
                  icon: Icons.favorite,
                  value: heartRate != null ? '$heartRate bpm' : '-- bpm',
                ),
                StatCard(
                  icon: Icons.bloodtype,
                  value: spo2 != null
                      ? '${spo2!.toStringAsFixed(1)} %'
                      : '-- %', // Display SpO2 as double
                ),
                StatCard(
                  icon: Icons.directions_walk,
                  value: stepCount != null ? '$stepCount steps' : '-- steps',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final String value;

  StatCard({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 30),
          SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 20, color: Colors.white)),
        ],
      ),
    );
  }
}*/

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'logs.dart';
import 'bt_service.dart'; // Import BluetoothService class
import 'settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final BluetoothService bluetoothService = BluetoothService();

  @override
  Widget build(BuildContext context) {
    // Start the Bluetooth service when the app initializes
    bluetoothService
        .startBluetoothService(); // Ensure service starts on app launch

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainScreen(bluetoothService: bluetoothService),
    );
  }
}

class MainScreen extends StatefulWidget {
  final BluetoothService bluetoothService;

  MainScreen({required this.bluetoothService});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  double? temperature;
  double? pressure;
  double? altitude;
  int? heartRate;
  double? spo2; // SpO2 as double
  int? stepCount;

  @override
  void initState() {
    super.initState();

    _loadSavedData(); // Load all saved sensor data

    Future.delayed(Duration.zero, () {
      widget.bluetoothService
          .scanAndConnect(); // Start scanning and connecting to Bluetooth device

      // Set up data reception handlers
      widget.bluetoothService.onTemperatureReceived = (double temp) {
        setState(() {
          temperature = temp;
        });
        _saveTemperature(temp);
      };

      widget.bluetoothService.onPressureReceived = (double press) {
        setState(() {
          pressure = press;
        });
        _savePressure(press);
      };

      widget.bluetoothService.onAltitudeReceived = (double alt) {
        setState(() {
          altitude = alt;
        });
        _saveAltitude(alt);
      };

      widget.bluetoothService.onHeartRateReceived = (int hr) {
        setState(() {
          heartRate = hr;
        });
        _saveHeartRate(hr);
      };

      widget.bluetoothService.onSpO2Received = (double oxygen) {
        setState(() {
          spo2 = oxygen; // Update SpO2 as double
        });
        _saveSpO2(oxygen); // Save SpO2 as double
      };

      widget.bluetoothService.onStepCountReceived = (int steps) {
        setState(() {
          stepCount = steps;
        });
        _saveStepCount(steps);
      };
    });
  }

  @override
  void dispose() {
    widget.bluetoothService.disconnect();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _loadSavedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      temperature = prefs.getDouble('temperature');
      pressure = prefs.getDouble('pressure');
      altitude = prefs.getDouble('altitude');
      heartRate = prefs.getInt('heartRate');
      spo2 = prefs.getDouble('spo2'); // Load SpO2 as double
      stepCount = prefs.getInt('stepCount');
    });
  }

  Future<void> _saveTemperature(double temp) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('temperature', temp);
  }

  Future<void> _savePressure(double press) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('pressure', press);
  }

  Future<void> _saveAltitude(double alt) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('altitude', alt);
  }

  Future<void> _saveHeartRate(int hr) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('heartRate', hr);
  }

  Future<void> _saveSpO2(double oxygen) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('spo2', oxygen); // Save SpO2 as double
  }

  Future<void> _saveStepCount(int steps) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('stepCount', steps);
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> _pages = [
      HomeScreen(
        temperature: temperature,
        pressure: pressure,
        altitude: altitude,
        heartRate: heartRate,
        spo2: spo2,
        stepCount: stepCount,
      ),
      LogsScreen(),
      SettingsScreen(bluetoothService: widget.bluetoothService),
    ];

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.white70,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Logs'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final double? temperature;
  final double? pressure;
  final double? altitude;
  final int? heartRate;
  final double? spo2; // SpO2 as double
  final int? stepCount;

  HomeScreen({
    required this.temperature,
    required this.pressure,
    required this.altitude,
    required this.heartRate,
    required this.spo2,
    required this.stepCount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Placeholder(), // You can replace this with your app logo
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {},
          ),
        ],
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '12:45 PM', // You can update this dynamically if needed
              style: TextStyle(
                fontSize: 60,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Monday, December 16', // You can update this dynamically too
              style: TextStyle(fontSize: 18, color: Colors.black),
            ),
            SizedBox(height: 40),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: [
                StatCard(
                  icon: Icons.thermostat,
                  value: temperature != null
                      ? '${temperature!.toStringAsFixed(1)} °C'
                      : '-- °C',
                ),
                StatCard(
                  icon: Icons.cloud,
                  value: pressure != null
                      ? '${pressure!.toStringAsFixed(1)} hPa'
                      : '-- hPa',
                ),
                StatCard(
                  icon: Icons.height,
                  value: altitude != null
                      ? '${altitude!.toStringAsFixed(1)} m'
                      : '-- m',
                ),
                StatCard(
                  icon: Icons.favorite,
                  value: heartRate != null ? '$heartRate bpm' : '-- bpm',
                ),
                StatCard(
                  icon: Icons.bloodtype,
                  value: spo2 != null
                      ? '${spo2!.toStringAsFixed(1)} %'
                      : '-- %', // Display SpO2 as double
                ),
                StatCard(
                  icon: Icons.directions_walk,
                  value: stepCount != null ? '$stepCount steps' : '-- steps',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final String value;

  StatCard({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 30),
          SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 20, color: Colors.white)),
        ],
      ),
    );
  }
}
