import 'package:flutter/material.dart';

class LogsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: Placeholder(), // Placeholder for logo
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
            child: Text(
              'Logs',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                LogFieldBox(
                  icon: Icons.favorite,
                  title: 'Heart Rate Logs',
                  onTap: () {
                    // Navigate to Heart Rate Logs
                  },
                ),
                SizedBox(height: 20),
                LogFieldBox(
                  icon: Icons.directions_walk,
                  title: 'Step Count Logs',
                  onTap: () {
                    // Navigate to Step Count Logs
                  },
                ),
                SizedBox(height: 20),
                LogFieldBox(
                  icon: Icons.security,
                  title: 'Attack Logs',
                  onTap: () {
                    // Navigate to Attack Logs
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LogFieldBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  LogFieldBox({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.0),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 30,
            ),
            SizedBox(width: 20),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white70,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
