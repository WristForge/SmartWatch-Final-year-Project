import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class HeartRateLogsScreen extends StatefulWidget {
  @override
  _HeartRateLogsScreenState createState() => _HeartRateLogsScreenState();
}

class _HeartRateLogsScreenState extends State<HeartRateLogsScreen> {
  final DatabaseReference _heartRateRef = FirebaseDatabase.instance
      .ref()
      .child('smartwatch_data')
      .child('heart_rate_readings');

  Map<String, int> _heartRateData = {};
  bool _hasInternetConnection = true;

  @override
  void initState() {
    super.initState();
    _fetchHeartRateData();
  }

  void _fetchHeartRateData() {
    _heartRateRef.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        Map<String, int> loadedData = {};
        data.forEach((key, value) {
          if (value is Map) {
            final bpm = value['bpm'];
            final timestamp = value['timestamp'];
            if (bpm != null && timestamp != null) {
              loadedData[timestamp.toString()] = bpm.toInt();
            }
          }
        });

        setState(() {
          _heartRateData = loadedData;
          _hasInternetConnection = true; // internet is working
        });
      } else {
        // No data found, but connection is fine
        setState(() {
          _heartRateData = {};
          _hasInternetConnection = true;
        });
      }
    }, onError: (error) {
      // If there is an error (likely no internet)
      setState(() {
        _hasInternetConnection = false;
      });
    });
  }

  double _calculateAverageHeartRate() {
    if (_heartRateData.isEmpty) return 0.0;
    int totalBpm = _heartRateData.values.reduce((a, b) => a + b);
    return totalBpm / _heartRateData.length;
  }

  @override
  Widget build(BuildContext context) {
    final sortedTimestamps = _heartRateData.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // newest first

    double averageHeartRate = _calculateAverageHeartRate();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Heart Rate Logs'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: !_hasInternetConnection
          ? Center(
              child: Text(
                'No Internet Connection.\nPlease check your connection.',
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            )
          : _heartRateData.isEmpty
              ? Center(
                  child: Text(
                    'No heart rate data available.',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : ListView.builder(
                  itemCount: sortedTimestamps.length + 1, // +1 for average card
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // Display Average Heart Rate first
                      return Card(
                        color: Colors.grey[850],
                        margin:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Average Heart Rate',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 16),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '${averageHeartRate.toStringAsFixed(1)} bpm',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      // Display each heart rate reading
                      final timestamp = sortedTimestamps[index - 1];
                      final bpm = _heartRateData[timestamp];
                      final formattedDate = DateFormat('yyyy-MM-dd – HH:mm')
                          .format(DateTime.parse(timestamp));

                      return ListTile(
                        title: Text(
                          'Heart Rate: $bpm bpm',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          formattedDate,
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }
                  },
                ),
    );
  }
}
