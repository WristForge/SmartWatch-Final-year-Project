import 'package:flutter/material.dart';
import 'temperature_logs.dart';
import 'pressure_logs.dart';
import 'altitude_logs.dart';

class EnvironmentLogsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Environment Logs'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          LogCard(
            title: 'Temperature Logs',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => TemperatureLogsScreen()),
              );
            },
          ),
          SizedBox(height: 20),
          LogCard(
            title: 'Pressure Logs',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PressureLogsScreen()),
              );
            },
          ),
          SizedBox(height: 20),
          LogCard(
            title: 'Altitude Logs',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AltitudeLogsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class LogCard extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  LogCard({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}
