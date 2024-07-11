import 'dart:async'; // Import Timer
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:commerce_yt/auth/login.dart';
import 'package:commerce_yt/auth/keywords.dart'; // Import the keywords page

class VerificationPage extends StatefulWidget {
  final User user;
  final bool isNewUser;

  VerificationPage({required this.user, required this.isNewUser});

  @override
  _VerificationPageState createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  bool _isVerified = false;
  bool _isVerifying = false;
  late Timer _timer;
  bool _canResendEmail = true;

  @override
  void initState() {
    super.initState();
    _startVerificationCheck();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startVerificationCheck() {
    _timer = Timer.periodic(Duration(seconds: 5), (timer) async {
      await _checkEmailVerified();
    });
  }

Future<void> _checkEmailVerified({bool showSnackBar = false}) async {
    await widget.user.reload();
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _isVerified = user?.emailVerified ?? false;
    });

    // Check emailVerified field in Firestore
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.uid)
        .get();
    final emailVerifiedField = userDoc.data()?['emailVerified'] ?? false;

    if (_isVerified || emailVerifiedField) {
      print('Email is verified or bypassed verification');
      await _transferUserData(widget.user.uid);
      _navigateNext();
    } else if (showSnackBar) {
      print('Email is not verified');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Your email is not verified yet. Please check your inbox.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _transferUserData(String uid) async {
    final pendingUserRef =
        FirebaseFirestore.instance.collection('pendingUsers').doc(uid);
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    final pendingUserSnapshot = await pendingUserRef.get();
    if (pendingUserSnapshot.exists) {
      final userData = pendingUserSnapshot.data()!;

      userData['emailVerified'] = true;

      await userRef.set(userData);

      await pendingUserRef.delete();
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResendEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('You can resend the verification email once every minute.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
      _canResendEmail = false;
    });

    try {
      await widget.user.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification email resent.')),
      );

      Timer(Duration(minutes: 1), () {
        setState(() {
          _canResendEmail = true;
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to resend verification email.')),
      );
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  void _navigateNext() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => KeywordsSelectionPage(userId: widget.user.uid)),
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
                          top: 100 * heightFactor,
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
                            height: 200 * heightFactor,
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  child: Container(
                                    width: 313 * widthFactor,
                                    height: 200 * heightFactor,
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
                                      'Verify Your Email',
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
                                            onPressed: () {
                                              _checkEmailVerified(
                                                  showSnackBar: true);
                                            },
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
                                              'I have verified my email',
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
                                Positioned(
                                  left: 28 * widthFactor,
                                  top: 135 * heightFactor,
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
                                              color: Color.fromARGB(
                                                  255, 255, 62, 48),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned.fill(
                                          child: InkWell(
                                            onTap: _canResendEmail
                                                ? _resendVerificationEmail
                                                : null,
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 10),
                                              alignment: Alignment.center,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.email,
                                                    color: Colors.white,
                                                  ),
                                                  SizedBox(width: 5),
                                                  Text(
                                                    'Resend Verification Email',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize:
                                                          12 * widthFactor,
                                                      fontFamily:
                                                          'SF UI Display',
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
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
                          left: 130 * widthFactor,
                          top: 510 * heightFactor,
                          child: SizedBox(
                            width: 150,
                            height: 17.97,
                            child: Opacity(
                              opacity: 0.50,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => LoginPage()),
                                  );
                                },
                                child: Text(
                                  'Back',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontFamily: 'SF UI Display',
                                    fontWeight: FontWeight.w500,
                                    height: 0.12,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 75 * widthFactor,
                          top: 205 * heightFactor,
                          child: Text(
                            'Verify your email to continue',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20 * widthFactor,
                              fontFamily: 'SF UI Display',
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.none,
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
