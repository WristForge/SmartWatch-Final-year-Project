import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fl_chart/fl_chart.dart';

class SpO2LogsScreen extends StatefulWidget {
  @override
  _SpO2LogsScreenState createState() => _SpO2LogsScreenState();
}

class _SpO2LogsScreenState extends State<SpO2LogsScreen> {
  bool hasInternet = true;
  bool isLoading = true;
  String selectedView = 'Hours'; // default view
  Map<DateTime, double> spo2Data = {}; // map of DateTime to SpO2 percentage

  @override
  void initState() {
    super.initState();
    checkInternetAndFetchData();
  }

  Future<void> checkInternetAndFetchData() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        hasInternet = false;
      });
      Timer(Duration(seconds: 5), () {
        Navigator.pop(context); // Go back after 5 seconds
      });
    } else {
      fetchSpO2Data();
    }
  }

  Future<void> fetchSpO2Data() async {
    final DatabaseReference ref =
        FirebaseDatabase.instance.ref('smartwatch_data/spo2_readings');
    final snapshot = await ref.get();

    if (snapshot.exists) {
      final Map data = snapshot.value as Map;
      Map<DateTime, double> parsedData = {}; // Use DateTime as the key

      // Loop through each entry in spo2_readings
      data.forEach((key, value) {
        final reading = value as Map;
        final timestamp = reading['timestamp'] as String;
        final spo2 = reading['spo2_percentage'].toDouble();

        // Parse the timestamp to DateTime
        DateTime parsedTimestamp = DateTime.parse(timestamp);

        // Store the spo2 percentage with the parsed timestamp as the key
        parsedData[parsedTimestamp] = spo2;
      });

      setState(() {
        spo2Data = parsedData;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  List<FlSpot> generateGraphSpots() {
    List<FlSpot> spots = [];
    List<DateTime> keys = spo2Data.keys.toList();
    keys.sort(); // Sort the DateTime keys in ascending order

    // Convert data to graph format
    for (int i = 0; i < keys.length; i++) {
      spots.add(FlSpot(i.toDouble(), spo2Data[keys[i]]!));
    }
    return spots;
  }

  List<MapEntry<DateTime, double>> getFilteredData() {
    DateTime now = DateTime.now();
    List<MapEntry<DateTime, double>> filteredData = [];
    switch (selectedView) {
      case 'Hours':
        filteredData = spo2Data.entries.where((entry) {
          return entry.key.isAfter(now.subtract(Duration(hours: 24)));
        }).toList();
        break;
      case 'Days':
        filteredData = spo2Data.entries.where((entry) {
          return entry.key.isAfter(now.subtract(Duration(days: 7)));
        }).toList();
        break;
      case 'Weeks':
        filteredData = spo2Data.entries.where((entry) {
          return entry.key.isAfter(now.subtract(Duration(days: 30)));
        }).toList();
        break;
      case 'Years':
        filteredData = spo2Data.entries.where((entry) {
          return entry.key.isAfter(now.subtract(Duration(days: 365)));
        }).toList();
        break;
      default:
        break;
    }
    return filteredData;
  }

  @override
  Widget build(BuildContext context) {
    if (!hasInternet) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'No Internet Connection.\nPlease connect to the internet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('SpO₂ Logs'),
        elevation: 0,
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  DropdownButton<String>(
                    value: selectedView,
                    dropdownColor: Colors.grey[900],
                    style: TextStyle(color: Colors.white),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedView = newValue!;
                      });
                    },
                    items: ['Hours', 'Days', 'Weeks', 'Years']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: LineChart(
                      LineChartData(
                        backgroundColor: Colors.grey[850],
                        gridData: FlGridData(show: true),
                        borderData: FlBorderData(show: true),
                        titlesData: FlTitlesData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: generateGraphSpots(),
                            isCurved: true,
                            barWidth: 3,
                            color: Colors.redAccent,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Average SpO₂: ${calculateAverageSpO2().toStringAsFixed(1)}%',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ],
              ),
            ),
    );
  }

  double calculateAverageSpO2() {
    var filtered = getFilteredData();
    if (filtered.isEmpty) return 0;
    double total = 0;
    filtered.forEach((entry) {
      total += entry.value;
    });
    return total / filtered.length;
  }
}
