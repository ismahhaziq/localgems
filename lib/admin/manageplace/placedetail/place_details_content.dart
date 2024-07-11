import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:commerce_yt/admin/manageplace/placedetail/weather_table.dart';
import 'package:commerce_yt/admin/manageplace/placedetail/place_description.dart';
import 'package:commerce_yt/admin/manageplace/placedetail/place_reviews.dart';

class PlaceDetailsContent extends StatelessWidget {
  final String placeId;
  final Map<String, dynamic> placeData;
  final String? userId;

  PlaceDetailsContent({
    required this.placeId,
    required this.placeData,
    required this.userId,
  });

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(10),
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: InteractiveViewer(
              child: Image.network(imageUrl),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var hours = placeData['hours'] as Map<String, dynamic>;
    var reviewQuery = FirebaseFirestore.instance
        .collection('places')
        .doc(placeId)
        .collection('reviews')
        .where('userId', isEqualTo: userId);

    return FutureBuilder<double>(
      future: _calculateAverageRating(placeId),
      builder: (context, averageRatingSnapshot) {
        if (averageRatingSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (averageRatingSnapshot.hasError) {
          return Center(child: Text('Error: ${averageRatingSnapshot.error}'));
        }

        double averageRating = averageRatingSnapshot.data ?? 0;

        return StreamBuilder<QuerySnapshot>(
          stream: reviewQuery.snapshots(),
          builder: (context, reviewSnapshot) {
            if (reviewSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (reviewSnapshot.hasError) {
              return Text('Error: ${reviewSnapshot.error}');
            }

            bool hasReview =
                reviewSnapshot.hasData && reviewSnapshot.data!.docs.isNotEmpty;
            String reviewId =
                hasReview ? reviewSnapshot.data!.docs.first.id : '';

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 350.0,
                  floating: false,
                  pinned: true,
                  flexibleSpace: LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                      double top = constraints.biggest.height;
                      return FlexibleSpaceBar(
                        title: top <= 120
                            ? Text(
                                placeData['placeName'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                        background: Stack(
                          children: [
                            PageView.builder(
                              controller: PageController(),
                              itemBuilder: (context, index) {
                                final imageUrl = placeData['imageURLs']
                                    [index % placeData['imageURLs'].length];
                                return GestureDetector(
                                  onTap: () {
                                    _showImageDialog(context, imageUrl);
                                  },
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                );
                              },
                            ),
                            Positioned(
                              left: 20,
                              top: 50,
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 16),
                          Divider(height: 1, thickness: 1),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  placeData['placeName'],
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Row(
                                children: [
                                  Icon(Icons.star, color: Color(0xFF7472E0)),
                                  SizedBox(width: 4),
                                  Text(
                                    averageRating.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          PlaceDescription(
                            hours: hours,
                            placeData: placeData,
                          ),
                          Divider(height: 32, thickness: 1),
                          PlaceReviews(
                            placeId: placeId,
                            placeData: placeData,
                            userId: userId,
                            hasReview: hasReview,
                            reviewId: reviewId,
                          ),
                          SizedBox(height: 16),
                          FutureBuilder<Map<String, dynamic>>(
                            future: _fetchWeather(placeData),
                            builder: (context, weatherSnapshot) {
                              if (weatherSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                    child: CircularProgressIndicator());
                              }
                              if (weatherSnapshot.hasError) {
                                return Center(
                                    child: Text(
                                        'Error: ${weatherSnapshot.error}'));
                              }

                              var weatherData = weatherSnapshot.data!;
                              return buildWeatherTable(context, weatherData);
                            },
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _generatePlaceLink(String placeId) {
    return 'https://localgems.com/place/$placeId';
  }

  Future<double> _calculateAverageRating(String placeId) async {
    QuerySnapshot reviewSnapshot = await FirebaseFirestore.instance
        .collection('places')
        .doc(placeId)
        .collection('reviews')
        .get();

    if (reviewSnapshot.docs.isEmpty) {
      return 0;
    }

    double totalRating = 0;
    reviewSnapshot.docs.forEach((doc) {
      totalRating += doc['rating'];
    });

    return totalRating / reviewSnapshot.docs.length;
  }

  Future<Map<String, dynamic>> fetchWeather(
      double latitude, double longitude) async {
    final apiKey = '3729b298c695849cc13c7353862be29b';
    final url =
        'https://api.openweathermap.org/data/2.5/forecast?lat=$latitude&lon=$longitude&units=metric&appid=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load weather data');
    }
  }

  Future<Map<String, dynamic>> _fetchWeather(Map<String, dynamic> placeData) {
    try {
      GeoPoint location = placeData['selectedLocation'];
      double latitude = location.latitude;
      double longitude = location.longitude;
      return fetchWeather(latitude, longitude);
    } catch (e) {
      return Future.error('Failed to get location data');
    }
  }
}
