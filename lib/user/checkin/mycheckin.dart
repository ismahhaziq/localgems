import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:commerce_yt/user/placedetail/placedetail.dart';
import 'package:intl/intl.dart';

class CheckInListPage extends StatefulWidget {
  @override
  _CheckInListPageState createState() => _CheckInListPageState();
}

class _CheckInListPageState extends State<CheckInListPage> {
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
        title: Text('My Check-Ins'),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: _fetchCheckIns(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No check-ins yet'));
          }
          return ListView(
            padding: EdgeInsets.all(16),
            children: snapshot.data!.docs.map((doc) {
              var checkInData = doc.data() as Map<String, dynamic>;
              return FutureBuilder<DocumentSnapshot>(
                future: _fetchPlaceDetails(checkInData['placeId']),
                builder: (context, placeSnapshot) {
                  if (placeSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (placeSnapshot.hasError) {
                    return Center(child: Text('Error: ${placeSnapshot.error}'));
                  }
                  if (!placeSnapshot.hasData || !placeSnapshot.data!.exists) {
                    return Center(child: Text('Place not found'));
                  }
                  var placeData =
                      placeSnapshot.data!.data() as Map<String, dynamic>;
                  return Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onTap: () {
                        // Navigate to PlaceDetailsPage when a check-in is tapped
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlaceDetailsPage(
                              placeId: checkInData['placeId'],
                              distance: 0,
                              userId: _user.uid,
                            ),
                          ),
                        );
                      },
                      child: _buildCheckInTile(checkInData, placeData),
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

  Widget _buildCheckInTile(
      Map<String, dynamic> checkInData, Map<String, dynamic> placeData) {
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
            children: [
              Expanded(
                child: Text(
                  placeData['placeName'],
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Text(
                placeData['address']['city'],
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Checked in at ${DateFormat('yyyy-MM-dd – kk:mm').format(checkInData['timestamp'].toDate())}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Future<QuerySnapshot> _fetchCheckIns() async {
    return await FirebaseFirestore.instance
        .collection('checkIns')
        .where('userId', isEqualTo: _user.uid)
        .orderBy('timestamp', descending: true)
        .get();
  }

  Future<DocumentSnapshot> _fetchPlaceDetails(String placeId) async {
    return await FirebaseFirestore.instance
        .collection('places')
        .doc(placeId)
        .get();
  }
}
