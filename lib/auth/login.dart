import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup.dart';
import 'package:commerce_yt/user/home/nav_bar.dart'; // Updated import
import 'forgotpassword.dart';
import 'package:commerce_yt/admin/homeadmin.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Import the Google Sign In package
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore package
import 'package:commerce_yt/auth/verification.dart';
import 'package:commerce_yt/auth/keywords.dart'; // Import the keywords page

class LoginPage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn =
      GoogleSignIn(); // Initialize GoogleSignIn instance
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _signInWithEmailAndPassword(BuildContext context) async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter your email address and password.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      String uid = userCredential.user!.uid;

      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      final emailVerifiedField = snapshot.data()?['emailVerified'] ?? false;

      if (!userCredential.user!.emailVerified && !emailVerifiedField) {
        Navigator.pop(context);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => VerificationPage(
                  user: userCredential.user!, isNewUser: false)),
        );
      } else if (snapshot.exists && snapshot.data()!['user_type'] == 'admin') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => HomeAdmin()),
          (route) => false,
        );
      } else if (snapshot.exists &&
          (snapshot.data()!['selectedKeywords'] == null ||
              (snapshot.data()!['selectedKeywords'] as List).isEmpty)) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  KeywordsSelectionPage(userId: userCredential.user!.uid)),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => NavBar()),
          (route) => false,
        );
      }
    } catch (error) {
      Navigator.pop(context);

      if (error is FirebaseAuthException) {
        print('FirebaseAuthException code: ${error.code}');
        String errorMessage;
        switch (error.code) {
          case 'user-not-found':
            errorMessage =
                'No user found with this email. Please check your email and try again.';
            break;
          case 'wrong-password':
            errorMessage =
                'Incorrect password. Please check your password and try again.';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email address. Please enter a valid email.';
            break;
          default:
            errorMessage =
                'Incorrect password or email. Please check and try again';
            break;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        print('Non-FirebaseAuthException error: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();
      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;

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

        final UserCredential userCredential =
            await _auth.signInWithCredential(credential);

        if (userCredential.user != null) {
          String email = userCredential.user!.email ?? '';
          String displayName = googleSignInAccount.displayName ?? '';
          String userUid = userCredential.user!.uid;

          final DocumentSnapshot snapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(userUid)
              .get();
          if (!snapshot.exists) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userUid)
                .set({
              'username': displayName,
              'email': email,
              'user_type': 'user',
              'profileImageUrl':
                  'https://jeffjbutler.com/wp-content/uploads/2018/01/default-user.png',
              'emailVerified': false,
              'createdAt': Timestamp.now(),
            });

            await userCredential.user!.sendEmailVerification();

            Navigator.pop(context);

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) => VerificationPage(
                      user: userCredential.user!, isNewUser: true)),
              (route) => false,
            );
          } else {
            Navigator.pop(context);

            final userData = snapshot.data() as Map<String, dynamic>;
            final emailVerifiedField = userData['emailVerified'] ?? false;
            if (userCredential.user!.emailVerified || emailVerifiedField) {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userUid)
                  .update({'emailVerified': true});

              if (userData['user_type'] == 'admin') {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => HomeAdmin()),
                  (route) => false,
                );
              } else if (userData['selectedKeywords'] == null ||
                  (userData['selectedKeywords'] as List).isEmpty) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (_) => KeywordsSelectionPage(
                          userId: userCredential.user!.uid)),
                  (route) => false,
                );
              } else {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => NavBar()),
                  (route) => false,
                );
              }
            } else {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) => VerificationPage(
                        user: userCredential.user!, isNewUser: false)),
                (route) => false,
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

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double baseWidth = 400; // Base width used in original design
    double baseHeight = 830; // Base height used in original design

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
                          left: 128 * widthFactor,
                          top: 665 * heightFactor,
                          child: Row(
                            children: [
                              Text(
                                'New Member? ',
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
                                    MaterialPageRoute(
                                        builder: (_) => SignUpPage()),
                                  );
                                },
                                child: Text(
                                  'Sign up Here',
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
                          left: 175 * widthFactor,
                          top: 700 * heightFactor,
                          child: Row(
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(builder: (_) => NavBar()),
                                    (route) => false,
                                  );
                                },
                                child: Text(
                                  'Back',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 15 * widthFactor,
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
                            height: 390 * heightFactor,
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  child: Container(
                                    width: 313 * widthFactor,
                                    height: 375 * heightFactor,
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
                                      'Sign In to Continue',
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
                                  top: 228 * heightFactor,
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
                                            onPressed: () =>
                                                _signInWithEmailAndPassword(
                                                    context),
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
                                              'Log In',
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
                                  top: 275 * heightFactor,
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
                                  top: 305 * heightFactor,
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
                                            onTap: () =>
                                                _signInWithGoogle(context),
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 10),
                                              alignment: Alignment.center,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
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
                                Positioned(
                                  left: 158 * widthFactor,
                                  top: 350 * heightFactor,
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
                                                builder: (_) =>
                                                    ForgotPasswordPage()),
                                          );
                                        },
                                        child: Text(
                                          'Forgot Password',
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
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
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
                                                  borderRadius:
                                                      BorderRadius.circular(4),
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
                                                contentPadding: EdgeInsets.only(
                                                    left: 20, top: 12),
                                                hintText: 'Enter your password',
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
