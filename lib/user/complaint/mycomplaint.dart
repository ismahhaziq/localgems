import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:commerce_yt/user/complaint/complaint_details_page.dart';

class MyComplaintsPage extends StatefulWidget {
  @override
  _MyComplaintsPageState createState() => _MyComplaintsPageState();
}

class _MyComplaintsPageState extends State<MyComplaintsPage> {
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
        title: Text('My Complaints'),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: _fetchComplaints(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No complaints found'));
          }
          return ListView(
            padding: EdgeInsets.all(16),
            children: snapshot.data!.docs.map((doc) {
              var complaintData = doc.data() as Map<String, dynamic>;
              return Card(
                margin: EdgeInsets.symmetric(vertical: 10),
                child: ListTile(
                  title: Text(complaintData['placeName']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(complaintData['complaint']),
                      SizedBox(height: 5),
                      Text(
                        'Status: ${complaintData['status']}',
                        style: TextStyle(
                          color: complaintData['status'] == 'resolved'
                              ? Colors.green
                              : complaintData['status'] == 'dismissed'
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
                        builder: (context) => ComplaintDetailsPage(
                          complaintData: complaintData,
                          complaintId: doc.id,
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

  Future<QuerySnapshot> _fetchComplaints() async {
    return await FirebaseFirestore.instance
        .collectionGroup('complaints')
        .where('userId', isEqualTo: _user.uid)
        .orderBy('timePosted', descending: true)
        .get();
  }
}
