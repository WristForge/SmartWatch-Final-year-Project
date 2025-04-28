import 'package:flutter/material.dart';

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
          LogCard(title: 'Temperature Logs'),
          SizedBox(height: 20),
          LogCard(title: 'Pressure Logs'),
          SizedBox(height: 20),
          LogCard(title: 'Altitude Logs'),
        ],
      ),
    );
  }
}

class LogCard extends StatelessWidget {
  final String title;

  LogCard({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        title,
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }
}
