import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as location;

class MapScreen extends StatefulWidget {
  final Function(LatLng) onSelectLocation;
  final LatLng? initialLocation;

  const MapScreen({
    Key? key,
    required this.onSelectLocation,
    this.initialLocation,
  }) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _controller;
  location.Location locationService = location.Location();
  LatLng? _currentLocation;
  LatLng? _selectedLocation;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    if (_selectedLocation != null) {
      _markers.add(
        Marker(
          markerId: MarkerId('selected_location'),
          position: _selectedLocation!,
          infoWindow: InfoWindow(title: 'Selected Location'),
        ),
      );
    }
    _getCurrentLocation();
  }

  void _onMapTapped(LatLng tappedLocation) {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: MarkerId(tappedLocation.toString()),
          position: tappedLocation,
          infoWindow: InfoWindow(title: 'Selected Location'),
          draggable: true,
          onDragEnd: _onMarkerDragEnd,
        ),
      );
      _selectedLocation = tappedLocation;
      _controller?.animateCamera(
        CameraUpdate.newLatLng(_selectedLocation!),
      );
      widget.onSelectLocation(_selectedLocation!);
    });
  }

  void _onMarkerDragEnd(LatLng position) {}

  Future<void> _getCurrentLocation() async {
    location.LocationData? locationData = await locationService.getLocation();
    setState(() {
      _currentLocation =
          LatLng(locationData.latitude!, locationData.longitude!);
      if (_selectedLocation == null) {
        _addCurrentLocationMarker();
      }
    });
  }

  void _addCurrentLocationMarker() {
    if (_currentLocation != null) {
      _markers.add(
        Marker(
          markerId: MarkerId('current_location'),
          position: _currentLocation!,
          infoWindow: InfoWindow(title: 'Current Location'),
          draggable: true,
          onDragEnd: _onMarkerDragEnd,
        ),
      );
    }
  }

  void _updateMarkerPosition(LatLng newPosition) {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: MarkerId(newPosition.toString()),
          position: newPosition,
          infoWindow: InfoWindow(title: 'Selected Location'),
          draggable: true,
          onDragEnd: _onMarkerDragEnd,
        ),
      );
      _selectedLocation = newPosition;
    });
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
            'Select Location',
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
      body: Stack(
        children: [
          _buildGoogleMap(),
          _buildDropPinButton(),
        ],
      ),
    );
  }

  Widget _buildGoogleMap() {
    return _currentLocation != null || _selectedLocation != null
        ? GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation ?? _currentLocation!,
              zoom: 15,
            ),
            markers: _markers,
            onTap: _onMapTapped,
            onCameraMove: (CameraPosition newPosition) {
              _updateMarkerPosition(newPosition.target);
            },
            onMapCreated: (GoogleMapController controller) {
              _controller = controller;
              if (_selectedLocation != null) {
                _controller?.animateCamera(
                  CameraUpdate.newLatLng(_selectedLocation!),
                );
              } else {
                _addCurrentLocationMarker();
              }
            },
          )
        : Center(
            child: CircularProgressIndicator(),
          );
  }

  Widget _buildDropPinButton() {
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Center(
        child: FloatingActionButton(
          onPressed: () {
            if (_selectedLocation != null) {
              widget.onSelectLocation(_selectedLocation!);
              Navigator.pop(context);
            }
          },
          child: Icon(Icons.check),
          backgroundColor: Color(0xFF7472E0),
        ),
      ),
    );
  }
}
