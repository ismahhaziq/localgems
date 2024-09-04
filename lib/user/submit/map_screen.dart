import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as location;

class MapScreen extends StatefulWidget {
  final Function(LatLng) onSelectLocation;
  final LatLng? initialLocation; // Existing selected location, nullable

  const MapScreen(
      {Key? key, required this.onSelectLocation, this.initialLocation})
      : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _controller;
  location.Location locationService = location.Location();
  LatLng? _currentLocation;
  LatLng? _selectedLocation; // Store the selected location here
  Set<Marker> _markers = {}; // Set to hold the marker(s) on the map

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _selectedLocation = widget.initialLocation; // Set initial location
  }

  void _onMapTapped(LatLng tappedLocation) {
    setState(() {
      // Clear previous markers (if any)
      _markers.clear();

      // Add a new marker at the tapped location
      _markers.add(
        Marker(
          markerId: MarkerId(tappedLocation.toString()),
          position: tappedLocation,
          infoWindow: InfoWindow(title: 'Selected Location'),
          draggable: true, // Make the marker draggable
          onDragEnd: _onMarkerDragEnd, // Callback when marker is dragged
        ),
      );

      // Update the selected location
      _selectedLocation = tappedLocation;

      // Animate camera to the new selected location
      _controller?.animateCamera(
        CameraUpdate.newLatLng(_selectedLocation!),
      );

      // Pass the selected location back to the previous screen
      widget.onSelectLocation(_selectedLocation!);
    });
  }

  void _onMarkerDragEnd(LatLng position) {
    // Handle marker drag if needed
  }

  Future<void> _getCurrentLocation() async {
    location.LocationData? locationData = await locationService.getLocation();
    setState(() {
      _currentLocation =
          LatLng(locationData.latitude!, locationData.longitude!);
      _addCurrentLocationMarker(); // Add marker once location is available
    });
  }

  void _addCurrentLocationMarker() {
    if (_currentLocation != null) {
      _markers.add(
        Marker(
          markerId: MarkerId('current_location'),
          position: _currentLocation!,
          infoWindow: InfoWindow(title: 'Current Location'),
          draggable: true, // Make the marker draggable
          onDragEnd: _onMarkerDragEnd, // Callback when marker is dragged
        ),
      );
    }
  }

  void _updateMarkerPosition(LatLng newPosition) {
    setState(() {
      // Clear previous markers (if any)
      _markers.clear();

      // Add a new marker at the updated position
      _markers.add(
        Marker(
          markerId: MarkerId(newPosition.toString()),
          position: newPosition,
          infoWindow: InfoWindow(title: 'Selected Location'),
          draggable: true, // Make the marker draggable
          onDragEnd: _onMarkerDragEnd, // Callback when marker is dragged
        ),
      );

      // Update the selected location
      _selectedLocation = newPosition;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Location'),
      ),
      body: Stack(
        children: [
          _buildGoogleMap(),
          _buildDropPinButton(),
        ],
      ),
    );
  }

  Widget _buildGoogleMap() {
    return _currentLocation != null
        ? GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation ??
                  _currentLocation!, // Initial map position at user's location
              zoom: 15, // Zoom level
            ),
            markers: _markers, // Set of markers to display on the map
            onTap: _onMapTapped, // Callback when map is tapped
            onCameraMove: (CameraPosition newPosition) {
              _updateMarkerPosition(newPosition.target);
            }, // Update marker position on camera move
            onMapCreated: (GoogleMapController controller) {
              _controller = controller;
              _addCurrentLocationMarker(); // Add marker once map is created
            },
          )
        : Center(
            child: CircularProgressIndicator(),
          );
  }

  Widget _buildDropPinButton() {
    return Positioned(
      bottom: 20, // Adjust the bottom position as needed
      left: 0,
      right: 0,
      child: Center(
        child: FloatingActionButton(
          onPressed: () {
            widget.onSelectLocation(
                _selectedLocation!); // Pass the selected location back
            Navigator.pop(context); // Pop the map screen
          },
          child: Icon(Icons.check),
        ),
      ),
    );
  }
}
