import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'welcome.dart';
import 'account_not.dart';
import 'account_page.dart';
import 'package:commerce_yt/user/submit/submitplace.dart';

class NavBar extends StatefulWidget {
  @override
  _NavBarState createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  int _selectedIndex = 0;
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
    _checkLocationPermissionStatus();
  }

  void checkLoginStatus() {
    User? user = FirebaseAuth.instance.currentUser;
    setState(() {
      isLoggedIn = user != null;
    });
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> _pages = [
      WelcomePage(),
      if (isLoggedIn) SubmitPlace(),
      if (isLoggedIn) AccountPage() else AccountNotPage(),
    ];

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Color(0xFF7472E0),
        unselectedItemColor: Colors.grey,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          if (isLoggedIn)
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle),
              label: 'Add Place',
            ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Account',
          ),
        ],
        onTap: _onItemTapped,
      ),
    );
  }
}
