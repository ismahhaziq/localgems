import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:shared_preferences/shared_preferences.dart';
import 'hours_selection.dart';
import 'image_and_category_selection.dart';
import 'map_screen.dart';

class SubmitPlace extends StatefulWidget {
  @override
  _SubmitPlaceState createState() => _SubmitPlaceState();
}

class _SubmitPlaceState extends State<SubmitPlace> {
  final TextEditingController _placeNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _postcodeController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();

  final picker = ImagePicker();
  LatLng? _selectedLocation; // Store the selected location here
  GoogleMapController?
      _selectedLocationMap; // Map controller for the selected location

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
    _checkLocationPermissionStatus();
  }

  void _checkLocationPermissionStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? locationPermissionGranted =
        prefs.getBool('locationPermissionGranted');

    if (locationPermissionGranted != null && locationPermissionGranted) {
      setState(() {
        // Do nothing, as we only need to check the status.
      });
    }
  }

  @override
  void dispose() {
    _placeNameController.dispose();
    _descriptionController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postcodeController.dispose();
    _countryController.dispose();
    super.dispose();
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
        ),
      ),
    );
  }

  void _navigateToImageAndCategoryPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageAndCategorySelection(
          placeName: _placeNameController.text.trim(),
          description: _descriptionController.text.trim(),
          street: _streetController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          postcode: _postcodeController.text.trim(),
          country: _countryController.text.trim(),
          selectedLocation: _selectedLocation!,
          hours: _hours, // Pass the hours data
        ),
      ),
    );
  }

  void _selectLocation(LatLng location) async {
    setState(() {
      _selectedLocation = location;
    });

    List<geocoding.Placemark> placemarks =
        await geocoding.placemarkFromCoordinates(
      location.latitude,
      location.longitude,
    );

    if (placemarks.isNotEmpty) {
      geocoding.Placemark placemark = placemarks.first;
      setState(() {
        _streetController.text = placemark.street ?? '';
        _cityController.text = placemark.locality ?? '';
        _stateController.text = placemark.administrativeArea ?? '';
        _postcodeController.text = placemark.postalCode ?? '';
        _countryController.text = placemark.country ?? '';
      });

      // Check if all fields are filled after selecting a location
      _checkIfAllFieldsAreFilled();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            'Add Place',
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
                  if (_selectedLocation == null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MapScreen(
                          onSelectLocation: _selectLocation,
                        ),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MapScreen(
                          initialLocation: _selectedLocation!,
                          onSelectLocation: _selectLocation,
                        ),
                      ),
                    );
                  }
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
            _selectedLocationMap = controller;
          },
          onCameraMove: (CameraPosition newPosition) {
            // Update the selected location when the camera position changes
            _selectedLocation = newPosition.target;
          },
        ),
      ),
    );
  }
}
