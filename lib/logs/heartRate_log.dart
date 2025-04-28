import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fl_chart/fl_chart.dart';

class HeartRateLogsScreen extends StatefulWidget {
  @override
  _HeartRateLogsScreenState createState() => _HeartRateLogsScreenState();
}

class _HeartRateLogsScreenState extends State<HeartRateLogsScreen> {
  bool hasInternet = true;
  bool isLoading = true;
  String selectedView = 'Hours'; // default view
  Map<DateTime, int> heartRateData = {}; // map of DateTime to BPM

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
      fetchHeartRateData();
    }
  }

  Future<void> fetchHeartRateData() async {
    final DatabaseReference ref =
        FirebaseDatabase.instance.ref('smartwatch_data/heart_rate_readings');
    final snapshot = await ref.get();

    if (snapshot.exists) {
      final Map data = snapshot.value as Map;
      Map<DateTime, int> parsedData = {};

      data.forEach((key, value) {
        final reading = value as Map;
        final timestamp = reading['timestamp'] as String;
        final bpm = reading['bpm'];

        if (bpm != null) {
          DateTime parsedTimestamp = DateTime.parse(timestamp);
          parsedData[parsedTimestamp] = bpm.toInt();
        }
      });

      setState(() {
        heartRateData = parsedData;
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
    List<DateTime> keys = getFilteredData().map((e) => e.key).toList();
    keys.sort();

    for (int i = 0; i < keys.length; i++) {
      spots.add(FlSpot(i.toDouble(), heartRateData[keys[i]]!.toDouble()));
    }
    return spots;
  }

  List<MapEntry<DateTime, int>> getFilteredData() {
    DateTime now = DateTime.now();
    List<MapEntry<DateTime, int>> filteredData = [];
    switch (selectedView) {
      case 'Hours':
        filteredData = heartRateData.entries.where((entry) {
          return entry.key.isAfter(now.subtract(Duration(hours: 24)));
        }).toList();
        break;
      case 'Days':
        filteredData = heartRateData.entries.where((entry) {
          return entry.key.isAfter(now.subtract(Duration(days: 7)));
        }).toList();
        break;
      case 'Weeks':
        filteredData = heartRateData.entries.where((entry) {
          return entry.key.isAfter(now.subtract(Duration(days: 30)));
        }).toList();
        break;
      case 'Years':
        filteredData = heartRateData.entries.where((entry) {
          return entry.key.isAfter(now.subtract(Duration(days: 365)));
        }).toList();
        break;
      default:
        break;
    }
    return filteredData;
  }

  double calculateAverageHeartRate() {
    var filtered = getFilteredData();
    if (filtered.isEmpty) return 0;
    int total = 0;
    filtered.forEach((entry) {
      total += entry.value;
    });
    return total / filtered.length;
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
        title: Text('Heart Rate Logs'),
        elevation: 0,
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : heartRateData.isEmpty
              ? Center(
                  child: Text(
                    'No Heart Rate Data Available.',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
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
                        'Average Heart Rate: ${calculateAverageHeartRate().toStringAsFixed(1)} bpm',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ],
                  ),
                ),
    );
  }
}
