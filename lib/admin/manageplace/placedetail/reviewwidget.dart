//a file for popup menu in placedetail.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:commerce_yt/user/review/editreview.dart';

class ReviewWidget extends StatelessWidget {
  final String reviewId;
  final String review;
  final double rating;
  final Timestamp timePosted;
  final String userId;
  final List<String> photoUrls;
  final String placeId;
  final String placeName;

  ReviewWidget({
    required this.reviewId,
    required this.review,
    required this.rating,
    required this.timePosted,
    required this.userId,
    required this.photoUrls,
    required this.placeId,
    required this.placeName,
  });

  @override
  Widget build(BuildContext context) {
    bool isCurrentUser = FirebaseAuth.instance.currentUser?.uid == userId;

    var timeDifference = DateTime.now().difference(timePosted.toDate());
    var formattedTimeDifference = '';

    if (timeDifference.inDays > 0) {
      formattedTimeDifference = '${timeDifference.inDays} days ago';
    } else if (timeDifference.inHours > 0) {
      formattedTimeDifference = '${timeDifference.inHours} hours ago';
    } else if (timeDifference.inMinutes > 0) {
      formattedTimeDifference = '${timeDifference.inMinutes} minutes ago';
    } else {
      formattedTimeDifference = 'Just now';
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.0),
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
              Row(
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
                  SizedBox(width: 8),
                  Text(
                    formattedTimeDifference,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
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
          Text(review),
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
