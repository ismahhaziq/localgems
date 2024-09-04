import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:commerce_yt/user/placedetail/placedetail.dart';
import 'package:commerce_yt/user/review/editreview.dart'; // Import the ReviewEditPage
import 'package:share_plus/share_plus.dart'; // Import share package
import 'package:intl/intl.dart'; // Add this import for date formatting

class MyReviewsPage extends StatefulWidget {
  @override
  _MyReviewsPageState createState() => _MyReviewsPageState();
}

class _MyReviewsPageState extends State<MyReviewsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late User _user;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Reviews'),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: _fetchReviews(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No reviews yet'));
          }
          return ListView(
            padding: EdgeInsets.all(16),
            children: snapshot.data!.docs.map((doc) {
              var reviewData = doc.data() as Map<String, dynamic>;
              return Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: GestureDetector(
                  onTap: () {
                    // Navigate to PlaceDetailsPage when a review is tapped
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlaceDetailsPage(
                          placeId: reviewData['placeId'],
                          distance: 0,
                          userId: _user.uid,
                        ),
                      ),
                    );
                  },
                  child: _buildReviewTile(doc, reviewData),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildReviewTile(
      DocumentSnapshot doc, Map<String, dynamic> reviewData) {
    double rating = reviewData['rating'] ?? 0.0;
    Timestamp timePosted = reviewData['timePosted'];
    DateTime date = timePosted.toDate();
    String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(date);

    List<String> photoUrls = List<String>.from(reviewData['photoUrls'] ?? []);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                reviewData['placeName'],
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReviewEditPage(
                          placeName: reviewData['placeName'],
                          placeId: reviewData['placeId'],
                          reviewId: doc.id,
                        ),
                      ),
                    );
                  } else if (value == 'share') {
                    _shareReview(reviewData);
                  } else if (value == 'delete') {
                    _showDeleteConfirmationDialog(doc);
                  }
                },
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem<String>(
                      value: 'share',
                      child: Text('Share'),
                    ),
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
          RatingBarIndicator(
            rating: rating,
            itemBuilder: (context, _) => Icon(
              Icons.star,
              color: Color(0xFF7472E0),
            ),
            itemCount: 5,
            itemSize: 20,
            unratedColor: Colors.grey[400],
          ),
          SizedBox(height: 8),
          Text(
            reviewData['review'],
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Posted on: $formattedDate',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: photoUrls.map((url) {
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

  Future<QuerySnapshot> _fetchReviews() async {
    return await FirebaseFirestore.instance
        .collectionGroup('reviews')
        .where('userId', isEqualTo: _user.uid)
        .orderBy('timePosted',
            descending: true) // Order by timePosted in descending order
        .get();
  }

  Future<void> _deleteReview(DocumentReference reviewDocRef) async {
    await reviewDocRef.delete();
    setState(() {}); // Refresh the UI after deleting the review
  }

  void _shareReview(Map<String, dynamic> reviewData) {
    String placeLink = _generatePlaceLink(reviewData['placeId']);
    Share.share(
      'Check out this review on LocalGems! ${reviewData['placeName']}\n$placeLink\n\nReview: ${reviewData['review']}',
      subject: 'Check out this review',
    );
  }

  String _generatePlaceLink(String placeId) {
    // Replace this URL with your app's deep link or web link format
    return 'https://localgems.com/place/$placeId';
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

  void _showDeleteConfirmationDialog(DocumentSnapshot reviewDoc) {
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
              _deleteReview(reviewDoc.reference); // Proceed with the deletion
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
}
