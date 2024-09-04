import 'dart:io';
import 'package:commerce_yt/admin/manageplace/manageplace.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'hours_selection.dart';

class ImageAndCategorySelection extends StatefulWidget {
  final String placeName;
  final String description;
  final String street;
  final String city;
  final String state;
  final String postcode;
  final String country;
  final LatLng selectedLocation;
  final Map<String, Map<String, dynamic>> hours;

  const ImageAndCategorySelection({
    Key? key,
    required this.placeName,
    required this.description,
    required this.street,
    required this.city,
    required this.state,
    required this.postcode,
    required this.country,
    required this.selectedLocation,
    required this.hours,
  }) : super(key: key);

  @override
  _ImageAndCategorySelectionState createState() =>
      _ImageAndCategorySelectionState();
}

class _ImageAndCategorySelectionState extends State<ImageAndCategorySelection> {
  List<String> _selectedKeywords = [];
  List<File> _images = [];
  bool _uploadingImages = false;

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
        newImages.removeWhere((newImage) => _images
            .any((selectedImage) => selectedImage.path == newImage.path));
        _images.addAll(newImages);
      });
    }
  }

  void _navigateToManagePlace() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/manageplace',
      ModalRoute.withName('/homeadmin'),
    );
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
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
            width: 100,
            height: 100,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _images.remove(photo);
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

  void _saveDataAndNavigateBack() async {
    if (_images.isEmpty || _selectedKeywords.isEmpty) {
      _showValidationError();
      return;
    }

    setState(() {
      _uploadingImages = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser; // Get the current user
      if (user == null) {
        _showErrorDialog('User not logged in.');
        setState(() {
          _uploadingImages = false;
        });
        return;
      }

      String userId = user.uid;

      List<String> imageURLs = [];
      for (File image in _images) {
        Reference storageReference = FirebaseStorage.instance.ref().child(
            'places_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
        UploadTask uploadTask = storageReference.putFile(image);
        TaskSnapshot taskSnapshot = await uploadTask;
        String imageURL = await taskSnapshot.ref.getDownloadURL();
        imageURLs.add(imageURL);
      }

      await FirebaseFirestore.instance.collection('places').add({
        'userId': userId,
        'placeName': widget.placeName,
        'address': {
          'street': widget.street,
          'city': widget.city,
          'state': widget.state,
          'postcode': widget.postcode,
          'country': widget.country,
        },
        'description': widget.description,
        'selectedLocation': GeoPoint(widget.selectedLocation.latitude,
            widget.selectedLocation.longitude),
        'imageURLs': imageURLs,
        'categories': _selectedKeywords,
        'hours': widget.hours.map((day, times) => MapEntry(day, {
              'open': times['open'] != null
                  ? (times['open'] as TimeOfDay).format(context)
                  : null,
              'close': times['close'] != null
                  ? (times['close'] as TimeOfDay).format(context)
                  : null,
              'closed': times['closed'],
              'allDay': times['allDay'],
              'individual': times['individual'],
            })),
        'createdAt': Timestamp.now(),
        'status': 'approved',
      });

      _navigateToManagePlace();
    } catch (error) {
      print('Error uploading images: $error');
      _showErrorDialog('Failed to upload images. Please try again.');
    } finally {
      setState(() {
        _uploadingImages = false;
      });
    }
  }

  void _showValidationError() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Important!!'),
          content: Text('Please select at least one image and one category.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () {
              Navigator.pop(
                context,
                MaterialPageRoute(
                  builder: (context) => HoursSelectionPage(
                    placeName: widget.placeName,
                    description: widget.description,
                    street: widget.street,
                    city: widget.city,
                    state: widget.state,
                    postcode: widget.postcode,
                    country: widget.country,
                    selectedLocation: widget.selectedLocation,
                    onSave: (hours) {},
                    initialHours: widget.hours,
                  ),
                ),
              );
            },
          ),
          title: Text(
            'Select Categories and Images',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: Color(0xFF7472E0),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(4.0),
            child: Container(
              color: Colors.grey,
              height: 1.0,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildKeywordSelection(),
                    SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: _getImages,
                      child: Text('Choose Image'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Color(0xFF7472E0),
                        backgroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.0),
                    _buildSelectedImages(),
                    if (_images.length > 6)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Scroll down to see more images',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: _saveDataAndNavigateBack,
                      child: Text('Save'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Color(0xFF7472E0),
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_uploadingImages)
            ModalBarrier(
              color: Colors.black.withOpacity(0.5),
              dismissible: false,
            ),
          if (_uploadingImages)
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(0xFF7472E0), // Use the specified color
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKeywordSelection() {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Select Categories',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.0),
          Container(
            height: 330,
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _buildKeywordChips(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildKeywordChips() {
    List<String> keywords = [
      'restaurant',
      'cafe',
      'bar',
      'diner',
      'park',
      'garden',
      'forest',
      'beach',
      'museum',
      'monument',
      'mosque'
    ];
    return keywords.map((keyword) {
      bool isSelected = _selectedKeywords.contains(keyword);
      return Container(
        width: 120,
        child: ChoiceChip(
          label: Center(
            child: Text(
              keyword,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ),
          selected: isSelected,
          onSelected: (_) => _toggleSelection(keyword),
          selectedColor: Color(0xFF7472E0),
          backgroundColor: Colors.grey[200],
        ),
      );
    }).toList();
  }

  void _toggleSelection(String keyword) {
    setState(() {
      if (_selectedKeywords.contains(keyword)) {
        _selectedKeywords.remove(keyword);
      } else {
        _selectedKeywords.add(keyword);
      }
    });
  }

  Widget _buildSelectedImages() {
    return Container(
      height: 200,
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: _images.map((photo) {
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
                    width: 100,
                    height: 100,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _images.remove(photo);
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
          }).toList(),
        ),
      ),
    );
  }
}
