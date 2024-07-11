import 'package:flutter/material.dart';
import 'login.dart'; // Import your login page for navigation

class CreateNewPasswordPage extends StatelessWidget {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final String email; // Email received from the password reset link

  CreateNewPasswordPage({required this.email});

  Future<void> _createNewPassword(BuildContext context) async {
    try {
      final String newPassword = _passwordController.text;
      final String confirmPassword = _confirmPasswordController.text;

      // Check if passwords match
      if (newPassword != confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Passwords do not match.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Update the user's password using Firebase Auth
     // await _auth.confirmPasswordReset(email: email, newPassword: newPassword);

      // Display success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Password has been successfully updated.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to login page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
    } catch (error) {
      // Handle any errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: double.infinity,
                    height: 812,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(color: Color(0xFFFFFFFF)),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          top: 0,
                          child: Container(
                            width: 412,
                            height: 392,
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
                          left: -40,
                          top: 134,
                          child: SizedBox(
                            width: 490,
                            height: 101,
                            child: Text(
                              'LOCALGEMS',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFFFDFDFD),
                                fontSize: 47,
                                fontFamily: 'SF UI Display',
                                fontWeight: FontWeight.w700,
                                height: 0.03,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          top: 0,
                          child: Container(
                            width: 375,
                            height: 44,
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 336,
                                  top: 17.33,
                                  child: Container(
                                    width: 24.33,
                                    height: 11.33,
                                    child: Stack(children: []),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 45,
                          top: 290,
                          child: Container(
                            width: 313,
                            height: 300,
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  child: Container(
                                    width: 313,
                                    height: 333,
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
                                  left: 86,
                                  top: 29.60,
                                  child: SizedBox(
                                    width: 200,
                                    height: 24.31,
                                    child: Text(
                                      'Create New Password',
                                      style: TextStyle(
                                        color: Color(0xFF616161),
                                        fontSize: 16,
                                        fontFamily: 'SF UI Display',
                                        fontWeight: FontWeight.w700,
                                        height: 0.09,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 31,
                                  top: 79,
                                  child: Container(
                                    width: 252,
                                    height: 51,
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          left: 0,
                                          top: 7,
                                          child: Opacity(
                                            opacity: 0.10,
                                            child: Container(
                                              width: 252,
                                              height: 44,
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
                                          left: 101,
                                          top: 18,
                                          child: Transform(
                                            transform: Matrix4.identity()
                                              ..translate(0.0, 0.0)
                                              ..rotateZ(3.14),
                                            child: Container(
                                              width: 90,
                                              height: 18,
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
                                          left: 17,
                                          top: 0,
                                          child: Opacity(
                                            opacity: 0.30,
                                            child: Text(
                                              'New Password',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 12,
                                                fontFamily: 'SF UI Display',
                                                fontWeight: FontWeight.w500,
                                                height: 0.12,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 0,
                                          top: 0,
                                          child: Container(
                                            width: 252,
                                            height: 44,
                                            child: TextField(
                                              controller: _passwordController,
                                              decoration: InputDecoration(
                                                border: InputBorder.none,
                                                contentPadding: EdgeInsets.only(
                                                    left: 20, top: 12),
                                                hintText:
                                                    'Enter your new password',
                                                hintStyle: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                  fontFamily: 'SF UI Display',
                                                  fontWeight: FontWeight.w500,
                                                  height: 0.12,
                                                ),
                                              ),
                                              obscureText: true,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 31,
                                  top: 160,
                                  child: Container(
                                    width: 252,
                                    height: 51,
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          left: 0,
                                          top: 7,
                                          child: Opacity(
                                            opacity: 0.10,
                                            child: Container(
                                              width: 252,
                                              height: 44,
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
                                          left: 101,
                                          top: 18,
                                          child: Transform(
                                            transform: Matrix4.identity()
                                              ..translate(0.0, 0.0)
                                              ..rotateZ(3.14),
                                            child: Container(
                                              width: 90,
                                              height: 18,
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
                                          left: 17,
                                          top: 0,
                                          child: Opacity(
                                            opacity: 0.30,
                                            child: Text(
                                              'Confirm Password',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 12,
                                                fontFamily: 'SF UI Display',
                                                fontWeight: FontWeight.w500,
                                                height: 0.12,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 0,
                                          top: 0,
                                          child: Container(
                                            width: 252,
                                            height: 44,
                                            child: TextField(
                                              controller:
                                                  _confirmPasswordController,
                                              decoration: InputDecoration(
                                                border: InputBorder.none,
                                                contentPadding: EdgeInsets.only(
                                                    left: 20, top: 12),
                                                hintText: 'Confirm Password',
                                                hintStyle: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                  fontFamily: 'SF UI Display',
                                                  fontWeight: FontWeight.w500,
                                                  height: 0.12,
                                                ),
                                              ),
                                              obscureText: true,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 31,
                                  top: 236,
                                  child: Container(
                                    width: 252,
                                    height: 36,
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: ElevatedButton(
                                            onPressed: () =>
                                                _createNewPassword(context),
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
                                              'Set New Password',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontFamily: 'SF UI Display',
                                                fontWeight: FontWeight.w500,
                                                height: 0.12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 83,
                                  top: 285,
                                  child: SizedBox(
                                    width: 150,
                                    height: 17.97,
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
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 105,
                          top: 262,
                          child: Text(
                            'Recover Your Account',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontFamily: 'SF UI Display',
                              fontWeight: FontWeight.w500,
                              height: 0.07,
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
