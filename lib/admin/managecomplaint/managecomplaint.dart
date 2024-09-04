import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:commerce_yt/admin/managecomplaint/complaint_details.dart';
import 'package:commerce_yt/admin/homeadmin.dart';

class ManageComplaint extends StatefulWidget {
  @override
  _ManageComplaintState createState() => _ManageComplaintState();
}

class _ManageComplaintState extends State<ManageComplaint> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<String> _selectedStatuses = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterComplaints);
  }

  void _filterComplaints() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
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
                ),
                Expanded(
                  child: ListView(
                    children: [
                      _buildCheckboxTile('resolved', setModalState),
                      _buildCheckboxTile('suspended', setModalState),
                      _buildCheckboxTile('declined', setModalState),
                      _buildCheckboxTile('dismiss', setModalState),
                      _buildCheckboxTile('pending', setModalState),
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
                          _selectedStatuses.clear();
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

  Widget _buildCheckboxTile(String status, StateSetter setModalState) {
    return CheckboxListTile(
      title: Text(status),
      value: _selectedStatuses.contains(status),
      onChanged: (bool? value) {
        setModalState(() {
          if (value == true) {
            _selectedStatuses.add(status);
          } else {
            _selectedStatuses.remove(status);
          }
        });
      },
    );
  }

//active filter shown 
  Widget _buildSelectedFilters() {
    List<Widget> chips = [];

    _selectedStatuses.forEach((status) {
      chips.add(
        Chip(
          label: Text(status),
          onDeleted: () {
            setState(() {
              _selectedStatuses.remove(status);
              _filterComplaints();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Complaints',
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
                  labelText: 'Search Complaints',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _buildSelectedFilters(),
                  ),
                ),
              ],
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collectionGroup('complaints')
                    .orderBy('timePosted', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No complaints found'));
                  }

                  var filteredComplaints = snapshot.data!.docs.where((doc) {
                    var complaintData = doc.data() as Map<String, dynamic>;
                    var placeName =
                        complaintData['placeName'].toString().toLowerCase();
                    var complaintDetail =
                        complaintData['complaint'].toString().toLowerCase();
                    var status =
                        complaintData['status'].toString().toLowerCase();

                    bool matchesSearchQuery =
                        placeName.contains(_searchQuery) ||
                            complaintDetail.contains(_searchQuery);
                    bool matchesStatus = _selectedStatuses.isEmpty ||
                        _selectedStatuses.contains(status);

                    return matchesSearchQuery && matchesStatus;
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
                                DataColumn(label: Text('Place Name')),
                                DataColumn(label: Text('Detail')),
                                DataColumn(label: Text('Status')),
                                DataColumn(label: Text('Action')),
                              ],
                              rows: List.generate(filteredComplaints.length,
                                  (index) {
                                var doc = filteredComplaints[index];
                                var complaintData =
                                    doc.data() as Map<String, dynamic>;
                                return DataRow(cells: [
                                  DataCell(Text('${index + 1}')),
                                  DataCell(Text(complaintData['placeName'])),
                                  DataCell(Text(complaintData['complaint'])),
                                  DataCell(Text(
                                    complaintData['status'],
                                    style: TextStyle(
                                      color:
                                          complaintData['status'] == 'resolved'
                                              ? Colors.green
                                              : complaintData['status'] ==
                                                      'suspended'
                                                  ? Colors.orange
                                                  : complaintData['status'] ==
                                                          'declined'
                                                      ? Colors.red
                                                      : Colors.grey,
                                    ),
                                  )),
                                  DataCell(Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.remove_red_eye),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ComplaintAdminDetailsPage(
                                                complaintData: complaintData,
                                                complaintId: doc.id,
                                              ),
                                            ),
                                          );
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
}
