import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'splash_screen.dart';
import 'firebase_options.dart';
import 'auth/login.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:commerce_yt/admin/homeadmin.dart';
import 'package:commerce_yt/admin/manageplace/manageplace.dart';
import 'package:commerce_yt/user/placedetail/placedetail.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final PendingDynamicLinkData? initialLink =
      await FirebaseDynamicLinks.instance.getInitialLink();
  runApp(MyApp(initialLink));
}

class MyApp extends StatefulWidget {
  final PendingDynamicLinkData? initialLink;

  const MyApp(this.initialLink, {Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Enable Performance Monitoring
    FirebasePerformance.instance.setPerformanceCollectionEnabled(true);
    _initDynamicLinks();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      // App is closed
      _logoutUser();
    }
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

  void _initDynamicLinks() async {
    FirebaseDynamicLinks.instance.onLink.listen(
      (PendingDynamicLinkData dynamicLink) async {
        final Uri? deepLink = dynamicLink.link;

        if (deepLink != null) {
          Navigator.pushNamed(context, deepLink.path);
        }
      },
      onError: (Exception e) async {
        print('onLinkError');
        print(e.toString());
      },
    );

    final PendingDynamicLinkData? data =
        await FirebaseDynamicLinks.instance.getInitialLink();
    final Uri? deepLink = data?.link;

    if (deepLink != null) {
      Navigator.pushNamed(context, deepLink.path);
    }
  }

void _handleDeepLink(Uri deepLink) {
    // Assuming your deep link follows the format: https://localgems.com/place/{placeId}
    final uriSegments = deepLink.pathSegments;
    if (uriSegments.isNotEmpty && uriSegments.first == 'place') {
      final placeId = uriSegments[1];
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlaceDetailsPage(
            placeId: placeId,
            distance: 0.0, // Provide a default distance
            userId: FirebaseAuth.instance.currentUser?.uid,
          ),
        ),
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
