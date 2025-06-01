// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
//import 'package:voting/oldRegisterScreen.dart';
//import 'screens/election_screen.dart';
//import 'OTPScreen.dart';
//import 'RegisterPage.dart';
import 'RegisterScreen.dart';
import 'package:flutter/services.dart';
//import 'screens/election_screen.dart';
//import 'welcomescreen.dart';
//import rohit's email OTP screen here
import 'EmailOTPscreen.dart';
import 'package:email_otp/email_otp.dart';
import 'forgotpassOTP.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String emailAddress = "", password = "";
  bool showText = true;
  final authInstance = FirebaseAuth.instance;
  String errorMessage = "";
  String successMessage = "";
  bool showprogress = false;
  bool isFormValid = false;

  void validateForm() {
    setState(() {
      isFormValid = emailAddress.isNotEmpty && password.isNotEmpty;
    });
  }

  Future<void> login() async {
    setState(() {
      showprogress = true;
    });
    try {
      if (isPhoneNumber(emailAddress)) {
        await checkPhoneNumberAndLogin(emailAddress);
      } else {
        await authInstance.signInWithEmailAndPassword(
          email: emailAddress,
          password: password,
        );
        setState(() {
          successMessage = "Logged In Successfully";
          errorMessage = "";
        });
      }
    } on FirebaseAuthException catch (error) {
      setState(() {
        errorMessage = error.message ?? "An unknown error occurred";
        successMessage = "";
      });
    } finally {
      setState(() {
        showprogress = false;
      });
    }
  }

  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  Future<void> sendOtpAndNavigate(BuildContext, String phoneNumber,
      {bool isLogin = true}) async {
    final String userPhoneNumber = phoneNumber; // User phone number

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userPhoneNumber)
          .get();

      if (userDoc.exists) {
        String email = userDoc.get('email');
        String phone = userPhoneNumber;
        // Send OTP before navigating
        bool otpSent = await EmailOTP.sendOTP(email: email);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EmailOTPscreen(
              email: email,
              phone: phone,
              password: password,
              isLogin: true,
            ),
          ),
        );

        if (otpSent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("OTP sent to your email"),
              backgroundColor:
                  Color(0xff4e5dc1), // Set your desired background color
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Failed to send OTP",
                style: TextStyle(fontSize: 17, fontFamily: "Medium"),
              ),
              backgroundColor: Color.fromARGB(255, 254, 44, 29),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "User document not found",
              style: TextStyle(fontSize: 17, fontFamily: "urmed"),
            ),
            backgroundColor: Color.fromARGB(255, 254, 44, 29),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error sending OTP: $e",
            style: const TextStyle(fontSize: 17, fontFamily: "urmed"),
          ),
          backgroundColor: const Color.fromARGB(255, 254, 44, 29),
        ),
      );
    }
  }

  Future<void> sendforgototp(BuildContext, String phoneNumber) async {
    final String userPhoneNumber = phoneNumber; // User phone number

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userPhoneNumber)
          .get();

      if (userDoc.exists) {
        String email = userDoc.get('email');
        String phone = userPhoneNumber;
        // Send OTP before navigating
        bool otpSent = await EmailOTP.sendOTP(email: email);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                forgotpassOTP(email: email, phoneNumber: phone),
          ),
        );

        if (otpSent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("OTP sent to your email"),
              backgroundColor:
                  Color(0xff4e5dc1), // Set your desired background color
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Failed to send OTP",
                style: TextStyle(fontSize: 17, fontFamily: "urmed"),
              ),
              backgroundColor: Color.fromARGB(255, 254, 44, 29),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "User document not found",
              style: TextStyle(fontSize: 17, fontFamily: "urmed"),
            ),
            backgroundColor: Color.fromARGB(255, 254, 44, 29),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error sending OTP: $e",
            style: const TextStyle(fontSize: 17, fontFamily: "urmed"),
          ),
          backgroundColor: const Color.fromARGB(255, 254, 44, 29),
        ),
      );
    }
  }

  // void loginUserWithPhoneNumber(String phone) {
  //   FirebaseAuth auth = FirebaseAuth.instance;
  //   auth.verifyPhoneNumber(
  //     phoneNumber: '+91$phone',
  //     verificationCompleted: (PhoneAuthCredential credential) async {
  //       // Auto sign-in case
  //       try {
  //         await auth.signInWithCredential(credential);
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(
  //             builder: (context) => ElectionScreen(phone: phone,),
  //           ),
  //         );
  //       } catch (e) {
  //         setState(() {
  //           errorMessage = "Sign in failed: ${e.toString()}";
  //           successMessage = "";
  //         });
  //       }
  //     },
  //     verificationFailed: (FirebaseAuthException e) {
  //       setState(() {
  //         errorMessage = "Verification failed: ${e.message}";
  //         successMessage = "";
  //       });
  //     },
  //     codeSent: (String verificationId, int? resendToken) {
  //       Navigator.push(
  //         context,
  //         MaterialPageRoute(
  //           builder: (context) => OTPScreen(
  //             phone: phone,
  //             password: password,
  //             isLogin: true,
  //             verificationId: verificationId,
  //           ),
  //         ),
  //       );
  //     },
  //     codeAutoRetrievalTimeout: (String verificationId) {},
  //   );
  // }

  Future<void> checkPhoneNumberAndLogin(String phone) async {
    setState(() {
      showprogress = true;
    });

    try {
      final DocumentSnapshot userDoc = await usersCollection.doc(phone).get();

      if (userDoc.exists) {
        // Phone number exists, proceed to OTP verification
        sendOtpAndNavigate(context, phone);
      } else {
        // Phone number not registered
        setState(() {
          showprogress = false;
        });
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Center(
                  child: Text("Registration Required",
                      style: TextStyle(fontFamily: "urwbold", fontSize: 24))),
              content: const Text(
                "The phone number you entered is not registered. Please sign up first.",
                style: TextStyle(fontFamily: "urmed", fontSize: 20),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("OK",
                      style: TextStyle(fontFamily: "urmed", fontSize: 18)),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error: ${e.toString()}";
        showprogress = false;
      });
    }
  }

  bool isPhoneNumber(String input) {
    final phoneRegExp = RegExp(r'^\d{10}$');
    return phoneRegExp.hasMatch(input);
  }

  // Helper function to obscure email (new function added)
  String obscureEmail(String email) {
    String start = email[0]; // First character of email
    String lastThree = email.substring(email.length - 3); // Last 3 characters
    String obscured = "*" * (email.length - 4); // Remaining characters as "*"
    return "$start$obscured$lastThree"; // Return formatted email
  }

  // Fetch email based on phone number from Firestore (new function added)
  Future<void> fetchEmailForPhoneNumber(String phone) async {
    try {
      final DocumentSnapshot userDoc = await usersCollection.doc(phone).get();

      if (userDoc.exists) {
        final String email = userDoc['email'];

        showDialog(
          context: context,
          builder: (context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.3,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontFamily: "urmed"),
                        children: [
                          const TextSpan(
                              text:
                                  "We are sending you an OTP on this email: "),
                          TextSpan(
                            text: email,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: "urmed"),
                          ),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: TextButton(
                        onPressed: () {
                          sendforgototp(BuildContext, phone);
                          // Navigator.of(context).pop();
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(
                          //     builder: (context) =>
                          //         forgotpassOTP(email: email, phoneNumber: phone),
                          //   ),
                          // );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xff4e5dc1),
                        ),
                        child: const Text('Confirm',
                            style:
                                TextStyle(fontFamily: "urmed", fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      } else {
        setState(() {
          errorMessage = "Phone number not registered.";
        });
      }
    } catch (e) {
      if (e is AssertionError) {
        if (e.toString().contains('path.isNotEmpty') ||
            e.toString().contains('Document references')) {
          setState(() {
            errorMessage = "Enter Valid Mobile Number";
          });
          print('Enter new phone number');
        } else {
          setState(() {
            errorMessage = "Assertion error: ${e.toString()}";
          });
          print('Assertion error: ${e.toString()}');
        }
      } else if (e is FirebaseException) {
        if (e.message != null &&
            e.message!.contains('a document path must be a non-empty string')) {
          setState(() {
            errorMessage = "Enter Valid Mobile Number";
          });
          print('Enter new phone number');
        } else {
          setState(() {
            errorMessage = "Firebase error: ${e.message}";
          });
          print('Firebase error: ${e.message}');
        }
      } else {
        setState(() {
          errorMessage = "Unexpected error: ${e.toString()}";
        });
        print('Unexpected error: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFb38ae8), Color(0xFF8DAFFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: Center(
                  child: SingleChildScrollView(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20.0),
                      child: Container(
                        color: Colors.transparent,
                        padding: const EdgeInsets.only(
                            top: 20, left: 5, bottom: 20, right: 5),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            showprogress
                                ? LoadingAnimationWidget.discreteCircle(
                                    color: Colors.white,
                                    size: 50,
                                    secondRingColor: Colors.black,
                                    thirdRingColor: Colors.purple)
                                : const SizedBox(),
                            const SizedBox(height: 30),
                            const Text(
                              "Welcome Back,",
                              style: TextStyle(
                                fontSize: 38,
                                color: Colors.white,
                                fontFamily: "urwbold",
                              ),
                            ),
                            const Text(
                              "Glad to see you!",
                              style: TextStyle(
                                fontSize: 29,
                                color: Colors.white,
                                fontFamily: "urmed",
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 60, bottom: 10),
                              child: SizedBox(
                                width: double.infinity,
                                child: TextField(
                                  onChanged: (val) {
                                    emailAddress = val;
                                    validateForm();
                                  },
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(
                                        10), // <-- Added to limit input to 10 digits
                                  ],
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 10, horizontal: 10),
                                    hintText:
                                        "Mobile Number", // Example mobile number
                                    hintStyle: TextStyle(
                                      fontFamily: "urmed",
                                      fontSize: 18,
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.2),
                                    prefixIcon: const Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 10),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.only(top: 2.0),
                                            child: Text(
                                              "+91", // Update the country code to match the image (+62 for Indonesia)
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: "urmed",
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 5, bottom: 15),
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: TextField(
                                      obscureText: showText,
                                      onChanged: (val) {
                                        password = val;
                                        validateForm();
                                      },
                                      onSubmitted: (_) => login(),
                                      decoration: InputDecoration(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 10, horizontal: 10),
                                        hintText: "Password",
                                        hintStyle: TextStyle(
                                            fontFamily: "urmed",
                                            fontSize: 18,
                                            color:
                                                Colors.white.withOpacity(0.6)),
                                        filled: true,
                                        fillColor:
                                            Colors.white.withOpacity(0.2),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: const BorderSide(
                                            color: Colors.white,
                                            width: 1.5,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: const BorderSide(
                                            color: Colors.white,
                                            width: 1.5,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: const BorderSide(
                                            color: Colors.white,
                                            width: 1.5,
                                          ),
                                        ),
                                        suffixIcon: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              showText = !showText;
                                            });
                                          },
                                          child: Icon(
                                            showText
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                            color: const Color(0xff4e5dc1),
                                          ),
                                        ),
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: GestureDetector(
                                        onTap: () async {
                                          // Call to fetch email for the phone number entered by the user (new feature)
                                          await fetchEmailForPhoneNumber(
                                              emailAddress);
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.only(
                                              top: 5.0, right: 7.0),
                                          child: Text(
                                            "Forgot Password?",
                                            style: TextStyle(
                                              fontFamily: "urmed",
                                              color: Colors.white,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 25),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isFormValid
                                    ? () async {
                                        setState(() {
                                          showprogress = true;
                                        });

                                        // Step 1: Check if the mobile number is exactly 10 digits long
                                        if (!isPhoneNumber(emailAddress) ||
                                            emailAddress.length != 10) {
                                          setState(() {
                                            errorMessage =
                                                "Enter a valid 10-digit mobile number";
                                            successMessage = "";
                                          });
                                          setState(() {
                                            showprogress = false;
                                          });
                                          return;
                                        }

                                        try {
                                          // Step 2: Check if the mobile number exists in Firestore
                                          final docSnapshot =
                                              await FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(emailAddress)
                                                  .get();

                                          if (!docSnapshot.exists) {
                                            setState(() {
                                              errorMessage =
                                                  "Mobile number is not registered.";

                                              successMessage = "";
                                            });
                                            setState(() {
                                              showprogress = false;
                                            });
                                            return;
                                          }

                                          // Step 3: Check if the entered password matches the stored password
                                          final data = docSnapshot.data()
                                              as Map<String, dynamic>;
                                          final storedPassword =
                                              data['password'];

                                          if (password != storedPassword) {
                                            setState(() {
                                              errorMessage =
                                                  "You entered incorrect password";
                                              successMessage = "";
                                            });
                                            setState(() {
                                              showprogress = false;
                                            });
                                            return;
                                          }

                                          // If all checks pass, log in successfully
                                          sendOtpAndNavigate(
                                            context,
                                            emailAddress,
                                          );
                                          setState(() {
                                            successMessage =
                                                "Account Logged in successfully";
                                            errorMessage = "";
                                          });
                                        } on FirebaseAuthException catch (error) {
                                          setState(() {
                                            errorMessage = error.message ??
                                                "An unknown error occurred";
                                            successMessage = "";
                                          });
                                        } finally {
                                          setState(() {
                                            showprogress = false;
                                          });
                                        }
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14, horizontal: 0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xff4e5dc1),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    "LOG IN",
                                    style: TextStyle(
                                        fontFamily: "urwbold", fontSize: 19),
                                  ),
                                ),
                              ),
                            ),
                            if (errorMessage.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 25.0),
                                child: Text(
                                  errorMessage,
                                  style: const TextStyle(
                                      color: Color.fromARGB(255, 239, 20, 4),
                                      fontFamily: "urmed",
                                      fontSize: 18),
                                ),
                              ),
                            if (successMessage.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Center(
                                    child: Text(
                                  successMessage,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      color: Color.fromARGB(255, 1, 222, 8),
                                      fontFamily: "urmed"),
                                )),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterPage(),
                    ),
                  );
                },
                child: RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: "Don't have an account? ",
                        style: TextStyle(
                          fontFamily: "urreg",
                          color: Colors.white,
                          fontSize: 19,
                        ),
                      ),
                      TextSpan(
                        text: "Sign Up",
                        style: TextStyle(
                          fontFamily: "urwbold",
                          color: Color.fromARGB(255, 57, 76, 197),
                          fontSize: 18,
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
    );
  }
}
