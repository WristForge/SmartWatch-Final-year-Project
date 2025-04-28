import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fl_chart/fl_chart.dart';

class StepLogsScreen extends StatefulWidget {
  @override
  _StepLogsScreenState createState() => _StepLogsScreenState();
}

class _StepLogsScreenState extends State<StepLogsScreen> {
  bool hasInternet = true;
  bool isLoading = true;
  String selectedView = 'Hours'; // default view
  Map<DateTime, int> stepData = {}; // map of DateTime to steps

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
      fetchStepData();
    }
  }

  Future<void> fetchStepData() async {
    final DatabaseReference ref =
        FirebaseDatabase.instance.ref('smartwatch_data/step_counts');
    final snapshot = await ref.get();

    if (snapshot.exists) {
      final Map data = snapshot.value as Map;
      Map<DateTime, int> parsedData = {}; // Use DateTime as the key

      // Loop through each entry in step_counts
      data.forEach((key, value) {
        final stepData = value as Map;
        final timestamp = stepData['timestamp'] as String;
        final stepCount = stepData['step_count'] as int;

        // Parse the timestamp to DateTime
        DateTime parsedTimestamp = DateTime.parse(timestamp);

        // Store the step count with the parsed timestamp as the key
        parsedData[parsedTimestamp] = stepCount;
      });

      setState(() {
        stepData = parsedData; // Set the parsed data
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
    List<DateTime> keys = stepData.keys.toList();
    keys.sort(); // Sort the DateTime keys in ascending order

    // Convert data to graph format
    for (int i = 0; i < keys.length; i++) {
      spots.add(FlSpot(i.toDouble(), stepData[keys[i]]!.toDouble()));
    }
    return spots;
  }

  List<MapEntry<DateTime, int>> getFilteredData() {
    DateTime now = DateTime.now();
    List<MapEntry<DateTime, int>> filteredData = [];
    switch (selectedView) {
      case 'Hours':
        filteredData = stepData.entries.where((entry) {
          return entry.key.isAfter(now.subtract(Duration(hours: 24)));
        }).toList();
        break;
      case 'Days':
        filteredData = stepData.entries.where((entry) {
          return entry.key.isAfter(now.subtract(Duration(days: 7)));
        }).toList();
        break;
      case 'Weeks':
        filteredData = stepData.entries.where((entry) {
          return entry.key.isAfter(now.subtract(Duration(days: 30)));
        }).toList();
        break;
      case 'Years':
        filteredData = stepData.entries.where((entry) {
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
        title: Text('Step Count Logs'),
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
                            color: Colors.cyan,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Total Steps: ${calculateTotalSteps()}',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ],
              ),
            ),
    );
  }

  int calculateTotalSteps() {
    int total = 0;
    getFilteredData().forEach((entry) {
      total += entry.value;
    });
    return total;
  }
}
