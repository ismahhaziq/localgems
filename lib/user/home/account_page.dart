import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:commerce_yt/user/profile_page.dart';
import 'package:commerce_yt/auth/login.dart';
import 'package:commerce_yt/user/review/myreview.dart';
import 'package:commerce_yt/user/checkin/mycheckin.dart';
import 'package:commerce_yt/user/complaint/mycomplaint.dart';
import 'package:commerce_yt/user/myaddedplace.dart';

class AccountPage extends StatefulWidget {
  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _imagePicker = ImagePicker();

  User? _user;
  String _profileImageUrl = '';
  String _displayName = '';
  String _email = '';
  bool _isUpdatingImage = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    _user = _auth.currentUser;
    if (_user != null) {
      DocumentSnapshot userDataSnapshot =
          await _firestore.collection('users').doc(_user!.uid).get();

      String? username = userDataSnapshot.get('username');
      String photoUrl = userDataSnapshot.get('profileImageUrl');

      if (photoUrl.isEmpty) {
        photoUrl =
            'https://jeffjbutler.com/wp-content/uploads/2018/01/default-user.png';
      }

      setState(() {
        _displayName = username ?? 'Anonymous';
        _email = _user!.email ?? 'No Email';
        _profileImageUrl = photoUrl;
      });
    }
  }

  Future<void> _updateProfilePicture() async {
    final XFile? image =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      _isUpdatingImage = true;
    });

    final File file = File(image.path);
    final String fileName = _user!.uid + '-profile-picture.jpg';
    final Reference storageRef = FirebaseStorage.instance
        .ref()
        .child('profile_pictures')
        .child(fileName);

    await storageRef.putFile(file);
    final String downloadUrl = await storageRef.getDownloadURL();

    await _firestore.collection('users').doc(_user!.uid).update({
      'profileImageUrl': downloadUrl,
    });

    await _user!.updatePhotoURL(downloadUrl);
    setState(() {
      _profileImageUrl = downloadUrl;
      _isUpdatingImage = false;
    });
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('locationPermissionGranted');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                GestureDetector(
                  onTap: _updateProfilePicture,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _profileImageUrl.isNotEmpty
                        ? NetworkImage(_profileImageUrl)
                        : NetworkImage(
                            'https://jeffjbutler.com/wp-content/uploads/2018/01/default-user.png'),
                  ),
                ),
                if (_isUpdatingImage)
                  Positioned.fill(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  radius: 15,
                  child: Icon(
                    Icons.edit,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              _displayName,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              _email,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              },
              child: Text('Profile'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                textStyle: TextStyle(fontSize: 18),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CheckInListPage()),
                );
              },
              child: Text('My Check In Places'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                textStyle: TextStyle(fontSize: 18),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyReviewsPage()),
                );
              },
              child: Text('My Reviews'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                textStyle: TextStyle(fontSize: 18),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyAddedPlacesPage()),
                );
              },
              child: Text('My Added Places'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                textStyle: TextStyle(fontSize: 18),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyComplaintsPage()),
                );
              },
              child: Text('My Complaints'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                textStyle: TextStyle(fontSize: 18),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _signOut,
              child: Text('Logout'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                textStyle: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
