import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:commerce_yt/admin/manageplace/approval/placedetailapproval.dart';
import 'package:commerce_yt/admin/homeadmin.dart';

class AdminPlaceApproval extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Approval',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF7472E0),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pop(
              context,
              MaterialPageRoute(builder: (context) => HomeAdmin()),
            );
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('places')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var places = snapshot.data!.docs;

          if (places.isEmpty) {
            return Center(child: Text('No pending places'));
          }

          return ListView.builder(
            itemCount: places.length,
            itemBuilder: (context, index) {
              var place = places[index];
              var placeData = place.data() as Map<String, dynamic>;

              return Card(
                margin: EdgeInsets.all(8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey, width: 1),
                ),
                child: ListTile(
                  leading: SizedBox(
                    width: 60,
                    height: 60,
                    child: Image.network(
                      placeData['imageURLs'][0],
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(
                    placeData['placeName'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    placeData['description'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        icon: Icon(Icons.check, color: Colors.green),
                        onPressed: () => _showApproveDialog(context, place.id),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        onPressed: () => _showDeclineDialog(context, place.id),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlaceDetailsApprovalPage(
                          placeId: place.id,
                          userId: '',
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _updateStatus(String placeId, String status, BuildContext context,
      {String? comment}) {
    FirebaseFirestore.instance.collection('places').doc(placeId).update({
      'status': status,
      if (comment != null) 'declineComment': comment,
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Place $status successfully')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $error')),
      );
    });
  }

  void _showApproveDialog(BuildContext context, String placeId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Approve Place'),
          content: Text('Are you sure you want to approve this place?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _updateStatus(placeId, 'approved', context);
                Navigator.of(context).pop();
              },
              child: Text('Approve'),
            ),
          ],
        );
      },
    );
  }

  void _showDeclineDialog(BuildContext context, String placeId) {
    final TextEditingController _commentController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Decline Place'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Please provide a reason for declining this place:'),
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter comment here',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                String comment = _commentController.text.trim();
                _updateStatus(placeId, 'declined', context, comment: comment);
                Navigator.of(context).pop();
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }
}
