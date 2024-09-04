import 'package:commerce_yt/user/home/welcome.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:commerce_yt/user/home/nav_bar.dart'; // Import NavBar

class KeywordsSelectionPage extends StatefulWidget {
  final String userId;

  KeywordsSelectionPage({required this.userId});

  @override
  _KeywordsSelectionPageState createState() => _KeywordsSelectionPageState();
}

class _KeywordsSelectionPageState extends State<KeywordsSelectionPage> {
  final List<String> keywords = [
    "restaurant",
    "cafe",
    "bar",
    "diner",
    "park",
    "garden",
    "forest",
    "beach",
    "museum",
    "monument",
    "mosque"
  ];
  final List<String> selectedKeywords = [];

  void _toggleSelection(String keyword) {
    setState(() {
      if (selectedKeywords.contains(keyword)) {
        selectedKeywords.remove(keyword);
      } else {
        selectedKeywords.add(keyword);
      }
    });
  }

  Future<void> _saveKeywords() async {
    if (selectedKeywords.isEmpty) {
      _showSelectionError();
      return;
    }
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .update({
      'selectedKeywords': selectedKeywords,
    });
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (context) => NavBar()), // Navigate to WelcomePage
      (route) => false,
    );
  }

  void _showSelectionError() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Selection Error'),
          content: Text('Please select at least one interest to continue.'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double baseWidth = 400;
    double baseHeight = 812;

    double widthFactor = screenWidth / baseWidth;
    double heightFactor = screenHeight / baseHeight;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: screenWidth,
                    height: screenHeight,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(color: Color(0xFFFFFFFF)),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          top: 0,
                          child: Container(
                            width: screenWidth,
                            height: 392 * heightFactor,
                            decoration: ShapeDecoration(
                              color: Color(0xFF7371E0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: -40 * widthFactor,
                          top: 95 * heightFactor,
                          child: SizedBox(
                            width: 490 * widthFactor,
                            height: 101 * heightFactor,
                            child: Text(
                              'LOCALGEMS',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFFFDFDFD),
                                fontSize: 47 * widthFactor,
                                fontFamily: 'SF UI Display',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          top: 0,
                          child: Container(
                            width: screenWidth,
                            height: 44 * heightFactor,
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 336 * widthFactor,
                                  top: 17.33 * heightFactor,
                                  child: Container(
                                    width: 24.33 * widthFactor,
                                    height: 11.33 * heightFactor,
                                    child: Stack(children: []),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 45 * widthFactor,
                          top: 290 * heightFactor,
                          child: Container(
                            width: 313 * widthFactor,
                            height: 490 * heightFactor,
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  child: Container(
                                    width: 313 * widthFactor,
                                    height: 490 * heightFactor,
                                    decoration: ShapeDecoration(
                                      color: Color(0xFDFDFDFD),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      shadows: [
                                        BoxShadow(
                                          color: Color(0x0C000000),
                                          blurRadius: 35,
                                          offset: Offset(20, 20),
                                          spreadRadius: 0,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 86 * widthFactor,
                                  top: 29.60 * heightFactor,
                                  child: SizedBox(
                                    width: 200 * widthFactor,
                                    height: 24.31 * heightFactor,
                                    child: Text(
                                      'Select Your Interests',
                                      style: TextStyle(
                                        color: Color(0xFF616161),
                                        fontSize: 16 * widthFactor,
                                        fontFamily: 'SF UI Display',
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 28 * widthFactor,
                                  top: 70 * heightFactor,
                                  child: Container(
                                    width: 257 * widthFactor,
                                    height: 360 * heightFactor,
                                    child: SingleChildScrollView(
                                      child: Wrap(
                                        spacing: 8.0,
                                        runSpacing: 8.0,
                                        children: keywords.map((keyword) {
                                          return Container(
                                            width: 120 * widthFactor,
                                            child: ChoiceChip(
                                              label: Center(
                                                child: Text(
                                                  keyword,
                                                  style: TextStyle(
                                                    color: selectedKeywords
                                                            .contains(keyword)
                                                        ? Colors.white
                                                        : Colors.black,
                                                  ),
                                                ),
                                              ),
                                              selected: selectedKeywords
                                                  .contains(keyword),
                                              onSelected: (_) =>
                                                  _toggleSelection(keyword),
                                              selectedColor: Color(0xFF7371E0),
                                              backgroundColor: Colors.grey[200],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 28 * widthFactor,
                                  top: 430 * heightFactor,
                                  child: Container(
                                    width: 257 * widthFactor,
                                    height: 36 * heightFactor,
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          left: 0,
                                          top: 0,
                                          child: Container(
                                            width: 257 * widthFactor,
                                            height: 36 * heightFactor,
                                            decoration: ShapeDecoration(
                                              color: Color(0xFF7371E0),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned.fill(
                                          child: ElevatedButton(
                                            onPressed: _saveKeywords,
                                            style: ButtonStyle(
                                              backgroundColor:
                                                  MaterialStateProperty.all<
                                                      Color>(Color(0xFF7371E0)),
                                              shape: MaterialStateProperty.all<
                                                  OutlinedBorder>(
                                                RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(3),
                                                ),
                                              ),
                                              shadowColor: MaterialStateProperty
                                                  .all<Color>(
                                                      Colors.transparent),
                                            ),
                                            child: Text(
                                              'Next',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12 * widthFactor,
                                                fontFamily: 'SF UI Display',
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 180 * heightFactor,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'Choose your interests to get\npersonalized recommendations',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16 * widthFactor,
                                fontFamily: 'SF UI Display',
                                fontWeight: FontWeight.w500,
                                height: 1.5,
                                decoration: TextDecoration.none,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
