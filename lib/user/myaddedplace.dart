import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:commerce_yt/user/placedetail/placedetail.dart';

class MyAddedPlacesPage extends StatefulWidget {
  @override
  _MyAddedPlacesPageState createState() => _MyAddedPlacesPageState();
}

class _MyAddedPlacesPageState extends State<MyAddedPlacesPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late User _user;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser!;
    print('Current user ID: ${_user.uid}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Added Places'),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: _fetchAddedPlaces(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print('Error fetching places: ${snapshot.error}');
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            print('No places found for user: ${_user.uid}');
            return Center(child: Text('No places added yet'));
          }
          return ListView(
            padding: EdgeInsets.all(16),
            children: snapshot.data!.docs.map((doc) {
              var placeData = doc.data() as Map<String, dynamic>;
              print('Place Data: $placeData');
              return Card(
                margin: EdgeInsets.symmetric(vertical: 10),
                child: ListTile(
                  title: Text(placeData['placeName'] ?? 'No name'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(placeData['description'] ?? ''),
                      SizedBox(height: 5),
                      Text(
                        'Location: ${placeData['address']['city'] ?? 'Unknown'}, ${placeData['address']['state'] ?? 'Unknown'}',
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Status: ${placeData['status'] ?? 'Unknown'}',
                        style: TextStyle(
                          color: placeData['status'] == 'approved'
                              ? Colors.green
                              : placeData['status'] == 'pending'
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlaceDetailsPage(
                          placeId: doc.id,
                          distance: 0,
                          userId: _user.uid,
                        ),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Future<QuerySnapshot> _fetchAddedPlaces() async {
    try {
      return await FirebaseFirestore.instance
          .collection('places')
          .where('userId', isEqualTo: _user.uid)
          .orderBy('createdAt', descending: true)
          .get();
    } catch (e) {
      print('Error fetching added places: $e');
      rethrow;
    }
  }
}
