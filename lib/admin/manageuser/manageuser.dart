import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:commerce_yt/admin/manageuser/viewuser.dart';
import 'package:commerce_yt/admin/manageuser/edituser.dart';
import 'package:commerce_yt/admin/manageuser/createuser.dart';
import 'package:commerce_yt/admin/homeadmin.dart'; // Import HomeAdmin

class ManageUser extends StatefulWidget {
  @override
  _ManageUserPageState createState() => _ManageUserPageState();
}

final FirebaseAuth _auth = FirebaseAuth.instance;

class _ManageUserPageState extends State<ManageUser> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<String> _selectedUserTypes =
      []; // List of selected user types for filtering

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  Widget _buildSelectedFilters() {
    List<Widget> chips = [];

    _selectedUserTypes.forEach((userType) {
      chips.add(
        Chip(
          label: Text(userType),
          onDeleted: () {
            setState(() {
              _selectedUserTypes.remove(userType);
              _filterUsers();
            });
          },
        ),
      );
    });

    return Wrap(
      spacing: 6.0,
      runSpacing: 6.0,
      children: chips,
    );
  }

  void _filterUsers() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage User',
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
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search User',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CreateUser(), // Navigate to CreateUser screen
                        ),
                      );
                    },
                    child: Text('Add User'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Color(
                          0xFF7472E0), // Set button color to match the theme
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.filter_list),
                    label: Text('Filter'),
                    onPressed: _showFilterOptions,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Color(0xFF7472E0),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: _buildSelectedFilters(),
            ),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users')
                    .orderBy('createdAt',
                        descending: true) // Order by createdAt
                    .snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return Text('Something went wrong');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  var users = snapshot.data!.docs.where((doc) {
                    final userData = doc.data() as Map<String, dynamic>;
                    final email = userData.containsKey('email')
                        ? userData['email']
                        : 'N/A';
                    final userType = userData.containsKey('user_type')
                        ? userData['user_type']
                        : 'N/A';

                    bool matchesSearchQuery =
                        email.toString().toLowerCase().contains(_searchQuery);
                    bool matchesUserType = _selectedUserTypes.isEmpty ||
                        _selectedUserTypes.contains(userType);

                    return matchesSearchQuery && matchesUserType;
                  }).toList();

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Swipe left/right or up/down to see more',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: [
                                DataColumn(label: Text('No')),
                                DataColumn(label: Text('Email')),
                                DataColumn(
                                    label: Text(
                                        'User Type')), // New column for User Type
                                DataColumn(label: Text('Action')),
                              ],
                              rows: List.generate(users.length, (index) {
                                final doc = users[index];
                                final userData =
                                    doc.data() as Map<String, dynamic>;
                                final email = userData.containsKey('email')
                                    ? userData['email']
                                    : 'N/A';
                                final userType =
                                    userData.containsKey('user_type')
                                        ? userData['user_type']
                                        : 'N/A';

                                return DataRow(cells: [
                                  DataCell(Text('${index + 1}')),
                                  DataCell(Text(email)),
                                  DataCell(Text(userType)), // Display User Type
                                  DataCell(Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.remove_red_eye),
                                        onPressed: () {
                                          final user = doc.data()
                                              as Map<String, dynamic>;
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ViewUser(user: user),
                                            ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.edit),
                                        onPressed: () {
                                          final user = doc.data()
                                              as Map<String, dynamic>;
                                          final userId = doc.id;
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => EditUser(
                                                  userId: userId,
                                                  userData: user),
                                            ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete),
                                        onPressed: () async {
                                          bool confirmed =
                                              await _showConfirmationDialog(
                                                  context);
                                          if (confirmed) {
                                            await _firestore
                                                .collection('users')
                                                .doc(doc.id)
                                                .delete();
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'User deleted successfully'),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  )),
                                ]);
                              }),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showConfirmationDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this user?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Filter Options',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  title: Text('User Type'),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      _buildCheckboxTile('admin', setModalState),
                      _buildCheckboxTile('user', setModalState),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {});
                      },
                      child: Text('Apply Filters'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setModalState(() {
                          _selectedUserTypes.clear();
                        });
                      },
                      child: Text('Reset'),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Slide up or down to see more options',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCheckboxTile(String userType, StateSetter setModalState) {
    return CheckboxListTile(
      title: Text(userType),
      value: _selectedUserTypes.contains(userType),
      onChanged: (bool? value) {
        setModalState(() {
          if (value == true) {
            _selectedUserTypes.add(userType);
          } else {
            _selectedUserTypes.remove(userType);
          }
        });
      },
    );
  }
}
