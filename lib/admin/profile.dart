import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'nav_bar.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _imagePicker = ImagePicker();

  User? _user;
  String _profileImageUrl = '';
  String _displayName = '';
  String _email = '';

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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: Color(0xFF7472E0),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                ),
                Positioned(
                  top: 100, // Adjust this value to move the avatar up or down
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: _profileImageUrl.isNotEmpty
                                ? NetworkImage(_profileImageUrl)
                                : NetworkImage(
                                    'https://jeffjbutler.com/wp-content/uploads/2018/01/default-user.png'),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _updateProfilePicture,
                              child: CircleAvatar(
                                backgroundColor: Colors.blue,
                                radius: 15,
                                child: Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        _displayName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontFamily: 'SF UI Display',
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 5),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(
                height: 30), // Adjust this value to move the content up or down
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6.0,
                      spreadRadius: 1.0,
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: InputBorder.none,
                  ),
                  readOnly: true,
                  controller: TextEditingController(text: _email),
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: NavBar(currentIndex: 1),
    );
  }
}
