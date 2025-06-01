// ignore_for_file: file_names, avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart'; // Import intl package
//import 'welcomescreen.dart';
import 'election_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OTPScreen extends StatefulWidget {
  final String phone;
  final String verificationId;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String password;
  final String? dob; // Date of Birth as a String
  final bool isLogin;

  const OTPScreen({
    super.key,
    required this.phone,
    required this.verificationId,
    this.email,
    this.firstName,
    this.lastName,
    required this.password,
    this.dob,
    this.isLogin = false,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> with WidgetsBindingObserver {
  late FirebaseAuth auth;
  String? _verificationId;
  String _otpCode = "";
  bool _isOTPSent = false;
  String _statusMessage = "";
  bool _isBlocked = false;
  Timer? _blockTimer;
  bool _isButtonEnabled = true;
  int _remainingTime = 30;
  Timer? _timer;
  bool _isImageVisible = true;

  // Create FocusNodes and TextEditingControllers for each OTP box
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());

  @override
  void initState() {
    super.initState();
    auth = FirebaseAuth.instance;
    _verificationId = widget.verificationId;
    _isOTPSent = true;
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

  void _onResendCode() {
    _startTimer();
    // Add your resend code logic here
  }

  // Function to calculate the age by extracting the year from DOB and subtracting it from the current year
  int _calculateAgeFromDOB(String dob) {
    try {
      final DateFormat dateFormat =
          DateFormat('M/d/yyyy'); // Use the correct format
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

  // OTP verification function
  void verifyOTP() async {
    if (_isBlocked) {
      setState(() {
        _statusMessage =
            'You are temporarily blocked due to unusual activity. Please try again later.';
      });
      return;
    }

    if (_verificationId != null && _otpCode.isNotEmpty) {
      try {
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: _verificationId!,
          smsCode: _otpCode,
        );

        await auth.signInWithCredential(credential);
        setState(() {
          _statusMessage = 'OTP verified successfully!';
        });

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
            'email': widget.email ?? '',
            'password': widget.password,
            'dob': widget.dob ?? '',
            'Age': age.toString(),
            'hasVoted': 'false',
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
      } catch (e) {
        setState(() {
          _statusMessage = 'An unexpected error occurred: $e';
        });
      }
    } else {
      setState(() {
        _statusMessage = 'Incorrect OTP code.';
      });
    }
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 5) {
        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
      } else {
        _otpCode = _controllers.map((controller) => controller.text).join();
      }
    }
  }

  void _handleBackspace(int index) {
    if (_controllers[index].text.isEmpty) {
      if (index > 0) {
        FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
        _controllers[index - 1].clear();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _blockTimer?.cancel();
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    for (final controller in _controllers) {
      controller.dispose();
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    setState(() {
      _isImageVisible = !isKeyboardVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    const otpTextStyle = TextStyle(
      fontSize: 24,
      color: Colors.white,
      fontFamily: "Bold",
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xffCAA1FF),
              Color(0xff8DAFFF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: SingleChildScrollView(
              child: KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: (KeyEvent event) {
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.backspace) {
                    for (int i = 0; i < _focusNodes.length; i++) {
                      if (_focusNodes[i].hasFocus) {
                        _handleBackspace(i);
                        break;
                      }
                    }
                  }
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (_isOTPSent)
                      Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: _isImageVisible ? 150.0 : 0.0,
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
                              fontSize: 30,
                              color: Colors.white,
                              fontFamily: "urwbold",
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text.rich(
                            TextSpan(
                              text:
                                  'We will send you an OTP to ', // Normal text
                              style: const TextStyle(
                                fontSize: 17,
                                color: Colors.white,
                                fontFamily: "urmed",
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      '+91 ${widget.phone}', // Bold phone number
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily:
                                        "urmed", // Bold style for phone number
                                  ),
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
                                  border: Border.all(
                                      color: Colors.white, width: 3.0),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: TextField(
                                    controller: _controllers[index],
                                    focusNode: _focusNodes[index],
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    maxLength: 1,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly
                                    ],
                                    onChanged: (value) =>
                                        _onChanged(value, index),
                                    onSubmitted: (value) {
                                      if (index == 5) {
                                        // If the user is on the last OTP field, trigger the verifyOTP function
                                        verifyOTP();
                                      }
                                    },
                                    style: otpTextStyle,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      counterText: '',
                                    ),
                                    cursorHeight: 20,
                                    cursorWidth: 2,
                                    cursorColor: Colors.white,
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
                                  fontSize: 15,
                                  color: Colors.white,
                                  fontFamily: "urmed",
                                ),
                              ),
                              GestureDetector(
                                onTap: _isButtonEnabled ? _onResendCode : null,
                                child: Text(
                                  'Resend Code',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: _isButtonEnabled
                                        ? const Color(0xff4e5dc1)
                                        : Colors.white.withOpacity(0.5),
                                    fontFamily: "urmed",
                                  ),
                                ),
                              ),
                              const SizedBox(width: 55),
                              Text(
                                '$_remainingTime second(s)',
                                style: TextStyle(
                                  fontSize: 15,
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
                            onPressed: verifyOTP,
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
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (_statusMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _statusMessage,
                          style: TextStyle(
                              color: (_statusMessage.contains('error') ||
                                      _statusMessage.contains('Incorrect'))
                                  ? Colors.red
                                  : Colors.green,
                              fontFamily: "urmed",
                              fontSize: 18),
                        ),
                      )
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
