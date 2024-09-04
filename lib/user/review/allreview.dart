import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:commerce_yt/user/review/editreview.dart';

class AllReviewsPage extends StatelessWidget {
  final String placeId;
  final String placeName;

  AllReviewsPage({required this.placeId, required this.placeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Reviews for $placeName'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('places')
            .doc(placeId)
            .collection('reviews')
            .orderBy('timePosted', descending: true)
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
            return Center(child: Text('No reviews yet'));
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

          return ListView(
            padding: EdgeInsets.all(16.0),
            children: groupedReviews.entries.map((entry) {
              var userId = entry.key;
              var reviews = entry.value;
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (userSnapshot.hasError) {
                    return Text('Error: ${userSnapshot.error}');
                  }
                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return Text('User not found');
                  }

                  var userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  var username = userData['username'] ?? 'Unknown';
                  var profileImageUrl = userData['profileImageUrl'] ?? '';

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
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: NetworkImage(profileImageUrl),
                              radius: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              username,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: reviews.map((reviewDoc) {
                            var reviewData =
                                reviewDoc.data() as Map<String, dynamic>;
                            var timeDifference = DateTime.now()
                                .difference(reviewData['timePosted'].toDate());
                            var formattedTimeDifference = '';
                            if (timeDifference.inDays > 0) {
                              formattedTimeDifference =
                                  '${timeDifference.inDays} days ago';
                            } else if (timeDifference.inHours > 0) {
                              formattedTimeDifference =
                                  '${timeDifference.inHours} hours ago';
                            } else if (timeDifference.inMinutes > 0) {
                              formattedTimeDifference =
                                  '${timeDifference.inMinutes} minutes ago';
                            } else {
                              formattedTimeDifference = 'Just now';
                            }

                            // Append "Updated" if status is "updated"
                            if (reviewData['status'] == 'updated') {
                              formattedTimeDifference += ' (Updated)';
                            }

                            return ReviewTile(
                              reviewId: reviewDoc.id,
                              review: reviewData['review'],
                              rating: reviewData['rating'],
                              timePosted: formattedTimeDifference,
                              userId: userId,
                              photoUrls:
                                  List<String>.from(reviewData['photoUrls']),
                              placeId: placeId,
                              placeName: placeName,
                              status: reviewData['status'],
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
    );
  }
}

class ReviewTile extends StatelessWidget {
  final String reviewId;
  final String review;
  final double rating;
  final String timePosted;
  final String userId;
  final List<String> photoUrls;
  final String placeId;
  final String placeName;
  final String status;

  ReviewTile({
    required this.reviewId,
    required this.review,
    required this.rating,
    required this.timePosted,
    required this.userId,
    required this.photoUrls,
    required this.placeId,
    required this.placeName,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    bool isCurrentUser = FirebaseAuth.instance.currentUser?.uid == userId;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RatingBarIndicator(
                rating: rating,
                itemBuilder: (context, index) => Icon(
                  Icons.star,
                  color: Color(0xFF7472E0),
                ),
                itemCount: 5,
                itemSize: 16.0,
                unratedColor: Colors.grey[400],
                direction: Axis.horizontal,
              ),
              if (isCurrentUser)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReviewEditPage(
                            placeName: placeName,
                            placeId: placeId,
                            reviewId: reviewId,
                          ),
                        ),
                      );
                    } else if (value == 'delete') {
                      _showDeleteConfirmationDialog(context);
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ];
                  },
                ),
            ],
          ),
          SizedBox(height: 8),
          Text(timePosted, style: TextStyle(color: Colors.grey, fontSize: 12)),
          SizedBox(height: 8),
          Text(review),
          SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: photoUrls.where((url) => url.isNotEmpty).map((url) {
              return GestureDetector(
                onTap: () {
                  _showFullImageDialog(context, url);
                },
                child: Image.network(
                  url,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showFullImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
              _deleteReview(); // Proceed with the deletion
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReview() async {
    await FirebaseFirestore.instance
        .collection('places')
        .doc(placeId)
        .collection('reviews')
        .doc(reviewId)
        .delete();
  }
}
