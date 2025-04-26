import 'package:flutter/material.dart';
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
  int stepCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStepCount();

    Future.delayed(Duration.zero, () {
      widget.bluetoothService.scanAndConnect();
      widget.bluetoothService.onStepCountReceived = (int steps) {
        _saveStepCount(steps);
        setState(() {
          stepCount = steps;
        });
      };
    });
  }

  void _loadStepCount() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSteps = prefs.getInt('lastStepCount') ?? 0;
    setState(() {
      stepCount = savedSteps;
    });
  }

  void _saveStepCount(int steps) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('lastStepCount', steps);
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

  @override
  Widget build(BuildContext context) {
    List<Widget> _pages = [
      HomeScreen(stepCount: stepCount),
      LogsScreen(),
      SettingsScreen(
          bluetoothService:
              widget.bluetoothService), // ✅ Now uses the full-featured screen
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
  final int stepCount;

  HomeScreen({required this.stepCount});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Placeholder(),
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
              '12:45 PM',
              style: TextStyle(
                  fontSize: 60,
                  color: Colors.black,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Monday, December 16',
              style: TextStyle(fontSize: 18, color: Colors.black),
            ),
            SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StatCard(icon: Icons.battery_full, value: '85%'),
                SizedBox(width: 20),
                StatCard(icon: Icons.directions_walk, value: '$stepCount'),
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
        children: [
          Icon(icon, color: Colors.white, size: 30),
          SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 22, color: Colors.white)),
        ],
      ),
    );
  }
}
