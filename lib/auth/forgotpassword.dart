import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:commerce_yt/auth/login.dart';
import 'dart:async'; // Import Timer

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  bool _isVerifying = false;
  bool _canResendEmail = true;

  bool _isValidEmail(String email) {
    String emailRegex = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
    RegExp regex = RegExp(emailRegex);
    return regex.hasMatch(email);
  }

  Future<void> _resetPassword(BuildContext context) async {
    final email = _emailController.text;

    if (email.isEmpty) {
      // Show error message if email field is empty
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter your email address.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_isValidEmail(email)) {
      // Show error message if email is not valid
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid email address.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_canResendEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You can resend the reset email once every minute.'),
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
      await _auth.sendPasswordResetEmail(email: email);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Password reset email has been sent. Please check your email.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Timer(Duration(minutes: 1), () {
        setState(() {
          _canResendEmail = true;
        });
      });
    } catch (e) {
      if (e is FirebaseAuthException) {
        if (e.code == 'user-not-found') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No account found with this email. Please check your email address and try again.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          print('FirebaseAuthException occurred: ${e.message}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('An error occurred. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        print('Error occurred: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
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
                          top: 110 * heightFactor,
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
                            height: 300 * heightFactor,
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  child: Container(
                                    width: 313 * widthFactor,
                                    height: 333 * heightFactor,
                                    decoration: ShapeDecoration(
                                      color: Color(0xFDFDFDFD),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      shadows: [
                                        BoxShadow(
                                          color: Color(0x0C000000),
                                          blurRadius: 35,
                                          offset: Offset(0, 20),
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
                                      'Forgot Password',
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
                                                  borderRadius:
                                                      BorderRadius.circular(4),
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
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4)),
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
                                          left: 0,
                                          top: 0,
                                          child: Container(
                                            width: 252 * widthFactor,
                                            height: 44 * heightFactor,
                                            child: TextFormField(
                                              controller: _emailController,
                                              decoration: InputDecoration(
                                                border: InputBorder.none,
                                                contentPadding: EdgeInsets.only(
                                                    left: 20, top: 12),
                                                hintText:
                                                    'Enter your email address',
                                                hintStyle: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12 * widthFactor,
                                                  fontFamily: 'SF UI Display',
                                                  fontWeight: FontWeight.w500,
                                                ),
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
                                  top: 160 * heightFactor,
                                  child: Container(
                                    width: 252 * widthFactor,
                                    height: 36 * heightFactor,
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: ElevatedButton(
                                            onPressed: _isVerifying
                                                ? null
                                                : () => _resetPassword(context),
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
                                              _isVerifying
                                                  ? 'Please wait...'
                                                  : 'Reset Password',
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
                                  left:
                                      83, // Adjust left position to center horizontally
                                  top: 240, // Adjust top position as needed
                                  child: SizedBox(
                                    width: 150 * widthFactor,
                                    height: 17.97 * heightFactor,
                                    child: Opacity(
                                      opacity: 0.50,
                                      child: TextButton(
                                        onPressed: () {
                                          Navigator.push(
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
                                  left: 83 * widthFactor,
                                  top: 219 * heightFactor,
                                  child: SizedBox(
                                    width: 150 * widthFactor,
                                    height: 17.97 * heightFactor,
                                    child: Opacity(
                                      opacity: 0.50,
                                      child: TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) => LoginPage()),
                                          );
                                        },
                                        child: Text(
                                          'Back',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 12 * widthFactor,
                                            fontFamily: 'SF UI Display',
                                            fontWeight: FontWeight.w500,
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
                                      ),
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
                            'Recover Your Account',
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
