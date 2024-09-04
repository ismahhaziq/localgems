import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewPage extends StatefulWidget {
  final String? placeName;
  final String? placeId;

  ReviewPage({
    required this.placeName,
    required this.placeId,
  });

  @override
  _ReviewPageState createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  double _rating = 0.0;
  List<File> _selectedPhotos = [];
  String userId = '';
  TextEditingController _reviewController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserId();
    _reviewController.addListener(() {
      setState(() {}); // Update the UI when the review text changes
    });
  }

  void fetchUserId() {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid;
      });
    } else {
      setState(() {
        userId = 'anonymous';
      });
    }
  }

  void _getImages() async {
    final picker = ImagePicker();
    final pickedImages = await picker.pickMultiImage(
      maxWidth: 800,
      maxHeight: 600,
      imageQuality: 85,
    );
    if (pickedImages != null) {
      setState(() {
        List<File> newImages =
            pickedImages.map((pickedImage) => File(pickedImage.path)).toList();
        newImages.removeWhere((newImage) => _selectedPhotos
            .any((selectedImage) => selectedImage.path == newImage.path));
        _selectedPhotos.addAll(newImages);
      });
    }
  }

  Widget _buildPhotoPreview(File photo) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            _showFullImageDialog(photo);
          },
          child: Container(
            margin: EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: FileImage(photo),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedPhotos.remove(photo);
              });
            },
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.black.withOpacity(0.6),
              child: Icon(Icons.close, color: Colors.white, size: 25),
            ),
          ),
        ),
      ],
    );
  }

  void _showFullImageDialog(File photo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Image.file(photo),
        );
      },
    );
  }

  Future<void> _submitReview() async {
    // Validate rating and review length
    if (_rating < 1) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Rating Required'),
          content: Text('Please provide at least a 1-star rating.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Show a loading indicator while uploading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      // Upload new photos to Firebase Storage and get their download URLs
      List<String> photoUrls = [];
      for (File photo in _selectedPhotos) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('review_images')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(photo);
        final url = await ref.getDownloadURL();
        photoUrls.add(url);
      }

      // Add new review to Firestore
      await FirebaseFirestore.instance
          .collection('places')
          .doc(widget.placeId)
          .collection('reviews')
          .add({
        'rating': _rating,
        'review': _reviewController.text,
        'photoUrls': photoUrls,
        'userId': userId,
        'placeId': widget.placeId,
        'placeName': widget.placeName,
        'timePosted': Timestamp.now(),
        'status': 'original',
      });

      // Hide the loading indicator
      Navigator.pop(context);

      // Navigate back to previous screen
      Navigator.pop(context);
    } catch (e) {
      // Hide the loading indicator
      Navigator.pop(context);

      // Show an error message
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Failed to submit review. Please try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.placeName ?? '',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios), // Use a fancier arrow icon
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return CircularProgressIndicator();
                      }

                      var userData = snapshot.data?.data() as Map<String,
                          dynamic>?; // Cast to Map<String, dynamic>
                      if (userData == null) {
                        // Handle the case where userData is null
                        return Text('User data not available');
                      }

                      String username = userData['username'] ?? '';
                      String profileImageUrl =
                          userData['profileImageUrl'] ?? '';

                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.grey,
                            backgroundImage: profileImageUrl.isNotEmpty
                                ? NetworkImage(profileImageUrl)
                                : null,
                            child: profileImageUrl.isEmpty
                                ? Icon(Icons.person, color: Colors.white)
                                : null,
                          ),
                          SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                username,
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _rating = 1.0;
                            });
                          },
                          child: Icon(Icons.star,
                              color: _rating >= 1 ? Colors.purple : Colors.grey,
                              size: 60),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _rating = 2.0;
                            });
                          },
                          child: Icon(Icons.star,
                              color: _rating >= 2 ? Colors.purple : Colors.grey,
                              size: 60),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _rating = 3.0;
                            });
                          },
                          child: Icon(Icons.star,
                              color: _rating >= 3 ? Colors.purple : Colors.grey,
                              size: 60),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _rating = 4.0;
                            });
                          },
                          child: Icon(Icons.star,
                              color: _rating >= 4 ? Colors.purple : Colors.grey,
                              size: 60),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _rating = 5.0;
                            });
                          },
                          child: Icon(Icons.star,
                              color: _rating >= 5 ? Colors.purple : Colors.grey,
                              size: 60),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _reviewController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText:
                          'Share details of your experience (max 300 characters)',
                      counterText:
                          '${_reviewController.text.length}/300', // Character count
                    ),
                    maxLines: 4,
                    maxLength: 300, // Set max length to 100 characters
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _getImages,
                      icon: Icon(Icons.camera_alt, color: Colors.white),
                      label: Text('Add photos',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF7472E0), // Button color
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12), // Soft corner radius
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    children: _selectedPhotos
                        .map((photo) => _buildPhotoPreview(photo))
                        .toList(),
                  ),
                  SizedBox(height: 80),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: ElevatedButton(
              onPressed: _submitReview,
              child:
                  Text('Submit Review', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF7472E0), // Button color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Soft corner radius
                ),
                padding: EdgeInsets.symmetric(vertical: 16), // Increase padding
              ),
            ),
          ),
        ],
      ),
    );
  }
}
