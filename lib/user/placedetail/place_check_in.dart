import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';

class PlaceCheckIn extends StatefulWidget {
  final String placeId;
  final Map<String, dynamic> placeData;

  PlaceCheckIn({
    required this.placeId,
    required this.placeData,
  });

  @override
  _PlaceCheckInState createState() => _PlaceCheckInState();
}

class _PlaceCheckInState extends State<PlaceCheckIn> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Check if the place status is 'pending'
    if (widget.placeData['status'] == 'pending') {
      return SizedBox.shrink(); // Return an empty widget if status is 'pending'
    }

    return ElevatedButton(
      onPressed: () {
        _checkIn(context, widget.placeData);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF7472E0),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.symmetric(
            vertical: 8, horizontal: 12), // Adjust padding here
      ),
      child: Text(
        'Check In',
        style: TextStyle(fontSize: 14), // Adjust font size here
      ),
    );
  }

  Future<String> _createDynamicLink(String placeId, String placeName) async {
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: 'https://localgems.page.link',
      link: Uri.parse('https://localgems.com/place/$placeId'),
      androidParameters: AndroidParameters(
        packageName: 'com.android.application',
        minimumVersion: 1,
        fallbackUrl: Uri.parse(
            'https://drive.google.com/drive/folders/1t5q9A_MsLm3T5oh5ltuYJ-oVEly8V8Bp?usp=sharing'),
      ),
      socialMetaTagParameters: SocialMetaTagParameters(
        title: 'Check out $placeName',
        description: 'Discover amazing places with LocalGems!',
      ),
    );

    final ShortDynamicLink shortLink =
        await FirebaseDynamicLinks.instance.buildShortLink(parameters);
    return shortLink.shortUrl.toString();
  }

  void _checkIn(BuildContext context, Map<String, dynamic> placeData) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      QuerySnapshot checkIns = await FirebaseFirestore.instance
          .collection('checkIns')
          .where('placeId', isEqualTo: widget.placeId)
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (checkIns.docs.isNotEmpty) {
        Timestamp lastCheckInTimestamp = checkIns.docs.first['timestamp'];
        DateTime lastCheckInTime = lastCheckInTimestamp.toDate();
        DateTime now = DateTime.now();

        if (now.difference(lastCheckInTime).inHours < 24) {
          _showCannotCheckInDialog(context);
          return;
        }
      }

      DocumentReference checkInRef =
          FirebaseFirestore.instance.collection('checkIns').doc();

      await checkInRef.set({
        'placeId': widget.placeId,
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      DocumentReference userDoc =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      DocumentSnapshot userSnapshot = await userDoc.get();
/*
      if (userSnapshot.exists) {
        Map<String, dynamic> userData =
            userSnapshot.data() as Map<String, dynamic>;
        int currentPoints = userData['points'] ?? 0;

        await userDoc.update({
          'points': currentPoints + 10,
        });
        */

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Check In Successful!'),
            actions: [
              TextButton(
                onPressed: () async {
                  String placeLink = await _createDynamicLink(
                      widget.placeId, widget.placeData['placeName']);
                  Share.share(
                    'I just checked in at ${widget.placeData['placeName']}! Check out this place!\n$placeLink',
                    subject: 'Check out ${widget.placeData['placeName']}',
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

void _showCannotCheckInDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Check In Failed'),
        content: Text(
            'You have already checked in within the last 24 hours. Please try again later.'),
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

String _generatePlaceLink(String placeId) {
  return 'https://localgems.com/place/$placeId';
}
//}
