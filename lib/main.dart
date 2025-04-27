import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'logs.dart';
import 'bt_service.dart';
import 'settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize Background Service
  await initializeService();

  // Start Bluetooth Service once at app launch
  BluetoothService bluetoothService = BluetoothService();
  await bluetoothService
      .startBluetoothService(); // Make sure this is awaited if needed

  runApp(MyApp(bluetoothService: bluetoothService));
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'Wrist Forge Running',
      initialNotificationContent: 'Monitoring Bluetooth data...',
    ),
    iosConfiguration: IosConfiguration(
      onForeground: onStart,
      onBackground: (service) => false,
    ),
  );

  await service.startService();
}

// This is what runs in background
@pragma('vm:entry-point')
void onStart(ServiceInstance service) {
  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // You can periodically do tasks here (e.g., reconnect Bluetooth if needed)
}

class MyApp extends StatelessWidget {
  final BluetoothService bluetoothService;

  const MyApp({required this.bluetoothService, Key? key}) : super(key: key);

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

  const MainScreen({required this.bluetoothService, Key? key})
      : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  double? temperature;
  double? pressure;
  double? altitude;
  int? heartRate;
  double? spo2;
  int? stepCount;

  @override
  void initState() {
    super.initState();
    _loadSavedData();

    Future.delayed(Duration.zero, () async {
      await _connectBluetooth();
    });
  }

  Future<void> _connectBluetooth() async {
    try {
      bool isConnected = await widget.bluetoothService.scanAndConnect();
      if (isConnected) {
        print("✅ Bluetooth connected successfully.");

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
            spo2 = oxygen;
          });
          _saveSpO2(oxygen);
        };

        widget.bluetoothService.onStepCountReceived = (int steps) {
          setState(() {
            stepCount = steps;
          });
          _saveStepCount(steps);
        };
      } else {
        print("⚠️ Failed to connect to Bluetooth device.");
      }
    } catch (e) {
      print("❌ Error connecting to Bluetooth: $e");
    }
  }

  @override
  void dispose() {
    // widget.bluetoothService.disconnect();
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
      spo2 = prefs.getDouble('spo2');
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
    await prefs.setDouble('spo2', oxygen);
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
        items: const [
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
