import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';

class PlaceCheckIn extends StatelessWidget {
  final String placeId;
  final Map<String, dynamic> placeData;

  PlaceCheckIn({
    required this.placeId,
    required this.placeData,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        _checkIn(context, placeData);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF7472E0),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text('Check In'),
    );
  }

  void _checkIn(BuildContext context, Map<String, dynamic> placeData) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentReference checkInRef =
          FirebaseFirestore.instance.collection('checkIns').doc();

      await checkInRef.set({
        'placeId': placeId,
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      DocumentReference userDoc =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      DocumentSnapshot userSnapshot = await userDoc.get();

      if (userSnapshot.exists) {
        Map<String, dynamic> userData =
            userSnapshot.data() as Map<String, dynamic>;
        int currentPoints = 0;

        if (userData.containsKey('points')) {
          currentPoints = userData['points'];
        } else {
          await userDoc.set({'points': 0}, SetOptions(merge: true));
        }

        await userDoc.update({
          'points': currentPoints + 10,
        });

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Check In Successful!'),
              content: Text('You have earned 10 points!'),
              actions: [
                TextButton(
                  onPressed: () {
                    String placeLink = _generatePlaceLink(placeId);
                    Share.share(
                      'I just checked in at ${placeData['placeName']}! Check out this place!\n$placeLink',
                      subject: 'Check out ${placeData['placeName']}',
                    );
                    Navigator.of(context).pop();
                  },
                  child: Text('Share'),
                ),
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
    }
  }

  String _generatePlaceLink(String placeId) {
    return 'https://localgems.com/place/$placeId';
  }
}
