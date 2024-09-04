import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

Future<Map<String, String>> fetchInferenceRules() async {
  QuerySnapshot querySnapshot =
      await FirebaseFirestore.instance.collection('InferenceRules').get();
  Map<String, String> inferenceRules = {};

  for (var doc in querySnapshot.docs) {
    var data = doc.data() as Map<String, dynamic>;
    inferenceRules[data['keywords']] = data['category'];
  }

  return inferenceRules;
}

Future<List<String>> fetchUserKeywords() async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (userSnapshot.exists) {
      return List<String>.from(userSnapshot['selectedKeywords']);
    }
  }
  return [];
}

double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  var p = 0.017453292519943295;
  var c = cos;
  var a = 0.5 -
      c((lat2 - lat1) * p) / 2 +
      c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
  return 12742 * asin(sqrt(a));
}

Future<List<Map<String, dynamic>>> fetchSuggestedPlacesWithWeights(
    double latitude, double longitude, bool useExactKeywordMatching) async {
  List<String> userKeywords = await fetchUserKeywords();
  Map<String, String> inferenceRules = await fetchInferenceRules();

  // Calculate user's categories based on inference rules
  Set<String> userCategories = userKeywords
      .map((keyword) => inferenceRules[keyword])
      .where((category) => category != null)
      .cast<String>()
      .toSet();

  // Fetch places that match the user's categories
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collection('places')
      .where('status', isEqualTo: 'approved')
      .get();

  List<Future<Map<String, dynamic>?>> placeFutures =
      querySnapshot.docs.map((doc) async {
    var data = doc.data() as Map<String, dynamic>;

    // Extract place keywords and convert to categories
    List<String> placeKeywords = List<String>.from(data['categories']);
    Set<String> placeCategories = placeKeywords 
        .map((keyword) => inferenceRules[keyword])
        .where((category) => category != null)
        .cast<String>()
        .toSet();

    bool matches = useExactKeywordMatching
        ? placeKeywords.any((keyword) => userKeywords.contains(keyword))
        : placeCategories.any((category) => userCategories.contains(category));

    if (matches) {
      var placeGeoPoint = data['selectedLocation'] as GeoPoint;
      var distance = _calculateDistance(
          latitude, longitude, placeGeoPoint.latitude, placeGeoPoint.longitude);
      data['distance'] = distance;
      data['imageURL'] = data['imageURLs'][0];
      data['id'] = doc.id;

      // Fetch average rating
      double averageRating = await calculateAverageRating(doc.id);
      data['averageRating'] = averageRating;

      // Fetch check-in count for all users
      QuerySnapshot checkInSnapshot = await FirebaseFirestore.instance
          .collection('checkIns')
          .where('placeId', isEqualTo: doc.id)
          .get();
      int checkInCount = checkInSnapshot.docs.length;
      data['checkInCount'] = checkInCount;

      return data;
    } else {
      return null;
    }
  }).toList();

  // Filter out null values
  List<Map<String, dynamic>> places = (await Future.wait(placeFutures))
      .where((place) => place != null)
      .cast<Map<String, dynamic>>()
      .toList();

  // Apply weights
  for (var place in places) {
    double keywordWeight = place['categories']
            .where((keyword) => userKeywords.contains(keyword))
            .length *
        1.0;
    double ratingWeight = place['averageRating'] * 2.0;
    double recentWeight = 5.0 /
        (1 +
            place['createdAt']
                .seconds); // Assuming createdAt is a Firestore Timestamp
    double distanceWeight = 1.0 / (1 + place['distance']);
    double checkInWeight = place['checkInCount'] * 1.5;

    place['weight'] = keywordWeight +
        ratingWeight +
        recentWeight +
        distanceWeight +
        checkInWeight;
  }

  // Sort places by weight
  places.sort((a, b) => b['weight'].compareTo(a['weight']));

  return places;
}

Future<double> calculateAverageRating(String placeId) async {
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
