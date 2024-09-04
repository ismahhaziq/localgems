import 'package:commerce_yt/admin/managecomplaint/managecomplaint.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:commerce_yt/admin/manageplace/placedetail/placedetail.dart';

class ComplaintAdminDetailsPage extends StatefulWidget {
  final Map<String, dynamic> complaintData;
  final String complaintId;

  ComplaintAdminDetailsPage({
    required this.complaintData,
    required this.complaintId,
  });

  @override
  _ComplaintAdminDetailsPageState createState() =>
      _ComplaintAdminDetailsPageState();
}

class _ComplaintAdminDetailsPageState extends State<ComplaintAdminDetailsPage> {
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

  Future<void> _updateComplaintStatus(
      BuildContext context, String status) async {
    bool confirmAction = await _showCommentDialog(context, status);
    if (confirmAction) {
      await FirebaseFirestore.instance
          .collection('places')
          .doc(widget.complaintData['placeId'])
          .collection('complaints')
          .doc(widget.complaintId)
          .update({
        'status': status,
        'adminComment': _commentController.text,
      });

      if (status == 'suspended') {
        await FirebaseFirestore.instance
            .collection('places')
            .doc(widget.complaintData['placeId'])
            .update({'status': 'suspended'});
      }

      Navigator.pop(context);
    }
  }

  Future<bool> _showCommentDialog(BuildContext context, String status) async {
    String actionText;
    if (status == 'reviewed') {
      actionText = 'mark this complaint as reviewed';
    } else if (status == 'resolved') {
      actionText = 'resolve this complaint';
    } else if (status == 'suspended') {
      actionText = 'suspend this place';
    } else {
      actionText = 'dismiss this complaint';
    }

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Confirmation'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                      'This action cannot be undone. Are you sure you want to $actionText?'),
                  SizedBox(height: 16),
                  TextField(
                    controller: _commentController,
                    maxLength: _maxCommentLength,
                    maxLines: 4,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Add your comment',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Confirm'),
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
              MaterialPageRoute(builder: (context) => ManageComplaint()),
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
              if (userData != null) ...[
                Text(
                  'Reported By',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7472E0)),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey,
                      backgroundImage: userData!['profileImageUrl'].isNotEmpty
                          ? NetworkImage(userData!['profileImageUrl'])
                          : null,
                      child: userData!['profileImageUrl'].isEmpty
                          ? Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userData!['username'],
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          userData!['email'],
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
                Divider(height: 32, thickness: 1),
              ],
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
              if (widget.complaintData.containsKey('adminComment')) ...[
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
                  widget.complaintData['adminComment'],
                  style: TextStyle(fontSize: 16),
                ),
              ],
              Divider(height: 32, thickness: 1),
              Text(
                'Actions',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7472E0)),
              ),
              SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlaceDetailsPage(
                          placeId: widget.complaintData['placeId'],
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
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _buildActionButton(
                        'Mark as Reviewed',
                        Colors.blue,
                        (context) =>
                            _updateComplaintStatus(context, 'reviewed'),
                        context),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildActionButton(
                        'Resolve Complaint',
                        Colors.green,
                        (context) =>
                            _updateComplaintStatus(context, 'resolved'),
                        context),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _buildActionButton(
                        'Suspend Place',
                        Colors.red,
                        (context) =>
                            _updateComplaintStatus(context, 'suspended'),
                        context),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildActionButton(
                        'Dismiss Complaint',
                        Colors.grey,
                        (context) =>
                            _updateComplaintStatus(context, 'dismissed'),
                        context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, Color color,
      void Function(BuildContext) onPressed, BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isActionTaken ? null : () => onPressed(context),
      icon: Icon(
        _getIconForAction(text),
        color: Colors.white,
      ),
      label: FittedBox(
        child: Text(
          text,
          style: TextStyle(color: Colors.white),
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActionTaken ? Colors.grey : color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  IconData _getIconForAction(String action) {
    switch (action) {
      case 'Mark as Reviewed':
        return Icons.check_circle;
      case 'Resolve Complaint':
        return Icons.check_circle_outline;
      case 'Suspend Place':
        return Icons.pause_circle_filled;
      case 'Dismiss Complaint':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }
}
