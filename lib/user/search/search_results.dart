import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:commerce_yt/user/placedetail/placedetail.dart'; // Import the PlaceDetailsPage

class SearchResultsPage extends StatefulWidget {
  final String initialSearchQuery;

  SearchResultsPage({required this.initialSearchQuery});

  @override
  _SearchResultsPageState createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> searchResults = [];
  List<String> selectedFilters = [];
  List<String> selectedStates = [];
  double selectedStarRating = 0.0; // Initialize selectedStarRating
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialSearchQuery;
    _performSearch(widget.initialSearchQuery);
  }

  void _performSearch(String query) async {
    setState(() {
      _isLoading = true;
    });

    var querySnapshot = await FirebaseFirestore.instance
        .collection('places')
        .where('status', isEqualTo: 'approved')
        .get();

    List<Map<String, dynamic>> results = [];

    for (var doc in querySnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      bool matchesQuery = data['placeName']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()) ||
          data['description']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase());

      // Fetch reviews for the place
      var reviewSnapshot = await FirebaseFirestore.instance
          .collection('places')
          .doc(doc.id)
          .collection('reviews')
          .get();

      bool matchesReview = reviewSnapshot.docs.any((reviewDoc) {
        var reviewData = reviewDoc.data() as Map<String, dynamic>;
        return reviewData['review']
            .toString()
            .toLowerCase()
            .contains(query.toLowerCase());
      });

      if (matchesQuery || matchesReview) {
        data['id'] = doc.id;
        data['imageURL'] = data['imageURLs'][0];
        results.add(data);
      }
    }

    setState(() {
      searchResults = results;
      _isLoading = false;
    });
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance.collection('InferenceRules').get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            List<String> allKeywords = snapshot.data!.docs
                .map((doc) => doc['keywords'].toString())
                .toList();

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
                    Expanded(
                      child: ListView(
                        children: [
                          ExpansionTile(
                            title: Text('Categories'),
                            children: allKeywords.map((keyword) {
                              bool isSelected =
                                  selectedFilters.contains(keyword);
                              return CheckboxListTile(
                                title: Text(keyword),
                                value: isSelected,
                                onChanged: (bool? value) {
                                  setModalState(() {
                                    if (value == true) {
                                      selectedFilters.add(keyword);
                                    } else {
                                      selectedFilters.remove(keyword);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          ExpansionTile(
                            title: Text('States'),
                            children: _malaysianStates.map((state) {
                              bool isSelected = selectedStates.contains(state);
                              return CheckboxListTile(
                                title: Text(state),
                                value: isSelected,
                                onChanged: (bool? value) {
                                  setModalState(() {
                                    if (value == true) {
                                      selectedStates.add(state);
                                    } else {
                                      selectedStates.remove(state);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          ExpansionTile(
                            title: Text('Star Rating'),
                            children: [
                              Slider(
                                value: selectedStarRating,
                                min: 0,
                                max: 5,
                                divisions: 5,
                                label: selectedStarRating.toString(),
                                onChanged: (double value) {
                                  setModalState(() {
                                    selectedStarRating = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _applyFilters();
                          },
                          child: Text('Apply Filters'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setModalState(() {
                              selectedFilters.clear();
                              selectedStates.clear(); // Reset states filter
                              selectedStarRating =
                                  0.0; // Reset star rating filter
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
      },
    );
  }

  void _applyFilters() async {
    setState(() {
      _isLoading = true;
    });

    var querySnapshot = await FirebaseFirestore.instance
        .collection('places')
        .where('status', isEqualTo: 'approved')
        .get();

    List<Map<String, dynamic>> results = [];

    for (var doc in querySnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      data['imageURL'] = data['imageURLs'][0];

      bool matchesFilters = true;

      if (selectedFilters.isNotEmpty) {
        List<String> placeKeywords = List<String>.from(data['categories']);
        matchesFilters =
            selectedFilters.every((filter) => placeKeywords.contains(filter));
      }

      if (matchesFilters && selectedStates.isNotEmpty) {
        matchesFilters = selectedStates.contains(data['address']['state']);
      }

      if (matchesFilters && selectedStarRating > 0) {
        double averageRating = await _calculateAverageRating(data['id']);
        matchesFilters = averageRating >= selectedStarRating &&
            averageRating < selectedStarRating + 1;
      }

      if (matchesFilters) {
        results.add(data);
      }
    }

    setState(() {
      searchResults = results;
      _isLoading = false;
    });
  }

  Future<double> _calculateAverageRating(String placeId) async {
    QuerySnapshot reviewSnapshot = await FirebaseFirestore.instance
        .collection('places')
        .doc(placeId)
        .collection('reviews')
        .get();

    if (reviewSnapshot.docs.isEmpty) {
      return 0;
    }

    double totalRating = 0;
    reviewSnapshot.docs.forEach((doc) {
      totalRating += doc['rating'];
    });

    return totalRating / reviewSnapshot.docs.length;
  }

  List<String> _malaysianStates = [
    'Johor',
    'Kedah',
    'Kelantan',
    'Kuala Lumpur',
    'Labuan',
    'Melaka',
    'Negeri Sembilan',
    'Pahang',
    'Penang',
    'Perak',
    'Perlis',
    'Putrajaya',
    'Sabah',
    'Sarawak',
    'Selangor',
    'Terengganu',
  ];

  Widget _buildFilterChips() {
    List<Widget> chips = [];

    selectedFilters.forEach((filter) {
      chips.add(
        Chip(
          label: Text(filter),
          onDeleted: () {
            setState(() {
              selectedFilters.remove(filter);
              _applyFilters();
            });
          },
        ),
      );
    });

    selectedStates.forEach((state) {
      chips.add(
        Chip(
          label: Text(state),
          onDeleted: () {
            setState(() {
              selectedStates.remove(state);
              _applyFilters();
            });
          },
        ),
      );
    });

    if (selectedStarRating > 0) {
      chips.add(
        Chip(
          label: Text('Rating: $selectedStarRating+'),
          onDeleted: () {
            setState(() {
              selectedStarRating = 0.0;
              _applyFilters();
            });
          },
        ),
      );
    }

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
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search',
            border: InputBorder.none,
          ),
          onSubmitted: (query) {
            _performSearch(query);
          },
        ),
        actions: [
          TextButton.icon(
            icon: Icon(Icons.filter_list),
            label: Text(
              'Filters',
              style: TextStyle(fontSize: 14, color: Color(0xFF7472E0)),
            ),
            onPressed: _showFilterOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildFilterChips(),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : searchResults.isEmpty
                    ? Center(
                        child: Text(
                          'No places found. Please try different filters or search terms.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          var place = searchResults[index];
                          return FutureBuilder<double>(
                            future: _calculateAverageRating(place['id']),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Card(
                                  child: ListTile(
                                    title: Text(place['placeName']),
                                    subtitle: Text(place['address']['city']),
                                    trailing: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              double averageRating = snapshot.data ?? 0;

                              return Card(
                                child: ListTile(
                                  leading: SizedBox(
                                    width: 60,
                                    height: 60,
                                    child: Image.network(
                                      place['imageURL'],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  title: Text(place['placeName']),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(place['address']['city']),
                                      Row(
                                        children: [
                                          RatingBarIndicator(
                                            rating: averageRating,
                                            itemBuilder: (context, index) =>
                                                Icon(
                                              Icons.star,
                                              color: Color(0xFF7472E0),
                                            ),
                                            itemCount: 5,
                                            itemSize: 16.0,
                                            direction: Axis.horizontal,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            averageRating.toStringAsFixed(1),
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  onTap: () async {
                                    String? userId;
                                    User? user = _auth.currentUser;
                                    if (user != null) {
                                      userId = user.uid;
                                    }

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PlaceDetailsPage(
                                          placeId: place['id'],
                                          distance: place['distance'] ?? 0.0,
                                          userId: userId,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
