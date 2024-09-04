import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Widget buildWeatherTable(
    BuildContext context, Map<String, dynamic> weatherData) {
  var city = weatherData['city']['name'];
  var currentWeather = weatherData['list'][0];
  var temperature = currentWeather['main']['temp'];
  var weatherDescription = currentWeather['weather'][0]['description'];
  var icon = currentWeather['weather'][0]['icon'];
  var iconUrl = 'http://openweathermap.org/img/wn/$icon@2x.png';

  List<Map<String, dynamic>> dailyForecasts = [];
  for (var forecast in weatherData['list']) {
    DateTime date = DateTime.parse(forecast['dt_txt']);
    if (dailyForecasts.isEmpty || date.day != dailyForecasts.last['date'].day) {
      dailyForecasts.add({
        'date': date,
        'temp': forecast['main']['temp'],
        'description': forecast['weather'][0]['description'],
        'icon': forecast['weather'][0]['icon'],
      });
    }
    if (dailyForecasts.length == 5) break;
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Divider(height: 32, thickness: 1),
      Text(
        'Weather',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      Text(
        city,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      Row(
        children: [
          Image.network(iconUrl, width: 50, height: 50),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$weatherDescription',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '$temperature°C',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
      SizedBox(height: 20),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: dailyForecasts.map((forecast) {
            var iconUrl =
                'http://openweathermap.org/img/wn/${forecast['icon']}@2x.png';
            var dayName = DateFormat('EEE').format(forecast['date']);
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(
                    '$dayName, ${forecast['date'].day}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Image.network(iconUrl, width: 50, height: 50),
                  Text(
                    '${forecast['temp']}°C',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    ],
  );
}
