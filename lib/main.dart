import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'splash_screen.dart';
import 'firebase_options.dart';
import 'auth/login.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async'; // Import Timer
import 'package:commerce_yt/admin/homeadmin.dart';
import 'package:commerce_yt/admin/manageplace/manageplace.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Timer? _backgroundTimer; // Timer to track background duration
  final int _maxBackgroundDuration = 180; // Max duration in seconds

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Enable Performance Monitoring
    FirebasePerformance.instance.setPerformanceCollectionEnabled(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _backgroundTimer?.cancel(); // Cancel timer if it's running
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App goes to background
      _startBackgroundTimer();
    } else if (state == AppLifecycleState.resumed) {
      // App comes to foreground
      _backgroundTimer?.cancel();
    } else if (state == AppLifecycleState.detached) {
      // App is closed
      _logoutUser();
    }
  }

  void _startBackgroundTimer() {
    _backgroundTimer = Timer(Duration(seconds: _maxBackgroundDuration), () {
      // Time exceeded max background duration, log out user
      _logoutUser();
    });
  }

  void _logoutUser() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LocalGems',
      home: SplashScreen(), // Show SplashScreen first
      routes: {
        '/homeadmin': (context) => HomeAdmin(),
        '/manageplace': (context) => ManagePlace(),
        '/login': (context) => LoginPage(),
      },
    );
  }
}
