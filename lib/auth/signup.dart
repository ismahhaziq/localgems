import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart';
import 'package:commerce_yt/user/home/welcome.dart';
import 'package:commerce_yt/user/home/nav_bar.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:commerce_yt/auth/verification.dart';
import 'package:commerce_yt/admin/homeadmin.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String _usernameError = '';
  String _emailError = '';
  String _passwordError = '';
  String _confirmPasswordError = '';
  String _error = '';

  Future<void> _signUp() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(child: CircularProgressIndicator());
      },
    );

    try {
      final String username = _usernameController.text;
      final String email = _emailController.text.trim();
      final String password = _passwordController.text;

      if (!_isValidEmail(email)) {
        setState(() {
          _emailError = "Please enter a valid email address.";
        });
        _startErrorTimer();
        Navigator.pop(context);
        return;
      }

      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        String uid = userCredential.user!.uid;

        await _firestore.collection('pendingUsers').doc(uid).set({
          'uid': uid,
          'username': username,
          'email': email,
          'user_type': 'user',
          'profileImageUrl': 'https://jeffjbutler.com/wp-content/uploads/2018/01/default-user.png',
          'emailVerified': false,
          'createdAt': Timestamp.now(),
        });

        await userCredential.user!.sendEmailVerification();

        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => VerificationPage(user: userCredential.user!, isNewUser: true)),
        );
      }
    } catch (error) {
      Navigator.pop(context);
      final errorMessage = (error as FirebaseAuthException).message;
      setState(() {
        if (errorMessage != null &&
            errorMessage.contains("The email address is already in use by another account.")) {
          _emailError = "Email address is already in use.";
        } else {
          _error = errorMessage ?? 'An error occurred';
        }
      });
      _startErrorTimer();
    }
  }

  bool _isValidEmail(String email) {
    String emailRegex = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
    RegExp regex = RegExp(emailRegex);
    return regex.hasMatch(email);
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();
      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication = await googleSignInAccount.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Center(
              child: CircularProgressIndicator(),
            );
          },
        );

        final UserCredential userCredential = await _auth.signInWithCredential(credential);

        if (userCredential.user != null) {
          await userCredential.user!.reload();

          String email = userCredential.user!.email ?? '';
          String displayName = googleSignInAccount.displayName ?? '';
          String userUid = userCredential.user!.uid;

          final DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('users').doc(userUid).get();
          if (!snapshot.exists) {
            await FirebaseFirestore.instance.collection('users').doc(userUid).set({
              'username': displayName,
              'email': email,
              'user_type': 'user',
              'profileImageUrl': 'https://jeffjbutler.com/wp-content/uploads/2018/01/default-user.png',
              'emailVerified': false,
              'createdAt' : Timestamp.now(),
            });

            await userCredential.user!.sendEmailVerification();

            Navigator.pop(context);

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => VerificationPage(user: userCredential.user!, isNewUser: true)),
            );
          } else {
            Navigator.pop(context);

            final userData = snapshot.data() as Map<String, dynamic>;
            if (userCredential.user!.emailVerified) {
              await FirebaseFirestore.instance.collection('users').doc(userUid).update({
                'emailVerified': true
              });

              if (userData['user_type'] == 'admin') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => HomeAdmin()),
                );
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => NavBar()),
                );
              }
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => VerificationPage(user: userCredential.user!, isNewUser: false)),
              );
            }
          }
        }
      }
    } catch (error) {
      Navigator.pop(context);
      print('Error signing in with Google: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to sign in with Google. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _validateFields() {
    bool isValid = true;
    setState(() {
      if (_usernameController.text.isEmpty) {
        _usernameError = "Please enter an username.";
        isValid = false;
      } else {
        _usernameError = '';
      }

      if (_emailController.text.trim().isEmpty) {
        _emailError = "Please enter an email address.";
        isValid = false;
      } else {
        _emailError = '';
      }

      if (_passwordController.text.isEmpty) {
        _passwordError = "Please enter a password.";
        isValid = false;
      } else if (_passwordController.text.length < 6) {
        _passwordError = "Password should be at least 6 characters.";
        isValid = false;
      } else {
        _passwordError = '';
      }

      if (_confirmPasswordController.text.isEmpty) {
        _confirmPasswordError = "Please confirm your password.";
        isValid = false;
      } else if (_confirmPasswordController.text != _passwordController.text) {
        _confirmPasswordError = "Passwords don't match.";
        isValid = false;
      } else {
        _confirmPasswordError = '';
      }
    });
    return isValid;
  }

  void _onCreateAccountPressed() {
    bool isValid = _validateFields();
    if (isValid) {
      _signUp();
    } else {
      _startErrorTimer();
    }
  }

  void _startErrorTimer() {
    Timer(Duration(seconds: 2), () {
      setState(() {
        _usernameError = '';
        _emailError = '';
        _passwordError = '';
        _confirmPasswordError = '';
      });
    });
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
                          top: 105 * heightFactor,
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
                          left: 105 * widthFactor,
                          top: 750 * heightFactor,
                          child: Row(
                            children: [
                              Text(
                                'Already have an account? ',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 12 * widthFactor,
                                  fontFamily: 'SF UI Display',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => LoginPage()),
                                  );
                                },
                                child: Text(
                                  'Sign in Here',
                                  style: TextStyle(
                                    color: Color(0xFF7371E0),
                                    fontSize: 12 * widthFactor,
                                    fontFamily: 'SF UI Display',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          left: 45 * widthFactor,
                          top: 290 * heightFactor,
                          child: Container(
                            width: 313 * widthFactor,
                            height: 460 * heightFactor,
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  child: Container(
                                    width: 313 * widthFactor,
                                    height: 460 * heightFactor,
                                    decoration: ShapeDecoration(
                                      color: Color(0xFDFDFDFD),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20)),
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
                                      'Create an Account',
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
                                  top: 340 * heightFactor,
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
                                                borderRadius: BorderRadius.circular(3),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned.fill(
                                          child: ElevatedButton(
                                            onPressed: _onCreateAccountPressed,
                                            style: ButtonStyle(
                                              backgroundColor: MaterialStateProperty.all<Color>(
                                                  Color(0xFF7371E0)),
                                              shape: MaterialStateProperty.all<OutlinedBorder>(
                                                RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(3),
                                                ),
                                              ),
                                              shadowColor: MaterialStateProperty.all<Color>(
                                                  Colors.transparent),
                                            ),
                                            child: Text(
                                              'Create Account',
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
                                  left: 110 * widthFactor,
                                  top: 385 * heightFactor,
                                  child: Text(
                                    'Or connect using',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 12 * widthFactor,
                                      fontFamily: 'SF UI Display',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 28 * widthFactor,
                                  top: 410 * heightFactor,
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
                                              color: Color.fromARGB(255, 255, 62, 48),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(3),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned.fill(
                                          child: InkWell(
                                            onTap: () => _signInWithGoogle(context),
                                            child: Container(
                                              padding: EdgeInsets.symmetric(horizontal: 10),
                                              alignment: Alignment.center,
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    FontAwesomeIcons.google,
                                                    color: Colors.white,
                                                  ),
                                                  SizedBox(width: 5),
                                                  Text(
                                                    'Google',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12 * widthFactor,
                                                      fontFamily: 'SF UI Display',
                                                      fontWeight: FontWeight.w500,
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
                                Positioned(
                                  left: 31 * widthFactor,
                                  top: 79 * heightFactor,
                                  child: Container(
                                    width: 252 * widthFactor,
                                    height: 51 * heightFactor,
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          left: 0,
                                          top: 7 * heightFactor,
                                          child: Opacity(
                                            opacity: 0.10,
                                            child: Container(
                                              width: 252 * widthFactor,
                                              height: 44 * heightFactor,
                                              decoration: ShapeDecoration(
                                                shape: RoundedRectangleBorder(
                                                  side: BorderSide(width: 1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 101 * widthFactor,
                                          top: 18 * heightFactor,
                                          child: Transform(
                                            transform: Matrix4.identity()
                                              ..translate(0.0, 0.0)
                                              ..rotateZ(3.14),
                                            child: Container(
                                              width: 90 * widthFactor,
                                              height: 18 * heightFactor,
                                              decoration: ShapeDecoration(
                                                color: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(4)),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 17 * widthFactor,
                                          top: 0,
                                          child: Opacity(
                                            opacity: 0.30,
                                            child: Text(
                                              'Username',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 12 * widthFactor,
                                                fontFamily: 'SF UI Display',
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 224 * widthFactor,
                                          top: 22 * heightFactor,
                                          child: Icon(
                                            Icons.person,
                                            size: 20 * widthFactor,
                                            color: Colors.black,
                                          ),
                                        ),
                                        Positioned(
                                          left: 230 * widthFactor,
                                          top: 25 * heightFactor,
                                          child: Container(
                                            width: 7 * widthFactor,
                                            height: 7 * heightFactor,
                                            padding: const EdgeInsets.only(
                                              top: 1.63,
                                              left: 1.02,
                                              right: 0.87,
                                              bottom: 1.46,
                                            ),
                                            clipBehavior: Clip.antiAlias,
                                            decoration: BoxDecoration(),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [],
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 0,
                                          top: 0,
                                          child: Container(
                                            width: 252 * widthFactor,
                                            height: 44 * heightFactor,
                                            child: TextFormField(
                                              controller: _usernameController,
                                              decoration: InputDecoration(
                                                border: InputBorder.none,
                                                contentPadding: EdgeInsets.only(left: 20, top: 12),
                                                hintText: 'Enter your username',
                                                hintStyle: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12 * widthFactor,
                                                  fontFamily: 'SF UI Display',
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                errorText: _usernameError.isNotEmpty ? _usernameError : null,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 31 * widthFactor,
                                  top: 144 * heightFactor,
                                  child: Container(
                                    width: 252 * widthFactor,
                                    height: 51 * heightFactor,
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          left: 0,
                                          top: 7 * heightFactor,
                                          child: Opacity(
                                            opacity: 0.10,
                                            child: Container(
                                              width: 252 * widthFactor,
                                              height: 44 * heightFactor,
                                              decoration: ShapeDecoration(
                                                shape: RoundedRectangleBorder(
                                                  side: BorderSide(width: 1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 101 * widthFactor,
                                          top: 18 * heightFactor,
                                          child: Transform(
                                            transform: Matrix4.identity()
                                              ..translate(0.0, 0.0)
                                              ..rotateZ(3.14),
                                            child: Container(
                                              width: 90 * widthFactor,
                                              height: 18 * heightFactor,
                                              decoration: ShapeDecoration(
                                                color: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(4)),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 17 * widthFactor,
                                          top: 0,
                                          child: Opacity(
                                            opacity: 0.30,
                                            child: Text(
                                              'Email Address',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 12 * widthFactor,
                                                fontFamily: 'SF UI Display',
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 224 * widthFactor,
                                          top: 22 * heightFactor,
                                          child: Icon(
                                            Icons.email,
                                            size: 20 * widthFactor,
                                            color: Colors.black,
                                          ),
                                        ),
                                        Positioned(
                                          left: 230 * widthFactor,
                                          top: 25 * heightFactor,
                                          child: Container(
                                            width: 7 * widthFactor,
                                            height: 7 * heightFactor,
                                            padding: const EdgeInsets.only(
                                              top: 1.63,
                                              left: 1.02,
                                              right: 0.87,
                                              bottom: 1.46,
                                            ),
                                            clipBehavior: Clip.antiAlias,
                                            decoration: BoxDecoration(),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [],
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 0,
                                          top: 0,
                                          child: Container(
                                            width: 252 * widthFactor,
                                            height: 44 * heightFactor,
                                            child: TextFormField(
                                              controller: _emailController,
                                              decoration: InputDecoration(
                                                border: InputBorder.none,
                                                contentPadding: EdgeInsets.only(left: 20, top: 12),
                                                hintText: 'Enter your email address',
                                                hintStyle: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12 * widthFactor,
                                                  fontFamily: 'SF UI Display',
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                errorText: _emailError.isNotEmpty ? _emailError : null,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 31 * widthFactor,
                                  top: 209 * heightFactor,
                                  child: Container(
                                    width: 252 * widthFactor,
                                    height: 51 * heightFactor,
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          left: 0,
                                          top: 7 * heightFactor,
                                          child: Opacity(
                                            opacity: 0.10,
                                            child: Container(
                                              width: 252 * widthFactor,
                                              height: 44 * heightFactor,
                                              decoration: ShapeDecoration(
                                                shape: RoundedRectangleBorder(
                                                  side: BorderSide(width: 1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 77 * widthFactor,
                                          top: 18 * heightFactor,
                                          child: Transform(
                                            transform: Matrix4.identity()
                                              ..translate(0.0, 0.0)
                                              ..rotateZ(3.14),
                                            child: Container(
                                              width: 66 * widthFactor,
                                              height: 18 * heightFactor,
                                              decoration: ShapeDecoration(
                                                color: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(4)),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 17 * widthFactor,
                                          top: 0,
                                          child: Opacity(
                                            opacity: 0.30,
                                            child: Text(
                                              'Password',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 12 * widthFactor,
                                                fontFamily: 'SF UI Display',
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 224 * widthFactor,
                                          top: 22 * heightFactor,
                                          child: Icon(
                                            Icons.password,
                                            size: 20 * widthFactor,
                                            color: Colors.black,
                                          ),
                                        ),
                                        Positioned(
                                          left: 0,
                                          top: 0,
                                          child: Container(
                                            width: 252 * widthFactor,
                                            height: 44 * heightFactor,
                                            child: TextFormField(
                                              controller: _passwordController,
                                              obscureText: true,
                                              decoration: InputDecoration(
                                                border: InputBorder.none,
                                                contentPadding: EdgeInsets.only(left: 20, top: 12),
                                                hintText: 'Enter your password',
                                                hintStyle: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12 * widthFactor,
                                                  fontFamily: 'SF UI Display',
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                errorText: _passwordError.isNotEmpty ? _passwordError : null,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 31 * widthFactor,
                                  top: 274 * heightFactor,
                                  child: Container(
                                    width: 252 * widthFactor,
                                    height: 51 * heightFactor,
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          left: 0,
                                          top: 7 * heightFactor,
                                          child: Opacity(
                                            opacity: 0.10,
                                            child: Container(
                                              width: 252 * widthFactor,
                                              height: 44 * heightFactor,
                                              decoration: ShapeDecoration(
                                                shape: RoundedRectangleBorder(
                                                  side: BorderSide(width: 1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 122 * widthFactor,
                                          top: 18 * heightFactor,
                                          child: Transform(
                                            transform: Matrix4.identity()
                                              ..translate(0.0, 0.0)
                                              ..rotateZ(3.14),
                                            child: Container(
                                              width: 108 * widthFactor,
                                              height: 18 * heightFactor,
                                              decoration: ShapeDecoration(
                                                color: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(4)),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 17 * widthFactor,
                                          top: 0,
                                          child: Opacity(
                                            opacity: 0.30,
                                            child: Text(
                                              'Confirm Password',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 12 * widthFactor,
                                                fontFamily: 'SF UI Display',
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 224 * widthFactor,
                                          top: 22 * heightFactor,
                                          child: Icon(
                                            Icons.lock,
                                            size: 20 * widthFactor,
                                            color: Colors.black,
                                          ),
                                        ),
                                        Positioned(
                                          left: 0,
                                          top: 0,
                                          child: Container(
                                            width: 252 * widthFactor,
                                            height: 44 * heightFactor,
                                            child: TextFormField(
                                              controller: _confirmPasswordController,
                                              obscureText: true,
                                              decoration: InputDecoration(
                                                border: InputBorder.none,
                                                contentPadding: EdgeInsets.only(left: 20, top: 12),
                                                hintText: 'Re-enter your password',
                                                hintStyle: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12 * widthFactor,
                                                  fontFamily: 'SF UI Display',
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                errorText: _confirmPasswordError.isNotEmpty ? _confirmPasswordError : null,
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
                          left: 105 * widthFactor,
                          top: 196 * heightFactor,
                          child: Text(
                            'Discover the Unseen',
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
