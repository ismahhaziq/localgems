import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class PlaceDescription extends StatelessWidget {
  final double distance;
  final Map<String, dynamic> hours;
  final Map<String, dynamic> placeData;

  PlaceDescription({
    required this.distance,
    required this.hours,
    required this.placeData,
  });

  @override
  Widget build(BuildContext context) {
    var nextOpening = getNextOpeningHour(hours);
    String nextOpeningTime = nextOpening['time'] ?? '';
    String nextOpeningDay = nextOpening['day'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: Color(0xFF7472E0)),
                    SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${distance.toStringAsFixed(2)} km from'),
                        Text('your location'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            Spacer(),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: isOpenNow(hours) ? Colors.green : Colors.red,
                ),
                SizedBox(width: 4),
                Container(
                  child: isOpenNow(hours)
                      ? Text(
                          'Open',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : _hasValidHours(hours)
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Closed',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '(Open $nextOpeningTime on $nextOpeningDay)',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'Closed',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                ),
              ],
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              margin: const EdgeInsets.only(left: 26.0),
              child: Row(
                children: [
                  Text(
                    'City: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(placeData['address']['city']),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                _launchMaps(
                  placeData['selectedLocation'].latitude,
                  placeData['selectedLocation'].longitude,
                );
              },
              child: Text(
                'View on Google Maps',
                style: TextStyle(
                  decoration: TextDecoration.underline,
                  fontSize: 13,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        Divider(height: 32, thickness: 1),
        Text(
          'Description',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 15),
        Text(
          placeData['description'],
          style: TextStyle(fontSize: 16),
        ),
        Divider(height: 32, thickness: 1),
        Text(
          'Hours of Operation',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        _buildHoursOfOperation(hours),
      ],
    );
  }

  bool isOpenNow(Map<String, dynamic> hours) {
    DateTime now = DateTime.now();
    String day = DateFormat('EEEE').format(now);

    if (hours.containsKey(day)) {
      Map<String, dynamic> dayHours = hours[day];

      if (dayHours['closed'] == true) {
        return false;
      }

      if (dayHours['allDay'] == true) {
        return true;
      }

      TimeOfDay? open = _parseTime(dayHours['open']);
      TimeOfDay? close = _parseTime(dayHours['close']);

      if (open != null && close != null) {
        DateTime openDateTime =
            DateTime(now.year, now.month, now.day, open.hour, open.minute);
        DateTime closeDateTime =
            DateTime(now.year, now.month, now.day, close.hour, close.minute);

        if (now.isAfter(openDateTime) && now.isBefore(closeDateTime)) {
          return true;
        }
      }
    }

    return false;
  }

  bool _hasValidHours(Map<String, dynamic> hours) {
    List<String> daysOfWeek = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    for (var day in daysOfWeek) {
      if (hours.containsKey(day)) {
        Map<String, dynamic> dayHours = hours[day];
        if (dayHours['open'] != null && dayHours['close'] != null) {
          return true;
        }
      }
    }
    return false;
  }

  TimeOfDay? _parseTime(String? time) {
    if (time == null || time.isEmpty) return null;
    try {
      final format = DateFormat.Hm(); // 24-hour format
      DateTime dateTime = format.parse(time);
      return TimeOfDay.fromDateTime(dateTime);
    } catch (e) {
      print("Error parsing time: $e");
      return null;
    }
  }

  Map<String, String> getNextOpeningHour(Map<String, dynamic> hours) {
    DateTime now = DateTime.now();
    List<String> daysOfWeek = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    int todayIndex = daysOfWeek.indexOf(DateFormat('EEEE').format(now));

    for (int i = 0; i < daysOfWeek.length; i++) {
      int dayIndex = (todayIndex + i) % daysOfWeek.length;
      String day = daysOfWeek[dayIndex];
      if (hours.containsKey(day)) {
        Map<String, dynamic> dayHours = hours[day];
        if (dayHours['open'] != null && dayHours['close'] != null) {
          return {'time': dayHours['open'] ?? '', 'day': day};
        }
      }
    }

    return {'time': '', 'day': ''};
  }

  Widget _buildHoursOfOperation(Map<String, dynamic> hours) {
    List<String> daysOfWeek = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    List<Widget> hourWidgets = [];

    for (var day in daysOfWeek) {
      if (hours.containsKey(day)) {
        Map<String, dynamic> dayHours = hours[day];
        String open = dayHours['open'] ?? '';
        String close = dayHours['close'] ?? '';
        String status = dayHours['closed'] == true
            ? 'Closed'
            : dayHours['allDay'] == true
                ? 'Open 24 Hours'
                : '$open - $close';

        hourWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  day,
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  status,
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: hourWidgets,
    );
  }

  Future<void> _launchMaps(double latitude, double longitude) async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
