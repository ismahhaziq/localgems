import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class PlaceDescription extends StatelessWidget {
  final Map<String, dynamic> hours;
  final Map<String, dynamic> placeData;

  PlaceDescription({
    required this.hours,
    required this.placeData,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(left: 0.0),
                  child: Text(
                    'City: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  child: Text(placeData['address']['city']),
                ),
              ],
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
        Divider(height: 20, thickness: 1),
        // Categories section
        Text(
          'Categories',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          children: placeData['categories']
              .map<Widget>((category) => Chip(
                    label: Text(category),
                  ))
              .toList(),
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

  TimeOfDay? _parseTime(String? time) {
    if (time == null || time.isEmpty) return null;
    try {
      final format = DateFormat.Hm();
      DateTime dateTime = format.parse(time);
      return TimeOfDay.fromDateTime(dateTime);
    } catch (e) {
      print("Error parsing time: $e");
      return null;
    }
  }

  String getOpeningHourToday(Map<String, dynamic> hours) {
    DateTime now = DateTime.now();
    String day = DateFormat('EEEE').format(now);

    if (hours.containsKey(day)) {
      Map<String, dynamic> dayHours = hours[day];

      if (dayHours['closed'] == true && dayHours['open'] != null) {
        return dayHours['open'];
      }

      if (dayHours['allDay'] == true) {
        return '00:00';
      }

      if (dayHours['open'] != null) {
        return dayHours['open'];
      }
    }

    return '';
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
