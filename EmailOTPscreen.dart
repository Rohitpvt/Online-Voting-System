// ignore_for_file: library_private_types_in_public_api, avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:email_otp/email_otp.dart';
import 'dart:async';
import 'election_screen.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:intl/intl.dart'; // Import intl package
//import 'welcomescreen.dart';

import 'package:shared_preferences/shared_preferences.dart';

class EmailOTPscreen extends StatefulWidget {
  final String? firstName;
  final String? lastName;
  final String password;
  final String? dob; // Date of Birth as a String
  final bool isLogin;
  final String email;
  final String phone;

  const EmailOTPscreen(
      {super.key,
      required this.email,
      required this.phone,
      this.firstName,
      this.lastName,
      required this.password,
      this.dob,
      this.isLogin = false});

  @override
  _EmailOTPscreenState createState() => _EmailOTPscreenState();
}

class _EmailOTPscreenState extends State<EmailOTPscreen> with WidgetsBindingObserver {
  bool _isButtonEnabled = true;
  int _remainingTime = 10;
  Timer? _timer;
  bool _isImageVisible = true; // Track image visibility

  // Create FocusNodes and TextEditingControllers for each OTP box
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addObserver(this);
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _isButtonEnabled = false;
      _remainingTime = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        setState(() {
          _isButtonEnabled = true;
        });
        timer.cancel();
      }
    });
  }

  int _calculateAgeFromDOB(String dob) {
    try {
      final DateFormat dateFormat =
          DateFormat('d/m/yyyy'); // Use the correct format
      final DateTime dobDate = dateFormat.parse(dob);
      final currentYear = DateTime.now().year;
      final birthYear = dobDate.year;
      return currentYear - birthYear;
    } catch (e) {
      print('Error parsing date: $e');
      return 0; // Return 0 if the date format is invalid
    }
  }

  Future<void> _saveUserDataToPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString('phone', widget.phone);
    await prefs.setString('password', widget.password);
    await prefs.setBool('isLoggedIn', true); // Save login state
  }

  void _onResendCode() async {
    // Request a new OTP code
    try {
      bool otpSent = await EmailOTP.sendOTP(
        email: widget.email, // Use the email provided to the page
      );
      if (otpSent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "New OTP sent to your email",
              style: TextStyle(fontSize: 17, fontFamily: "urmed"),
            ),
            backgroundColor:
                Color(0xff4e5dc1), // Set your desired background color
          ),
        );
        _startTimer(); // Restart the timer after sending a new OTP
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Failed to send OTP",
              style: TextStyle(fontSize: 17, fontFamily: "urmed"),
            ),
            backgroundColor: Color.fromARGB(
                255, 254, 44, 29), // Set your desired background color
          ),
        );
      }
    } catch (e) {
      // Handle any errors that might occur
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "An error occurred. Please try again",
            style: TextStyle(fontSize: 17, fontFamily: "urmed"),
          ),
          backgroundColor: Color.fromARGB(
              255, 254, 44, 29), // Set your desired background color
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Dispose the FocusNodes and Controllers
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    for (final controller in _controllers) {
      controller.dispose();
    }
    // Remove the observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    setState(() {
      _isImageVisible =
          !isKeyboardVisible; // Hide image when keyboard is visible
    });
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 5) {
        Future.microtask(() {
          FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
        });
      }
      // Check if all OTP fields are filled
      if (_controllers.every((controller) => controller.text.isNotEmpty)) {
        _verifyOTP();
      }
    }
  }

  void _handleBackspace(int index) {
    if (_controllers[index].text.isEmpty) {
      if (index > 0) {
        FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
        _controllers[index - 1].clear(); // Clear the previous field
      }
    }
  }

  Future<void> _verifyOTP() async {
    String otp = _controllers.map((e) => e.text).join();
    if (otp.length == 6 && await EmailOTP.verifyOTP(otp: otp)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          "OTP verified",
          style: TextStyle(fontSize: 17, fontFamily: "urmed"),
        ),
        backgroundColor: Color(0xff4e5dc1),
      ));

      int age = 0;
      if (widget.dob != null && widget.dob!.isNotEmpty) {
        age = _calculateAgeFromDOB(widget.dob!);
      }
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(widget.phone);
      if (widget.isLogin) {
        await userRef.update({
          'password': widget.password,
          'phoneNumber': widget.phone,
        });
      } else {
        await userRef.set({
          'firstName': widget.firstName ?? '',
          'lastName': widget.lastName ?? '',
          'phoneNumber': widget.phone,
          'email': widget.email,
          'password': widget.password,
          'dob': widget.dob ?? '',
          'Age': age.toString(),
          'hasVoted Delhi CM Election': 'false',
          'hasVoted Mumbai CM Election': 'false',
          'hasVoted Punjab CM Election': 'false',
          'hasVoted Uttar Pradesh CM Election': 'false',
        });
      }

      await _saveUserDataToPreferences();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => ElectionScreen(
                  phone: widget.phone,
                )),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          "Invalid OTP",
          style: TextStyle(fontSize: 17, fontFamily: "urmed"),
        ),
        backgroundColor: Color.fromARGB(255, 254, 44, 29),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define text styles for different parts
    const otpTextStyle = TextStyle(
      fontSize: 24, // Set the font size for OTP numbers
      color: Colors.white, // Set the font color
      fontFamily: "urwbold", // Set the font family
    );

    const emailTextStyle = TextStyle(
      fontSize: 18,
      color: Colors.white,
      fontFamily: "urwbold",
    );

    const normalTextStyle = TextStyle(
      fontSize: 18,
      color: Colors.white,
      fontFamily: "urmed",
    );

    return Scaffold(
      body: Container(
        // Adding a gradient background to the Scaffold
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xffCAA1FF),
              Color(0xff8DAFFF)
            ], // Define your gradient colors here
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(right: 16, left: 16),
          child: Center(
            child: SingleChildScrollView(
              child: KeyboardListener(
                focusNode: FocusNode(), // To listen for keyboard events
                onKeyEvent: (KeyEvent event) {
                  if (event is KeyDownEvent) {
                    if (event.logicalKey == LogicalKeyboardKey.backspace) {
                      // Find which field is focused and handle backspace
                      for (int i = 0; i < _focusNodes.length; i++) {
                        if (_focusNodes[i].hasFocus) {
                          _handleBackspace(i);
                          break;
                        }
                      }
                    }
                  }
                },
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center, // Center vertically
                  crossAxisAlignment:
                      CrossAxisAlignment.center, // Center horizontally
                  children: [
                    // Wrap the image with an AnimatedContainer to manage its space
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: _isImageVisible
                          ? 150.0
                          : 0.0, // Height is 150 when visible, 0 when hidden
                      child: AnimatedOpacity(
                        opacity: _isImageVisible ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: Image.network(
                          'https://firebasestorage.googleapis.com/v0/b/voting-469a3.appspot.com/o/cartoon.png?alt=media&token=6456410d-df42-472d-be6d-58ee0f05d7c6',
                          height: 150.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Enter your \nVerification Code',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 33,
                        color: Colors.white,
                        fontFamily: "urwbold",
                      ),
                    ),
                    const SizedBox(height: 12),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: 'We will send you a One Time Passcode to \n ',
                            style: normalTextStyle,
                          ),
                          TextSpan(
                            text: widget.email,
                            style: emailTextStyle,
                          ),
                          const TextSpan(
                            text: ' email address',
                            style: normalTextStyle,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 27),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) {
                        return Container(
                          width: 40,
                          height: 55,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 3.0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: TextField(
                              controller: _controllers[index],
                              focusNode:
                                  _focusNodes[index], // Assign focus node
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              onChanged: (value) => _onChanged(value, index),
                              style:
                                  otpTextStyle, // Apply the custom text style
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                counterText: '',
                              ),
                              cursorHeight: 20, // Set cursor height
                              cursorWidth: 2, // Set cursor width
                              cursorColor: Colors.white, // Set cursor color
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Didn't get it? ",
                          style: TextStyle(
                            fontSize: 17,
                            color: Colors.white,
                            fontFamily: "urmed",
                          ),
                        ),
                        GestureDetector(
                          onTap: _isButtonEnabled ? _onResendCode : null,
                          child: Text(
                            'Resend Code',
                            style: TextStyle(
                              fontSize: 16,
                              color: _isButtonEnabled
                                  ? const Color(0xff4e5dc1)
                                  : Colors.white.withOpacity(0.5),
                              fontFamily: "urmed",
                            ),
                          ),
                        ),
                        const SizedBox(width: 42),
                        Text(
                          '$_remainingTime second(s)',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: "urmed",
                            color: _isButtonEnabled
                                ? Colors.white.withOpacity(0.5)
                                : Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _verifyOTP,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 110),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Verify OTP',
                        style: TextStyle(
                          fontFamily: "urwbold",
                          color: Color(0xff4e5dc1),
                          fontSize: 21,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
