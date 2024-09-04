import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'edit_image_and_category_selection.dart';
import 'editplace.dart';

class HoursSelectionPage extends StatefulWidget {
  final String placeId;
  final String placeName;
  final String description;
  final String street;
  final String city;
  final String state;
  final String postcode;
  final String country;
  final LatLng selectedLocation;
  final Function(Map<String, Map<String, dynamic>>) onSave;
  final Map<String, Map<String, dynamic>> initialHours;
  final List<String> initialImageURLs;
  final List<String> initialSelectedKeywords;

  const HoursSelectionPage({
    Key? key,
    required this.placeId,
    required this.placeName,
    required this.description,
    required this.street,
    required this.city,
    required this.state,
    required this.postcode,
    required this.country,
    required this.selectedLocation,
    required this.onSave,
    required this.initialHours,
    required this.initialImageURLs,
    required this.initialSelectedKeywords,
  }) : super(key: key);

  @override
  _HoursSelectionPageState createState() => _HoursSelectionPageState();
}

class _HoursSelectionPageState extends State<HoursSelectionPage> {
  late Map<String, Map<String, dynamic>> _hours;
  List<String> _selectedDays = [];

  @override
  void initState() {
    super.initState();
    _hours = Map.from(widget.initialHours);
  }

  void _selectTime(String day, String type) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _hours[day]![type] = picked;
        _hours[day]!['closed'] = false;
        _hours[day]!['allDay'] = false;
        _validateTimes();
      });
    }
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    final format = DateFormat.jm();
    return format.format(dt);
  }

  void _setClosed(String day, bool value) {
    setState(() {
      _hours[day]!['closed'] = value;
      if (value) {
        _hours[day]!['open'] = null;
        _hours[day]!['close'] = null;
        _hours[day]!['allDay'] = false;
      }
      _validateTimes();
    });
  }

  void _setAllDay(String day, bool value) {
    setState(() {
      _hours[day]!['allDay'] = value;
      if (value) {
        _hours[day]!['open'] = null;
        _hours[day]!['close'] = null;
        _hours[day]!['closed'] = false;
      }
      _validateTimes();
    });
  }

  void _applySameHours() {
    if (_selectedDays.isEmpty) return;

    final openTime = _hours[_selectedDays.first]!['open'];
    final closeTime = _hours[_selectedDays.first]!['close'];

    setState(() {
      for (String day in _selectedDays) {
        _hours[day]!['open'] = openTime;
        _hours[day]!['close'] = closeTime;
        _hours[day]!['closed'] = false;
        _hours[day]!['allDay'] = false;
        _hours[day]!['individual'] = false;
      }
    });
    _validateTimes();
  }

  bool _validateTimes() {
    bool isValid = true;
    _hours.forEach((day, times) {
      if (times['open'] != null && times['close'] == null) {
        isValid = false;
      } else if (times['open'] == null && times['close'] != null) {
        isValid = false;
      }
    });
    return isValid;
  }

  void _showValidationError() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Validation Error'),
          content: Text('Please select the Start Time and End Time'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> daysOfWeek = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

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
                  builder: (context) => EditPlace(placeId: widget.placeId),
                ),
              );
            },
          ),
          title: Text(
            'Edit Hours of Operation',
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
      body: ListView(
        children: [
          Wrap(
            spacing: 8.0,
            children: daysOfWeek.map((day) {
              return FilterChip(
                label: Text(day),
                selected: _selectedDays.contains(day),
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      _selectedDays.add(day);
                    } else {
                      _selectedDays.remove(day);
                    }
                  });
                },
              );
            }).toList(),
          ),
          if (_selectedDays.isNotEmpty)
            Column(
              children: [
                CheckboxListTile(
                  title: Text('Closed'),
                  value: _selectedDays
                      .any((day) => _hours[day]!['closed'] == true),
                  onChanged: (bool? value) {
                    for (String day in _selectedDays) {
                      _setClosed(day, value!);
                    }
                  },
                ),
                CheckboxListTile(
                  title: Text('24 Hours'),
                  value: _selectedDays
                      .any((day) => _hours[day]!['allDay'] == true),
                  onChanged: (bool? value) {
                    for (String day in _selectedDays) {
                      _setAllDay(day, value!);
                    }
                  },
                ),
                if (!_selectedDays.any((day) =>
                    _hours[day]!['closed'] == true ||
                    _hours[day]!['allDay'] == true))
                  Column(
                    children: [
                      ListTile(
                        title: Text('Start Time'),
                        trailing: Text(
                            _formatTime(_hours[_selectedDays.first]!['open'])),
                        onTap: () => _selectTime(_selectedDays.first, 'open'),
                      ),
                      ListTile(
                        title: Text('End Time'),
                        trailing: Text(
                            _formatTime(_hours[_selectedDays.first]!['close'])),
                        onTap: () => _selectTime(_selectedDays.first, 'close'),
                      ),
                      ElevatedButton(
                        onPressed: _applySameHours,
                        child: Text('Apply to Selected Days'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Color(0xFF7472E0),
                          padding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ...daysOfWeek.map((day) {
            return ExpansionTile(
              title: Text(day),
              subtitle: Text(_hours[day]!['closed'] == true
                  ? 'Closed'
                  : _hours[day]!['allDay'] == true
                      ? '24 Hours'
                      : '${_formatTime(_hours[day]!['open'])} - ${_formatTime(_hours[day]!['close'])}'),
              children: [
                CheckboxListTile(
                  title: Text('Closed'),
                  value: _hours[day]!['closed'] == true,
                  onChanged: (bool? value) {
                    _setClosed(day, value!);
                  },
                ),
                CheckboxListTile(
                  title: Text('24 Hours'),
                  value: _hours[day]!['allDay'] == true,
                  onChanged: (bool? value) {
                    _setAllDay(day, value!);
                  },
                ),
                if (_hours[day]!['closed'] != true &&
                    _hours[day]!['allDay'] != true)
                  Column(
                    children: [
                      ListTile(
                        title: Text('Start Time'),
                        trailing: Text(_formatTime(_hours[day]!['open'])),
                        onTap: () => _selectTime(day, 'open'),
                      ),
                      ListTile(
                        title: Text('End Time'),
                        trailing: Text(_formatTime(_hours[day]!['close'])),
                        onTap: () => _selectTime(day, 'close'),
                      ),
                    ],
                  ),
                CheckboxListTile(
                  title: Text('Individual Settings'),
                  value: _hours[day]!['individual'] == true,
                  onChanged: (bool? value) {
                    setState(() {
                      _hours[day]!['individual'] = value!;
                    });
                  },
                ),
              ],
            );
          }).toList(),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          onPressed: () {
            if (!_validateTimes()) {
              _showValidationError();
              return;
            }
            widget.onSave(_hours);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ImageAndCategorySelection(
                  placeId: widget.placeId,
                  placeName: widget.placeName,
                  description: widget.description,
                  street: widget.street,
                  city: widget.city,
                  state: widget.state,
                  postcode: widget.postcode,
                  country: widget.country,
                  selectedLocation: widget.selectedLocation,
                  hours: _hours,
                  initialImageURLs: widget.initialImageURLs,
                  initialSelectedKeywords: widget.initialSelectedKeywords,
                ),
              ),
            );
          },
          child: Text('Next Step'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Color(0xFF7472E0),
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
