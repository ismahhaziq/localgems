import 'package:commerce_yt/admin/homeadmin.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:commerce_yt/admin/profile.dart';
import 'package:commerce_yt/auth/login.dart';

class NavBar extends StatefulWidget {
  final int currentIndex;

  NavBar({this.currentIndex = 0});

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
    _selectedIndex = widget.currentIndex;
  }

  void checkLoginStatus() {
    User? user = FirebaseAuth.instance.currentUser;
    setState(() {
      isLoggedIn = user != null;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeAdmin()),
        );
        break;
      case 1:
        if (isLoggedIn) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ProfilePage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
          );
        }
        break;
      case 2:
        FirebaseAuth.instance.signOut().then((_) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
            (Route<dynamic> route) => false,
          );
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    List<BottomNavigationBarItem> items = [
      BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.account_circle),
        label: 'Account',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.logout),
        label: 'Logout',
      ),
    ];

    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      selectedItemColor: Color(0xFF7472E0),
      unselectedItemColor: Colors.grey,
      items: items,
      onTap: _onItemTapped,
    );
  }
}
