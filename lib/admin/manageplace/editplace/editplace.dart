import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'edit_hours_selection.dart';
import 'edit_image_and_category_selection.dart';
import 'edit_map_screen.dart';
import 'package:commerce_yt/admin/manageplace/manageplace.dart';

class EditPlace extends StatefulWidget {
  final String placeId;

  EditPlace({required this.placeId});

  @override
  _EditPlaceState createState() => _EditPlaceState();
}

class _EditPlaceState extends State<EditPlace> {
  final TextEditingController _placeNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _postcodeController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();

  LatLng? _selectedLocation;
  bool _isNextButtonEnabled = false;
  Map<String, Map<String, dynamic>> _hours = {
    'Monday': {
      'open': null,
      'close': null,
      'closed': false,
      'allDay': false,
      'individual': false
    },
    'Tuesday': {
      'open': null,
      'close': null,
      'closed': false,
      'allDay': false,
      'individual': false
    },
    'Wednesday': {
      'open': null,
      'close': null,
      'closed': false,
      'allDay': false,
      'individual': false
    },
    'Thursday': {
      'open': null,
      'close': null,
      'closed': false,
      'allDay': false,
      'individual': false
    },
    'Friday': {
      'open': null,
      'close': null,
      'closed': false,
      'allDay': false,
      'individual': false
    },
    'Saturday': {
      'open': null,
      'close': null,
      'closed': false,
      'allDay': false,
      'individual': false
    },
    'Sunday': {
      'open': null,
      'close': null,
      'closed': false,
      'allDay': false,
      'individual': false
    },
  };

  List<String> _selectedKeywords = [];
  List<String> _initialImageURLs = [];

  @override
  void initState() {
    super.initState();
    _placeNameController.addListener(_checkIfAllFieldsAreFilled);
    _descriptionController.addListener(_checkIfAllFieldsAreFilled);
    _streetController.addListener(_checkIfAllFieldsAreFilled);
    _cityController.addListener(_checkIfAllFieldsAreFilled);
    _stateController.addListener(_checkIfAllFieldsAreFilled);
    _postcodeController.addListener(_checkIfAllFieldsAreFilled);
    _countryController.addListener(_checkIfAllFieldsAreFilled);
    _loadPlaceData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadPlaceData();
  }

  void _loadPlaceData() async {
    DocumentSnapshot placeSnapshot = await FirebaseFirestore.instance
        .collection('places')
        .doc(widget.placeId)
        .get();
    var placeData = placeSnapshot.data() as Map<String, dynamic>;

    setState(() {
      _placeNameController.text = placeData['placeName'];
      _descriptionController.text = placeData['description'];
      _streetController.text = placeData['address']['street'];
      _cityController.text = placeData['address']['city'];
      _stateController.text = placeData['address']['state'];
      _postcodeController.text = placeData['address']['postcode'];
      _countryController.text = placeData['address']['country'];

      GeoPoint geoPoint = placeData['selectedLocation'];
      _selectedLocation = LatLng(
        geoPoint.latitude,
        geoPoint.longitude,
      );

      _hours = (placeData['hours'] as Map<String, dynamic>).map((day, times) {
        return MapEntry(
          day,
          {
            'open':
                times['open'] != null ? _parseTimeOfDay(times['open']) : null,
            'close':
                times['close'] != null ? _parseTimeOfDay(times['close']) : null,
            'closed': times['closed'],
            'allDay': times['allDay'],
            'individual': times['individual'],
          },
        );
      });

      _selectedKeywords = List<String>.from(placeData['categories']);
      _initialImageURLs = List<String>.from(placeData['imageURLs']);
    });

    _checkIfAllFieldsAreFilled();
  }

  TimeOfDay _parseTimeOfDay(String time) {
    final format = DateFormat.jm(); // Adjust format as necessary
    final dateTime = format.parse(time);
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }

  void _checkIfAllFieldsAreFilled() {
    setState(() {
      _isNextButtonEnabled = _placeNameController.text.isNotEmpty &&
          _descriptionController.text.isNotEmpty &&
          _selectedLocation != null &&
          _streetController.text.isNotEmpty &&
          _cityController.text.isNotEmpty &&
          _stateController.text.isNotEmpty &&
          _postcodeController.text.isNotEmpty &&
          _countryController.text.isNotEmpty;
    });
  }

  void _navigateToHoursPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HoursSelectionPage(
          placeId: widget.placeId,
          placeName: _placeNameController.text.trim(),
          description: _descriptionController.text.trim(),
          street: _streetController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          postcode: _postcodeController.text.trim(),
          country: _countryController.text.trim(),
          selectedLocation: _selectedLocation!,
          onSave: (hours) {
            setState(() {
              _hours = hours;
            });
            _navigateToImageAndCategoryPage();
          },
          initialHours: _hours,
          initialImageURLs: _initialImageURLs,
          initialSelectedKeywords: _selectedKeywords,
        ),
      ),
    );
  }

  void _navigateToImageAndCategoryPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageAndCategorySelection(
          placeId: widget.placeId,
          placeName: _placeNameController.text.trim(),
          description: _descriptionController.text.trim(),
          street: _streetController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          postcode: _postcodeController.text.trim(),
          country: _countryController.text.trim(),
          selectedLocation: _selectedLocation!,
          hours: _hours,
          initialImageURLs: _initialImageURLs,
          initialSelectedKeywords: _selectedKeywords,
        ),
      ),
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
                  builder: (context) => ManagePlace(),
                ),
              );
            },
          ),
          title: Text(
            'Edit Place',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: Color.fromARGB(255, 115, 113, 224),
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Place Name',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _placeNameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter place name',
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Description',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter description',
                ),
                keyboardType: TextInputType.multiline,
                maxLines: null,
                minLines: 3,
              ),
            ),
            if (_selectedLocation != null)
              Column(
                children: [
                  _buildSelectedLocationMap(),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Address',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      controller: _streetController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter street',
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter city',
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      controller: _stateController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter state',
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      controller: _postcodeController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter postcode',
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      controller: _countryController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter country',
                      ),
                    ),
                  ),
                ],
              ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MapScreen(
                        initialLocation: _selectedLocation,
                        onSelectLocation: (location) {
                          setState(() {
                            _selectedLocation = location;
                          });
                          _checkIfAllFieldsAreFilled();
                        },
                      ),
                    ),
                  );
                },
                child: Text(_selectedLocation != null
                    ? 'Edit Location'
                    : 'Select Location'),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: _isNextButtonEnabled
                    ? _navigateToHoursPage
                    : null, // Set onPressed to null when conditions are not met
                child: Text('Next Step'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedLocationMap() {
    return Container(
      height: 200,
      margin: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: IgnorePointer(
        ignoring: true,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _selectedLocation ??
                LatLng(0, 0), // Default to (0, 0) if _selectedLocation is null
            zoom: 15,
          ),
          markers: {
            Marker(
              markerId: MarkerId('selected_location'),
              position: _selectedLocation ??
                  LatLng(
                      0, 0), // Default to (0, 0) if _selectedLocation is null
            ),
          },
          onMapCreated: (GoogleMapController controller) {
            // No need for _selectedLocationMap, removed it
          },
        ),
      ),
    );
  }
}
