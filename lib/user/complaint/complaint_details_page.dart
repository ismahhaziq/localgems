import 'package:commerce_yt/user/complaint/mycomplaint.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:commerce_yt/user/placedetail/placedetail.dart';

class ComplaintDetailsPage extends StatefulWidget {
  final Map<String, dynamic> complaintData;
  final String complaintId;

  ComplaintDetailsPage({
    required this.complaintData,
    required this.complaintId,
  });

  @override
  _ComplaintDetailsPageState createState() => _ComplaintDetailsPageState();
}

class _ComplaintDetailsPageState extends State<ComplaintDetailsPage> {
  final TextEditingController _commentController = TextEditingController();
  final int _maxCommentLength = 200;
  Map<String, dynamic>? userData;

  bool get isActionTaken {
    String status = widget.complaintData['status'];
    return status == 'reviewed' ||
        status == 'resolved' ||
        status == 'suspended' ||
        status == 'dismissed';
  }

  @override
  void initState() {
    super.initState();
    _fetchUserData(widget.complaintData['userId']);
  }

  Future<void> _fetchUserData(String userId) async {
    DocumentSnapshot userSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    setState(() {
      userData = userSnapshot.data() as Map<String, dynamic>?;
    });
  }

  void _markAsReviewed(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('places')
        .doc(widget.complaintData['placeId'])
        .collection('complaints')
        .doc(widget.complaintId)
        .update({
      'status': 'reviewed',
      'adminComment': _commentController.text,
    });
    Navigator.pop(context);
  }

  void _suspendPlace(BuildContext context) async {
    bool confirmSuspend = await _showSuspendWarning(context);
    if (confirmSuspend) {
      await FirebaseFirestore.instance
          .collection('places')
          .doc(widget.complaintData['placeId'])
          .update({'status': 'suspended'});

      await FirebaseFirestore.instance
          .collection('places')
          .doc(widget.complaintData['placeId'])
          .collection('complaints')
          .doc(widget.complaintId)
          .update({
        'status': 'suspended',
        'adminComment': _commentController.text,
      });

      Navigator.pop(context);
    }
  }

  void _resolveComplaint(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('places')
        .doc(widget.complaintData['placeId'])
        .collection('complaints')
        .doc(widget.complaintId)
        .update({
      'status': 'resolved',
      'adminComment': _commentController.text,
    });
    Navigator.pop(context);
  }

  void _dismissComplaint(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('places')
        .doc(widget.complaintData['placeId'])
        .collection('complaints')
        .doc(widget.complaintId)
        .update({
      'status': 'dismissed',
      'adminComment': _commentController.text,
    });
    Navigator.pop(context);
  }

  Future<bool> _showSuspendWarning(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Warning'),
            content: Text(
                'This action cannot be undone. Are you sure you want to suspend this place?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Suspend'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showImageDialog(
      BuildContext context, List<String> imageUrls, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(10),
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: InteractiveViewer(
              child: PageView.builder(
                itemCount: imageUrls.length,
                controller: PageController(initialPage: initialIndex),
                itemBuilder: (context, index) {
                  return Image.network(imageUrls[index]);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> photoUrls =
        List<String>.from(widget.complaintData['photoUrls']);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Complaint Details',
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
              MaterialPageRoute(builder: (context) => MyComplaintsPage()),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      _showImageDialog(context, photoUrls, 0);
                    },
                    child: Container(
                      height: 200,
                      child: PageView.builder(
                        itemCount: photoUrls.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              _showImageDialog(context, photoUrls, index);
                            },
                            child: Container(
                              margin: EdgeInsets.symmetric(horizontal: 5),
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.grey, width: 2),
                              ),
                              child: Image.network(
                                photoUrls[index],
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  if (photoUrls.length > 1) ...[
                    Positioned(
                      left: 10,
                      top: 90,
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.black,
                        size: 30,
                      ),
                    ),
                    Positioned(
                      right: 10,
                      top: 90,
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.black,
                        size: 30,
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 16),
              Text(
                'Place Name',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7472E0)),
              ),
              SizedBox(height: 8),
              Text(
                widget.complaintData['placeName'],
                style: TextStyle(fontSize: 16),
              ),
              Divider(height: 32, thickness: 1),
              Text(
                'Details',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7472E0)),
              ),
              SizedBox(height: 8),
              Text(
                widget.complaintData['complaint'],
                style: TextStyle(fontSize: 16),
              ),
              if (widget.complaintData['status'] != 'pending') ...[
                Divider(height: 32, thickness: 1),
                Text(
                  'Admin Comment',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7472E0)),
                ),
                SizedBox(height: 8),
                Text(
                  widget.complaintData['adminComment'] ?? 'No comment',
                  style: TextStyle(fontSize: 16),
                ),
              ],
              SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlaceDetailsPage(
                          placeId: widget.complaintData['placeId'],
                          distance: 0,
                          userId: widget.complaintData['userId'],
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.place, color: Colors.white),
                  label: Text(
                    'View Place',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF7472E0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
