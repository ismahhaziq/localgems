import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:commerce_yt/admin/manageplace/editplace/editplace.dart';
import 'package:commerce_yt/admin/manageplace/createplace/createplace.dart';
import 'package:commerce_yt/admin/homeadmin.dart';
import 'package:commerce_yt/admin/manageplace/placedetail/placedetail.dart';
import 'package:commerce_yt/admin/manageplace/approval/manageapproval.dart';

class ManagePlace extends StatefulWidget {
  @override
  _ManagePlaceState createState() => _ManagePlaceState();
}

final FirebaseAuth _auth = FirebaseAuth.instance;

class _ManagePlaceState extends State<ManagePlace> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  String _selectedStatus = 'All';
  List<String> _selectedStates = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  //displayed active filter
  Widget _buildSelectedFilters() {
    List<Widget> chips = [];

    if (_selectedStatus != 'All') {
      chips.add(
        Chip(
          label: Text('Status: $_selectedStatus'),
          onDeleted: () {
            setState(() {
              _selectedStatus = 'All';
              _filterPlaces();
            });
          },
        ),
      );
    }

    _selectedStates.forEach((state) {
      chips.add(
        Chip(
          label: Text(state),
          onDeleted: () {
            setState(() {
              _selectedStates.remove(state);
              _filterPlaces();
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

  void _filterPlaces() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Place',
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
            Navigator.pushReplacement(
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
                  labelText: 'Search Place',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
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
                        MaterialPageRoute(builder: (context) => CreatePlace()),
                      );
                    },
                    child: Text('Add Place'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Color(0xFF7472E0),
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
              child: _buildSelectedFilters(), //display active filter
            ),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('places').snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return Text('Something went wrong');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  var places = snapshot.data!.docs.where((doc) {
                    final placeData = doc.data() as Map<String, dynamic>;
                    final placeName = placeData.containsKey('placeName')
                        ? placeData['placeName']
                        : 'N/A';
                    final status = placeData['status'] ?? 'N/A';
                    final address =
                        placeData['address'] as Map<String, dynamic>;
                    final state =
                        address.containsKey('state') ? address['state'] : 'N/A';

                    bool matchesSearchQuery = placeName
                        .toString()
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase());

                    bool matchesStatus = _selectedStatus == 'All' ||
                        status.toString().toLowerCase() ==
                            _selectedStatus.toLowerCase();

                    bool matchesState = _selectedStates.isEmpty ||
                        _selectedStates.contains(state);

                    return matchesSearchQuery && matchesStatus && matchesState;
                  }).toList();

                  places.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;

                    int statusComparison = _getStatusOrder(aData['status'])
                        .compareTo(_getStatusOrder(bData['status']));

                    if (statusComparison != 0) {
                      return statusComparison;
                    } else {
                      Timestamp aCreatedAt =
                          aData['createdAt'] ?? Timestamp.now();
                      Timestamp bCreatedAt =
                          bData['createdAt'] ?? Timestamp.now();
                      return bCreatedAt.compareTo(aCreatedAt);
                    }
                  });

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
                                DataColumn(label: Text('Place Name')),
                                DataColumn(label: Text('State')),
                                DataColumn(label: Text('Status')),
                                DataColumn(label: Text('Action')),
                              ],
                              rows: List.generate(places.length, (index) {
                                final doc = places[index];
                                final placeData =
                                    doc.data() as Map<String, dynamic>;
                                final placeName =
                                    placeData.containsKey('placeName')
                                        ? placeData['placeName']
                                        : 'N/A';
                                final status = placeData['status'] ?? 'N/A';
                                final address = placeData['address']
                                    as Map<String, dynamic>;
                                final state = address.containsKey('state')
                                    ? address['state']
                                    : 'N/A';

                                return DataRow(cells: [
                                  DataCell(Text('${index + 1}')),
                                  DataCell(Text(placeName)),
                                  DataCell(Text(state)),
                                  DataCell(Text(
                                    status,
                                    style: TextStyle(
                                      color: _getStatusColor(status),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )),
                                  DataCell(Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.remove_red_eye),
                                        onPressed: () {
                                          String? userId;
                                          User? user = _auth.currentUser;
                                          if (user != null) {
                                            userId = user.uid;
                                          }
                                          if (status == 'pending') {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    AdminPlaceApproval(),
                                              ),
                                            );
                                          } else {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    PlaceDetailsPage(
                                                  placeId: doc.id,
                                                  userId: userId,
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.edit),
                                        onPressed: () async {
                                          if (status != 'approved') {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title:
                                                      Text('Cannot Edit Place'),
                                                  content: Text(
                                                      'This place is currently ${status} and cannot be edited.'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                      child: Text('OK'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          } else {
                                            final docSnapshot = await _firestore
                                                .collection('places')
                                                .doc(doc.id)
                                                .get();
                                            final placeData = docSnapshot.data()
                                                as Map<String, dynamic>;
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    EditPlace(placeId: doc.id),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete),
                                        onPressed: () async {
                                          bool confirmDelete =
                                              await _showConfirmationDialog(
                                                  context);
                                          if (confirmDelete == true) {
                                            await _firestore
                                                .collection('places')
                                                .doc(doc.id)
                                                .delete();
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Place deleted successfully'),
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

  int _getStatusOrder(String status) {
    switch (status) {
      case 'pending':
        return 0;
      case 'approved':
        return 1;
      case 'declined':
        return 2;
      case 'suspended':
        return 3;
      default:
        return 4;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'declined':
        return Colors.red;
      case 'suspended':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  Future<bool> _showConfirmationDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this place?'),
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
                  title: Text('Status'),
                  trailing: DropdownButton<String>(
                    value: _selectedStatus,
                    onChanged: (String? newValue) {
                      setModalState(() {
                        _selectedStatus = newValue!;
                      });
                    },
                    items: <String>[
                      'All',
                      'approved',
                      'pending',
                      'declined',
                      'suspended'
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      Text('States:'),
                      ..._getAllStates().map((state) {
                        return CheckboxListTile(
                          title: Text(state),
                          value: _selectedStates.contains(state),
                          onChanged: (bool? value) {
                            setModalState(() {
                              if (value == true) {
                                _selectedStates.add(state);
                              } else {
                                _selectedStates.remove(state);
                              }
                            });
                          },
                        );
                      }).toList(),
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
                          _selectedStatus = 'All';
                          _selectedStates.clear();
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

  List<String> _getAllStates() {
    return [
      'Johor',
      'Kedah',
      'Kelantan',
      'Melaka',
      'Negeri Sembilan',
      'Pahang',
      'Penang',
      'Perak',
      'Perlis',
      'Sabah',
      'Sarawak',
      'Selangor',
      'Terengganu',
      'Kuala Lumpur',
      'Labuan',
      'Putrajaya',
    ];
  }
}
