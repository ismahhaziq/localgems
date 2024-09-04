import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  String _username = '';
  List<String> _selectedKeywords = [];
  TextEditingController _usernameController = TextEditingController();
  bool _isEditing = false;

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

      setState(() {
        _username = userDataSnapshot.get('username') ?? 'Anonymous';
        _selectedKeywords =
            List<String>.from(userDataSnapshot.get('selectedKeywords') ?? []);
        _usernameController.text = _username;
      });
    }
  }

  Future<void> _updateUserProfile() async {
    if (_selectedKeywords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least one interest.')),
      );
      return;
    }

    if (_user != null) {
      await _firestore.collection('users').doc(_user!.uid).update({
        'username': _usernameController.text,
        'selectedKeywords': _selectedKeywords,
      });

      setState(() {
        _username = _usernameController.text;
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully!')),
      );
    }
  }

  void _toggleKeywordSelection(String keyword) {
    setState(() {
      if (_selectedKeywords.contains(keyword)) {
        _selectedKeywords.remove(keyword);
      } else {
        _selectedKeywords.add(keyword);
      }
    });
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
          onSelected:
              _isEditing ? (_) => _toggleKeywordSelection(keyword) : null,
          selectedColor: Color(0xFF7472E0),
          backgroundColor: Colors.grey[200],
        ),
      );
    }).toList();
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
              Navigator.pop(context);
            },
          ),
          title: Text(
            'Profile',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: Color(0xFF7472E0),
          centerTitle: true,
          actions: [
            TextButton.icon(
              icon: Icon(
                _isEditing ? Icons.check : Icons.edit,
                color: Colors.white,
              ),
              label: Text(
                _isEditing ? 'Save' : 'Edit',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                if (_isEditing) {
                  _updateUserProfile();
                } else {
                  setState(() {
                    _isEditing = true;
                  });
                }
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(4.0),
            child: Container(
              color: Colors.grey,
              height: 1.0,
            ),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: !_isEditing,
                ),
                SizedBox(height: 20),
                Text(
                  'Interests',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.0),
                Container(
                  padding: EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: _buildKeywordChips(),
                    ),
                  ),
                ),
                if (_isEditing) ...[
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _updateUserProfile,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
