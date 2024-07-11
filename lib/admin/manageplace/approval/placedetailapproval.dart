import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:commerce_yt/admin/manageplace/approval/placedetailcontentapproval.dart';

class PlaceDetailsApprovalPage extends StatelessWidget {
  final String placeId;
  final String? userId;

  PlaceDetailsApprovalPage({
    required this.placeId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('places').doc(placeId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Place not found'));
          }

          var placeData = snapshot.data!.data() as Map<String, dynamic>;
          if (placeData['status'] == 'suspended') {
            return Center(
              child: AlertDialog(
                title: Text('Place Suspended'),
                content: Text(
                    'This place is currently suspended and cannot be viewed.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('OK'),
                  ),
                ],
              ),
            );
          }

          return PlaceDetailsContentApproval(
            placeId: placeId,
            placeData: placeData,
            userId: userId,
          );
        },
      ),
    );
  }
}
