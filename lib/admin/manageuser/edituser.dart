import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'manageuser.dart'; // Import ManageUser for navigation

class EditUser extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const EditUser({Key? key, required this.userId, required this.userData})
      : super(key: key);

  @override
  _EditUserState createState() => _EditUserState();
}

class _EditUserState extends State<EditUser> {
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  String _selectedUserType = '';
  List<String> _userTypes = ['admin', 'user'];
  bool _isLoading = false; // Loading state

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.userData['username'] ?? '';
    _emailController.text = widget.userData['email'] ?? '';
    _selectedUserType = widget.userData['user_type'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit User',
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
              MaterialPageRoute(builder: (context) => ManageUser()),
            );
          },
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(labelText: 'Username'),
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                ),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedUserType,
                  onChanged: (value) {
                    setState(() {
                      _selectedUserType = value!;
                    });
                  },
                  items: _userTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  decoration: InputDecoration(labelText: 'User Type'),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : _updateUser, // Disable button when loading
                      child: Text('Save'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Color(
                            0xFF7472E0), // Set button color to match the theme
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          MaterialPageRoute(builder: (context) => ManageUser()),
                        );
                      },
                      child: Text('Cancel'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor:
                            Colors.grey, // Set button color to match the theme
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isLoading)
            ModalBarrier(
              color: Colors.black.withOpacity(0.5),
              dismissible: false,
            ),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(0xFF7472E0),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _updateUser() async {
    setState(() {
      _isLoading = true; // Start loading
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'username': _usernameController.text,
        'email': _emailController.text,
        'user_type': _selectedUserType,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User updated successfully')),
      );

      Navigator.pop(
        context,
        MaterialPageRoute(builder: (context) => ManageUser()),
      );
    } catch (error) {
      print('Error updating user: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update user')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Stop loading
      });
    }
  }
}
