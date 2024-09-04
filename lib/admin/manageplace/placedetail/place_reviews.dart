import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:commerce_yt/user/placedetail/reviewwidget.dart';
import 'package:commerce_yt/user/review/allreview.dart';

class PlaceReviews extends StatelessWidget {
  final String placeId;
  final Map<String, dynamic> placeData;
  final String? userId;
  final bool hasReview;
  final String reviewId;

  PlaceReviews({
    required this.placeId,
    required this.placeData,
    required this.userId,
    required this.hasReview,
    required this.reviewId,
  });

  @override
  Widget build(BuildContext context) {
    var reviewtotal = FirebaseFirestore.instance
        .collection('places')
        .doc(placeId)
        .collection('reviews');

    return FutureBuilder<QuerySnapshot>(
      future: reviewtotal.get(),
      builder: (context, reviewTotalSnapshot) {
        if (reviewTotalSnapshot.connectionState == ConnectionState.waiting) {
          return Text('Reviews (Loading...)');
        }
        if (reviewTotalSnapshot.hasError) {
          return Text('Error: ${reviewTotalSnapshot.error}');
        }

        final totalReviews = reviewTotalSnapshot.data!.docs.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reviews ($totalReviews)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AllReviewsPage(
                          placeId: placeId,
                          placeName: placeData['placeName'],
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'See all reviews',
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      fontSize: 13,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('places')
                  .doc(placeId)
                  .collection('reviews')
                  .orderBy('timePosted',
                      descending:
                          true) // Order by timePosted in descending order
                  .limit(3)
                  .snapshots(),
              builder: (context, reviewSnapshot) {
                if (reviewSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (reviewSnapshot.hasError) {
                  return Text('Error: ${reviewSnapshot.error}');
                }
                if (reviewSnapshot.data == null ||
                    reviewSnapshot.data!.docs.isEmpty) {
                  return Text('No reviews yet');
                }

                Map<String, List<QueryDocumentSnapshot>> groupedReviews = {};
                for (var doc in reviewSnapshot.data!.docs) {
                  var userId = doc['userId'];
                  if (groupedReviews.containsKey(userId)) {
                    groupedReviews[userId]!.add(doc);
                  } else {
                    groupedReviews[userId] = [doc];
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: groupedReviews.entries.map((entry) {
                    var userId = entry.key;
                    var reviews = entry.value;
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .get(),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (userSnapshot.hasError) {
                          return Text('Error: ${userSnapshot.error}');
                        }
                        if (!userSnapshot.hasData ||
                            !userSnapshot.data!.exists) {
                          return Text('User not found');
                        }

                        var userData =
                            userSnapshot.data!.data() as Map<String, dynamic>;
                        var username = userData['username'] ?? 'Unknown';

                        return Container(
                          margin: EdgeInsets.only(bottom: 16.0),
                          padding: EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                username,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: reviews.map((reviewDoc) {
                                  var reviewData =
                                      reviewDoc.data() as Map<String, dynamic>;
                                  return ReviewWidget(
                                    reviewId: reviewDoc.id,
                                    review: reviewData['review'],
                                    rating: reviewData['rating'],
                                    timePosted: reviewData['timePosted'] ?? 0,
                                    userId: userId,
                                    photoUrls: List<String>.from(
                                        reviewData['photoUrls']),
                                    placeId: placeId,
                                    placeName: placeData['placeName'],
                                    status: reviewData['status'] ?? '',
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
