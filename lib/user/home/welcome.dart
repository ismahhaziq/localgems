import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' show cos, sqrt, asin;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:commerce_yt/user/placedetail/placedetail.dart';
import 'package:commerce_yt/user/submit/submitplace.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:commerce_yt/user/home/place_helpers.dart';
import 'package:commerce_yt/user/search/search_results.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WelcomePage extends StatefulWidget {
  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final Location location = Location();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController();
  bool isLoggedIn = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _serviceEnabled = false;
  PermissionStatus _permissionGranted = PermissionStatus.denied;
  LocationData? _locationData;
  List<Map<String, dynamic>> nearbyPlaces = [];
  List<Map<String, dynamic>> suggestedPlaces = [];
  bool _showLocationButton = true;
  double _selectedRadius = 500.0;
  bool _isLoading = false;
  bool _loadingSuggestedPlaces = false;
  bool useExactKeywordMatching = false;
  int _currentPage = 0;
  int _itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
    fetchUserData();
    _loadSelectedRadius();
    _checkLocationPermissionStatus();
  }

  void checkLoginStatus() async {
    User? user = _auth.currentUser;
    setState(() {
      isLoggedIn = user != null;
    });
  }

  void fetchUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
    }
  }

  void _checkLocationPermissionStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? locationPermissionGranted =
        prefs.getBool('locationPermissionGranted');

    if (locationPermissionGranted != null && locationPermissionGranted) {
      _getUserLocation();
    }
  }

  void _getUserLocation() async {
    setState(() {
      _isLoading = true;
    });

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }

    _locationData = await location.getLocation();
    await _fetchNearbyPlaces(
        _locationData!.latitude, _locationData!.longitude, _selectedRadius);

    setState(() {
      _isLoading = false;
      _showLocationButton = false;
    });

    if (_locationData != null) {
      setState(() {
        _loadingSuggestedPlaces = true;
      });
      fetchSuggestedPlacesWithWeights(
        _locationData!.latitude!,
        _locationData!.longitude!,
        useExactKeywordMatching,
      ).then((places) {
        if (mounted) {
          setState(() {
            suggestedPlaces = places;
            _loadingSuggestedPlaces = false;
          });
        }
      });
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('locationPermissionGranted', true);
  }

  Future<void> _loadSelectedRadius() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    double? savedRadius = prefs.getDouble('selectedRadius');
    if (savedRadius != null) {
      setState(() {
        _selectedRadius = savedRadius;
      });
    }
  }

  Future<void> _saveSelectedRadius(double radius) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setDouble('selectedRadius', radius);
  }

  /*Future<double> calculateGoogleMapsDistance(double originLat, double originLng,
      double destLat, double destLng) async {
    final apiKey = 'AIzaSyBNAewwHlI0vnP1-3Xq7k7wgF_Qy4O9bPA';
    final url =
        'https://maps.googleapis.com/maps/api/distancematrix/json?origins=$originLat,$originLng&destinations=$destLat,$destLng&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['rows'] != null &&
          data['rows'].isNotEmpty &&
          data['rows'][0]['elements'] != null &&
          data['rows'][0]['elements'].isNotEmpty &&
          data['rows'][0]['elements'][0]['status'] == 'OK') {
        final distanceInMeters =
            data['rows'][0]['elements'][0]['distance']['value'];
        final distanceInKilometers = distanceInMeters / 1000;
        return distanceInKilometers;
      } else {
        // Log the response data for debugging
        print('Invalid response structure: ${json.encode(data)}');
        throw Exception('No route found or invalid response structure');
      }
    } else {
      // Log the response status code and body for debugging
      print(
          'Failed to load distance data: ${response.statusCode} ${response.body}');
      throw Exception('Failed to load distance data');
    }
  }

 Future<void> _fetchNearbyPlaces(
      double? latitude, double? longitude, double radius) async {
    if (latitude == null || longitude == null) return;

    var query = FirebaseFirestore.instance
        .collection('places')
        .where('status', isEqualTo: 'approved');

    QuerySnapshot querySnapshot = await query.get();
    List<Map<String, dynamic>> tempNearbyPlaces = [];

    for (var doc in querySnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      var placeGeoPoint = data['selectedLocation'] as GeoPoint;
      try {
        var distance = await calculateGoogleMapsDistance(latitude, longitude,
            placeGeoPoint.latitude, placeGeoPoint.longitude);
        if (distance <= radius) {
          data['distance'] = distance;
          data['imageURL'] = data['imageURLs'][0];
          data['id'] = doc.id;
          tempNearbyPlaces.add(data);
        }
      } catch (e) {
        // Log the error for debugging
        print('Error calculating distance for place ${doc.id}: $e');
      }
    }

    setState(() {
      nearbyPlaces = tempNearbyPlaces;
      nearbyPlaces.sort((a, b) => a['distance'].compareTo(b['distance']));
    });
  } */


  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  Future<void> _fetchNearbyPlaces(
      double? latitude, double? longitude, double radius) async {
    if (latitude == null || longitude == null) return;

    var query = FirebaseFirestore.instance
        .collection('places')
        .where('status', isEqualTo: 'approved');

    QuerySnapshot querySnapshot = await query.get();
    setState(() {
      nearbyPlaces = querySnapshot.docs
          .map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            var placeGeoPoint = data['selectedLocation'] as GeoPoint;
            var distance = _calculateDistance(latitude, longitude,
                placeGeoPoint.latitude, placeGeoPoint.longitude);
            data['distance'] = distance;
            data['imageURL'] = data['imageURLs'][0];
            data['id'] = doc.id;
            return data;
          })
          .where((data) => data != null && data['distance'] <= radius)
          .toList();
      nearbyPlaces.sort((a, b) => a['distance'].compareTo(b['distance']));
    });
  }
  

  void _showRadiusPicker() {
    double _tempRadius = _selectedRadius;
    _radiusController.text = _tempRadius.toStringAsFixed(1);

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: 400,
              child: Column(
                children: [
                  Text(
                    'Select Radius',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _radiusController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Radius in km',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          _tempRadius = double.tryParse(value) ?? _tempRadius;
                          if (_tempRadius > 1500) {
                            _tempRadius = 1500;
                            _radiusController.text = '1500';
                          }
                        });
                      },
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedRadius = _tempRadius;
                      });
                      _saveSelectedRadius(_selectedRadius);
                      Navigator.pop(context);
                      _getUserLocation();
                    },
                    child: Text('Confirm'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showInstructionsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Exact Match'),
          content: Text(
              'Toggle this switch to match places exactly with your selected keywords. If turned off, places within the same category will be suggested.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _performSearch(String query) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsPage(initialSearchQuery: query),
      ),
    );
  }

  List<Map<String, dynamic>> _getPaginatedPlaces() {
    int startIndex = _currentPage * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;
    if (startIndex > nearbyPlaces.length) return [];
    if (endIndex > nearbyPlaces.length) endIndex = nearbyPlaces.length;
    return nearbyPlaces.sublist(startIndex, endIndex);
  }

  void _nextPage() {
    setState(() {
      if ((_currentPage + 1) * _itemsPerPage < nearbyPlaces.length) {
        _currentPage++;
      }
    });
  }

  void _previousPage() {
    setState(() {
      if (_currentPage > 0) {
        _currentPage--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  height: 280,
                  decoration: BoxDecoration(
                    color: Color(0xFF7472E0),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 100,
                  child: Column(
                    children: [
                      Text(
                        'Find your hidden gems',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontFamily: 'SF UI Display',
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: GestureDetector(
                            onTap: () {
                              _performSearch(_searchController.text);
                            },
                            child: AbsorbPointer(
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Enter a city, place or keyword',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                      vertical: 15, horizontal: 20),
                                  suffixIcon: IconButton(
                                    icon: Icon(Icons.search),
                                    onPressed: () {
                                      _performSearch(_searchController.text);
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            if (isLoggedIn && !_showLocationButton) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Suggested Places',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.info_outline,
                                size: 25,
                              ),
                              onPressed: _showInstructionsDialog,
                            ),
                            Switch(
                              value: useExactKeywordMatching,
                              onChanged: (value) {
                                setState(() {
                                  useExactKeywordMatching = value;
                                });
                                _getUserLocation();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    if (_loadingSuggestedPlaces)
                      Center(child: CircularProgressIndicator())
                    else if (suggestedPlaces.isEmpty)
                      Center(
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'No places found that match your interests.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: suggestedPlaces.length,
                          itemBuilder: (context, index) {
                            var place = suggestedPlaces[index];
                            return FutureBuilder<double>(
                              future: calculateAverageRating(place['id']),
                              builder: (context, ratingSnapshot) {
                                if (ratingSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Card(
                                    child: Container(
                                      width: 150,
                                      child: Center(
                                          child: CircularProgressIndicator()),
                                    ),
                                  );
                                }

                                double averageRating = ratingSnapshot.data ?? 0;

                                return GestureDetector(
                                  onTap: () {
                                    String? userId;
                                    User? user = _auth.currentUser;
                                    if (user != null) {
                                      userId = user.uid;
                                    }
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PlaceDetailsPage(
                                          placeId: place['id'],
                                          distance: place['distance'] ?? 0.0,
                                          userId: userId,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: Colors.grey,
                                        width: 1,
                                      ),
                                    ),
                                    child: Container(
                                      width: 200,
                                      child: Column(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Image.network(
                                              place['imageURL'],
                                              fit: BoxFit.cover,
                                              height: 100,
                                              width: 200,
                                            ),
                                          ),
                                          SizedBox(height: 10),
                                          Text(
                                            place['placeName'],
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            place['address']['city'],
                                            style: TextStyle(fontSize: 14),
                                          ),
                                          RatingBarIndicator(
                                            rating: averageRating,
                                            itemBuilder: (context, index) =>
                                                Icon(
                                              Icons.star,
                                              color: Color(0xFF7472E0),
                                            ),
                                            itemCount: 5,
                                            itemSize: 16.0,
                                            direction: Axis.horizontal,
                                          ),
                                          Text(
                                            averageRating.toStringAsFixed(1),
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discover Infamous Local Place!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _showLocationButton
                          ? Column(
                              children: [
                                Text(
                                  'Unlock unique insights into the hidden gems of your surroundings.',
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 10),
                                _isLoading
                                    ? Center(child: CircularProgressIndicator())
                                    : ElevatedButton(
                                        onPressed: _getUserLocation,
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: Color(0xFF7472E0),
                                          backgroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          padding: EdgeInsets.symmetric(
                                              vertical: 12, horizontal: 32),
                                        ),
                                        child: Text('Allow Location Access'),
                                      ),
                              ],
                            )
                          : Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Radius: ${_selectedRadius.toStringAsFixed(1)} km',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                    TextButton.icon(
                                      icon: Icon(Icons.settings, size: 15),
                                      label: Text(
                                        'Filters',
                                        style: TextStyle(fontSize: 15),
                                      ),
                                      onPressed: _showRadiusPicker,
                                      style: TextButton.styleFrom(
                                        backgroundColor:
                                            Colors.white.withOpacity(0.1),
                                        foregroundColor: Color(0xFF7472E0),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                _isLoading
                                    ? Center(child: CircularProgressIndicator())
                                    : nearbyPlaces.isNotEmpty
                                        ? Column(
                                            children: [
                                              ListView.builder(
                                                shrinkWrap: true,
                                                physics:
                                                    NeverScrollableScrollPhysics(),
                                                itemCount: _getPaginatedPlaces()
                                                    .length,
                                                itemBuilder: (context, index) {
                                                  var place =
                                                      _getPaginatedPlaces()[
                                                          index];
                                                  return FutureBuilder<double>(
                                                    future:
                                                        calculateAverageRating(
                                                            place['id']),
                                                    builder:
                                                        (context, snapshot) {
                                                      if (snapshot
                                                              .connectionState ==
                                                          ConnectionState
                                                              .waiting) {
                                                        return Card(
                                                          child: ListTile(
                                                            title: Text(place[
                                                                'placeName']),
                                                            subtitle: Text(
                                                                '${place['address']['city']} - ${place['distance'].toStringAsFixed(2)} km from your location'),
                                                            trailing:
                                                                CircularProgressIndicator(),
                                                          ),
                                                        );
                                                      }
                                                      if (snapshot.hasError) {
                                                        return Card(
                                                          child: ListTile(
                                                            title: Text(place[
                                                                'placeName']),
                                                            subtitle: Text(
                                                                '${place['address']['city']} - ${place['distance'].toStringAsFixed(2)} km from your location'),
                                                            trailing: Icon(
                                                                Icons.error),
                                                          ),
                                                        );
                                                      }

                                                      double averageRating =
                                                          snapshot.data ?? 0;

                                                      return Card(
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                          side: BorderSide(
                                                            color: Colors.grey,
                                                            width: 1,
                                                          ),
                                                        ),
                                                        child: ListTile(
                                                          leading: SizedBox(
                                                            width: 60,
                                                            height: 100,
                                                            child:
                                                                Image.network(
                                                              place['imageURL'],
                                                              fit: BoxFit.cover,
                                                            ),
                                                          ),
                                                          title: Text(place[
                                                              'placeName']),
                                                          subtitle: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                  '${place['address']['city']} - ${place['distance'].toStringAsFixed(2)} km from your location'),
                                                              SizedBox(
                                                                  height: 4),
                                                              Row(
                                                                children: [
                                                                  RatingBarIndicator(
                                                                    rating:
                                                                        averageRating,
                                                                    itemBuilder:
                                                                        (context,
                                                                                index) =>
                                                                            Icon(
                                                                      Icons
                                                                          .star,
                                                                      color: Color(
                                                                          0xFF7472E0),
                                                                    ),
                                                                    itemCount:
                                                                        5,
                                                                    itemSize:
                                                                        16.0,
                                                                    direction: Axis
                                                                        .horizontal,
                                                                  ),
                                                                  SizedBox(
                                                                      width: 8),
                                                                  Text(
                                                                    averageRating
                                                                        .toStringAsFixed(
                                                                            1),
                                                                    style:
                                                                        TextStyle(
                                                                      fontSize:
                                                                          14,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                          onTap: () async {
                                                            String? userId;
                                                            User? user =
                                                                FirebaseAuth
                                                                    .instance
                                                                    .currentUser;
                                                            if (user != null) {
                                                              userId = user.uid;
                                                            }

                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        PlaceDetailsPage(
                                                                  placeId:
                                                                      place[
                                                                          'id'],
                                                                  distance: place[
                                                                      'distance'],
                                                                  userId:
                                                                      userId,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  TextButton(
                                                    onPressed: _previousPage,
                                                    child: Text('Previous'),
                                                  ),
                                                  TextButton(
                                                    onPressed: _nextPage,
                                                    child: Text('Next'),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          )
                                        : Center(
                                            child: Text(
                                              'No places found within the selected radius.',
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
