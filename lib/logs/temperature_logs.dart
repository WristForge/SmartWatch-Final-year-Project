import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fl_chart/fl_chart.dart';

class TemperatureLogsScreen extends StatefulWidget {
  @override
  _TemperatureLogsScreenState createState() => _TemperatureLogsScreenState();
}

class _TemperatureLogsScreenState extends State<TemperatureLogsScreen> {
  bool hasInternet = true;
  bool isLoading = true;
  String selectedView = 'Hours'; // default view
  Map<DateTime, double> temperatureData =
      {}; // map of DateTime to Temperature (Celsius)

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
      fetchTemperatureData();
    }
  }

  Future<void> fetchTemperatureData() async {
    final DatabaseReference ref =
        FirebaseDatabase.instance.ref('smartwatch_data/temperature_readings');
    final snapshot = await ref.get();

    if (snapshot.exists) {
      final Map data = snapshot.value as Map;
      Map<DateTime, double> parsedData = {};

      data.forEach((key, value) {
        final reading = value as Map;
        final timestamp = reading['timestamp'] as String;
        final temperature = reading['temperature_celcius'].toDouble();

        if (temperature != null) {
          DateTime parsedTimestamp = DateTime.parse(timestamp);
          parsedData[parsedTimestamp] = temperature.toDouble();
        }
      });

      setState(() {
        temperatureData = parsedData;
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
      spots.add(FlSpot(i.toDouble(), temperatureData[keys[i]]!));
    }
    return spots;
  }

  List<MapEntry<DateTime, double>> getFilteredData() {
    DateTime now = DateTime.now();
    List<MapEntry<DateTime, double>> filteredData = [];
    switch (selectedView) {
      case 'Hours':
        filteredData = temperatureData.entries.where((entry) {
          return entry.key.isAfter(now.subtract(Duration(hours: 24)));
        }).toList();
        break;
      case 'Days':
        filteredData = temperatureData.entries.where((entry) {
          return entry.key.isAfter(now.subtract(Duration(days: 7)));
        }).toList();
        break;
      case 'Weeks':
        filteredData = temperatureData.entries.where((entry) {
          return entry.key.isAfter(now.subtract(Duration(days: 30)));
        }).toList();
        break;
      case 'Years':
        filteredData = temperatureData.entries.where((entry) {
          return entry.key.isAfter(now.subtract(Duration(days: 365)));
        }).toList();
        break;
      default:
        break;
    }
    return filteredData;
  }

  double calculateAverageTemperature() {
    var filtered = getFilteredData();
    if (filtered.isEmpty) return 0;
    double total = 0;
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
        title: Text('Temperature Logs'),
        elevation: 0,
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : temperatureData.isEmpty
              ? Center(
                  child: Text(
                    'No Temperature Data Available.',
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
                                color: Colors.orangeAccent,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Average Temperature: ${calculateAverageTemperature().toStringAsFixed(1)}°C',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ],
                  ),
                ),
    );
  }
}
