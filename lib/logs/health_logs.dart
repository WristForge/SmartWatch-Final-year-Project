import 'package:flutter/material.dart';
import 'spo2_log.dart';
import 'heartRate_log.dart';

class HealthLogsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Health Logs'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          LogCard(
            title: 'Heart Rate Logs',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HeartRateLogsScreen()),
              );
            },
          ),
          SizedBox(height: 20),
          LogCard(
            title: 'SpO₂ (Oxygen) Logs',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SpO2LogsScreen()),
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
        child: Text(
          title,
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }
}
