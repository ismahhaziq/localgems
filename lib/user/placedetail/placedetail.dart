import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:commerce_yt/user/placedetail/place_details_content.dart';

class PlaceDetailsPage extends StatelessWidget {
  final String placeId;
  final double distance;
  final String? userId;

  PlaceDetailsPage({
    required this.placeId,
    required this.distance,
    required this.userId,
  });

  Future<Map<String, dynamic>> _getPlaceData() async {
    DocumentSnapshot placeSnapshot = await FirebaseFirestore.instance
        .collection('places')
        .doc(placeId)
        .get();
    if (!placeSnapshot.exists) {
      throw Exception('Place not found');
    }
    var placeData = placeSnapshot.data() as Map<String, dynamic>;
    return placeData;
  }

  Future<String?> _getAdminComment(String placeId) async {
    QuerySnapshot complaintsSnapshot = await FirebaseFirestore.instance
        .collection('places')
        .doc(placeId)
        .collection('complaints')
        .get();
    if (complaintsSnapshot.docs.isNotEmpty) {
      var complaintData =
          complaintsSnapshot.docs.first.data() as Map<String, dynamic>;
      return complaintData['adminComment'];
    }
    return null;
  }

  Future<String?> _getDeclineComment(String placeId) async {
    QuerySnapshot complaintsSnapshot = await FirebaseFirestore.instance
        .collection('places')
        .doc(placeId)
        .collection('complaints')
        .get();
    if (complaintsSnapshot.docs.isNotEmpty) {
      var complaintData =
          complaintsSnapshot.docs.first.data() as Map<String, dynamic>;
      return complaintData['declineComment'];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getPlaceData(),
        builder: (context, placeSnapshot) {
          if (placeSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (placeSnapshot.hasError) {
            return Center(child: Text('Error: ${placeSnapshot.error}'));
          }
          if (!placeSnapshot.hasData) {
            return Center(child: Text('Place not found'));
          }

          var placeData = placeSnapshot.data!;

          if (placeData['status'] == 'suspended') {
            return FutureBuilder<String?>(
              future: _getAdminComment(placeId),
              builder: (context, adminCommentSnapshot) {
                if (adminCommentSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (adminCommentSnapshot.hasError) {
                  return Center(
                      child: Text('Error: ${adminCommentSnapshot.error}'));
                }
                return Center(
                  child: AlertDialog(
                    title: Text('Place Suspended'),
                    content: RichText(
                      text: TextSpan(
                        text:
                            'This place has been suspended by the admin for the following reason: ',
                        style: DefaultTextStyle.of(context).style,
                        children: [
                          TextSpan(
                            text: adminCommentSnapshot.data ??
                                'No comment provided',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            );
          }

          if (placeData['status'] == 'declined') {
            return FutureBuilder<String?>(
              future: _getDeclineComment(placeId),
              builder: (context, declineCommentSnapshot) {
                if (declineCommentSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (declineCommentSnapshot.hasError) {
                  return Center(
                      child: Text('Error: ${declineCommentSnapshot.error}'));
                }
                return Center(
                  child: AlertDialog(
                    title: Text('Place Declined'),
                    content: RichText(
                      text: TextSpan(
                        text:
                            'This place has been declined by the admin for the following reason: ',
                        style: DefaultTextStyle.of(context).style,
                        children: [
                          TextSpan(
                            text: declineCommentSnapshot.data ??
                                'No comment provided',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            );
          }

          return PlaceDetailsContent(
            placeId: placeId,
            placeData: placeData,
            distance: distance,
            userId: userId,
          );
        },
      ),
    );
  }
}
