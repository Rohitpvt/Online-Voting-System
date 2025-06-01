// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'LoginPage.dart';
import 'NumberOTP.dart';
import 'package:flutter/services.dart';
import 'package:email_otp/email_otp.dart';
import 'EmailOTPscreen.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  String emailAddress = "",
      password = "",
      confirmPassword = "",
      firstName = "",
      lastName = "",
      phoneNumber = "";
  DateTime? dob;
  bool showPassword = false;
  final authInstance = FirebaseAuth.instance;
  final databaseInstance = FirebaseFirestore.instance;
  String errorMessage = "";
  String successMessage = "";
  bool showProgress = false;
  final TextEditingController _dobController = TextEditingController();
  bool isFormValid = false;

  bool isEmailValid(String email) {
    // Regular expression for validating an Email
    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      caseSensitive: false,
    );
    return emailRegExp.hasMatch(email);
  }

  void validateForm() {
    setState(() {
      isFormValid = emailAddress.isNotEmpty &&
          password.isNotEmpty &&
          confirmPassword.isNotEmpty &&
          firstName.isNotEmpty &&
          lastName.isNotEmpty &&
          phoneNumber.isNotEmpty &&
          dob != null;
    });
  }

  bool isNameValid(String name) {
    // Regular expression to allow only letters (no spaces, numbers, or symbols)
    final nameRegExp = RegExp(r'^[a-zA-Z]+$');
    return nameRegExp.hasMatch(name);
  }

  bool _isPasswordValid(String password) {
    // Check if password has at least 9 characters
    final isLengthValid = password.length >= 9;

    // Check if password contains at least one uppercase letter
    final hasUpperCase = RegExp(r'[A-Z]').hasMatch(password);

    // Check if password contains at least one special character
    final hasSpecialCharacter =
        RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);

    // Check if password is alphanumeric
    final isAlphanumeric =
        RegExp(r'^[a-zA-Z0-9!@#$%^&*(),.?":{}|<>]+$').hasMatch(password);

    return isLengthValid &&
        hasUpperCase &&
        hasSpecialCharacter &&
        isAlphanumeric;
  }

  Future<void> sendOtpAndNavigate(
      BuildContext context, String phoneNumber, String email,
      {String? dob, bool isLogin = false}) async {
    final String userPhoneNumber = phoneNumber; // User phone number
    String dateString = dob ?? "Not provided"; // User phone number
    // DateTime dateTime; // Non-nullable DateTime
    // dateTime = DateTime.now();
    // String dateString = DateFormat('dd-MM-yyy').format(dateTime);

    try {
      if (email.isNotEmpty) {
        String email = emailAddress;
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
              isLogin: false,
              firstName: firstName,
              lastName: lastName,
              dob: dateString,
            ),
          ),
        );

        if (otpSent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "OTP sent to your email",
                style: TextStyle(fontFamily: "urmed", fontSize: 17),
              ),
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
        const SnackBar(
          content: Text(
            "Error sending OTP",
            style: TextStyle(fontSize: 17, fontFamily: "urmed"),
          ),
          backgroundColor: Color.fromARGB(255, 254, 44, 29),
        ),
      );
    }
  }

  Future<void> _handleSignUp() async {
    if (!isNameValid(firstName)) {
      setState(() {
        errorMessage =
            "First Name should contain only letters. No spaces, numbers, or symbols.";
        successMessage = "";
      });
      return;
    }

    if (!isNameValid(lastName)) {
      setState(() {
        errorMessage =
            "Last Name should contain only letters. No spaces, numbers, or symbols.";
        successMessage = "";
      });
      return;
    }

    if (!isPhoneNumberValid(phoneNumber)) {
      setState(() {
        errorMessage = "Phone number must be exactly 10 digits.";
        successMessage = "";
      });
      return;
    }

    if (!isEmailValid(emailAddress)) {
      setState(() {
        errorMessage = "Invalid email address format.";
        successMessage = "";
      });
      return;
    }

    bool isPasswordValid = _isPasswordValid(password);

    if (!isPasswordValid) {
      setState(() {
        errorMessage =
            "Password must be alphanumeric, a capital letter, include a special character, and have at least 9 characters.";
        successMessage = "";
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        errorMessage = "Passwords do not match.";
        successMessage = "";
      });
      return;
    }

    // Check if password is valid

    // Check if phone number is valid

    try {
      // Query Firestore for any document where phoneNumber field matches the input
      final existingUser = await databaseInstance
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1) // Limit to 1 result for efficiency
          .get();

      // If a document exists with this phone number, display an error
      if (existingUser.docs.isNotEmpty) {
        setState(() {
          errorMessage =
              "Phone number already exists. Please use a different number.";
          successMessage = "";
        });
        return;
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error checking phone number: ${e.toString()}";
        successMessage = "";
      });
      return;
    }

    // Start showing loading animation
    setState(() {
      showProgress = true;
    });

    try {
      // Create user with email and password
      // await authInstance.createUserWithEmailAndPassword(
      //   email: emailAddress,
      //   password: password,
      // );

      // // Success message
      // setState(() {
      //   successMessage = "Account Created Successfully. Sending OTP...";
      //   errorMessage = "";
      // });

      // if (authInstance.currentUser != null) {
      // Perform phone number verification
      await authInstance.verifyPhoneNumber(
        phoneNumber: '+91$phoneNumber',
        verificationCompleted: (PhoneAuthCredential credential) {},
        verificationFailed: (FirebaseAuthException e) async {
          if (e.code == 'invalid-phone-number') {
            // Handle invalid phone number
            setState(() {
              errorMessage =
                  "Invalid phone number. Please check and try again.";
            });
          } else if (e.code == 'too-many-requests' ||
              e.message?.contains(
                      "We have blocked all requests from this device due to unusual activity") ==
                  true) {
            // Handle case where requests are blocked due to unusual activity
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Error sending OTP on Mobile Number so proceeding sending OTP on Email.",
                  style: TextStyle(fontSize: 17, fontFamily: "urmed"),
                ),
                backgroundColor:
                    Color(0xff4e5dc1), // Set your desired background color
              ),
            );
            await sendOtpAndNavigate(context, phoneNumber, emailAddress,
                dob: dob != null
                    ? "${dob!.day}/${dob!.month}/${dob!.year}"
                    : "Not provided",
                isLogin: false);
          } else {
            // Handle other server errors
            setState(() {
              errorMessage =
                  "Server Error: Error Sending OTP on Mobile Number.";
              successMessage = "Please Wait! Sending OTP to $emailAddress";
            });
            await sendOtpAndNavigate(context, phoneNumber, emailAddress,
                dob: dob != null
                    ? "${dob!.day}/${dob!.month}/${dob!.year}"
                    : "Not provided",
                isLogin: false);
          }
        },
        codeSent: (String verificationId, int? resendToken) async {
          print("otp bhj diaaaa");
          setState(() {
            successMessage = "OTP sent successfully to $phoneNumber";
          });

          print("moblal otp");

          // Navigate to OTPScreen
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OTPScreen(
                isLogin: false,
                phone: phoneNumber,
                verificationId: verificationId,
                email: emailAddress,
                firstName: firstName,
                lastName: lastName,
                password: password,
                dob: dob != null
                    ? "${dob!.day}/${dob!.month}/${dob!.year}"
                    : "Not provided",
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } on FirebaseAuthException catch (error) {
      setState(() {
        errorMessage = "Server Error: Error Sending OTP.";
        successMessage = "Please Wait! Sending OTP to $emailAddress";
        print(error);
      });

      await sendOtpAndNavigate(context, phoneNumber, emailAddress,
          dob: dob != null
              ? "${dob!.day}/${dob!.month}/${dob!.year}"
              : "Not provided",
          isLogin: false);
    }
    //finally {
    //   // Ensure loading animation stops even if an error occurs
    //   if (Navigator.canPop(context)) {
    //     setState(() {
    //       showProgress = false;
    //     });
    //   }
    // }
  }

  bool isPhoneNumberValid(String phone) {
    final phoneRegExp = RegExp(r'^\d{10}$');
    return phoneRegExp.hasMatch(phone);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != dob) {
      setState(() {
        dob = picked;
        _dobController.text =
            "${dob!.year}-${dob!.month.toString().padLeft(2, '0')}-${dob!.day.toString().padLeft(2, '0')}";
      });
    }
  }

  TextEditingController _controller = TextEditingController();
  TextEditingController _controller2 = TextEditingController();
  TextEditingController _controller3 = TextEditingController();
  TextEditingController _controller4 = TextEditingController();
  TextEditingController _controller5 = TextEditingController();
  TextEditingController _controller6 = TextEditingController();

  @override
  void dispose() {
    _dobController.dispose();
    _controller.dispose();
    _controller2.dispose();
    _controller3.dispose();
    _controller4.dispose();
    _controller5.dispose();
    _controller6.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xffb38ae8),
              Color(0xff8DAFFF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
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
                            top: 30, left: 5, bottom: 20, right: 5),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            showProgress
                                ? LoadingAnimationWidget.flickr(
                                    leftDotColor: const Color(0xFF9055dd),
                                    rightDotColor: const Color(0xFF4d82ff),
                                    size: 70,
                                  )
                                : const SizedBox(),
                            const SizedBox(height: 17),
                            const Text(
                              "Create Account",
                              style: TextStyle(
                                fontSize: 37,
                                color: Colors.white,
                                fontFamily: "urwbold",
                              ),
                            ),
                            const Text(
                              "to get started now!",
                              style: TextStyle(
                                fontSize: 26,
                                color: Colors.white,
                                fontFamily: "urmed",
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        top: 20, right: 4),
                                    child: TextField(
                                      controller: _controller,
                                      onChanged: (val) {
                                        firstName = val;
                                        validateForm();
                                      },
                                      style:
                                          const TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 10, horizontal: 10),
                                        hintText: "First Name",
                                        hintStyle: TextStyle(
                                            fontFamily: "urmed",
                                            fontSize: 19,
                                            color:
                                                Colors.white.withOpacity(0.6)),
                                        filled: true,
                                        fillColor:
                                            Colors.white.withOpacity(0.2),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                          borderSide: const BorderSide(
                                            color: Colors.white,
                                            width: 1.5,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                          borderSide: const BorderSide(
                                            color: Colors.white,
                                            width: 1.5,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                          borderSide: const BorderSide(
                                            color: Colors.white,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.only(top: 20, left: 4),
                                    child: TextField(
                                      controller: _controller2,
                                      onChanged: (val) {
                                        lastName = val;
                                        validateForm();
                                      },
                                      style:
                                          const TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 10, horizontal: 10),
                                        hintText: "Last Name",
                                        hintStyle: TextStyle(
                                            fontFamily: "urmed",
                                            fontSize: 19,
                                            color:
                                                Colors.white.withOpacity(0.6)),
                                        fillColor:
                                            Colors.white.withOpacity(0.2),
                                        filled: true,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                          borderSide: const BorderSide(
                                            color: Colors.white,
                                            width: 1.5,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                          borderSide: const BorderSide(
                                            color: Colors.white,
                                            width: 1.5,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                          borderSide: const BorderSide(
                                            color: Colors.white,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 17, bottom: 15),
                              child: TextField(
                                controller: _controller3,
                                onChanged: (val) {
                                  phoneNumber = val;
                                  validateForm();
                                },
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(
                                      10), // <-- Added to limit input to 10 digits
                                ],
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 10),
                                  hintText:
                                      "Mobile Number", // Example from the image
                                  hintStyle: TextStyle(
                                    fontFamily: "urmed",
                                    fontSize: 19,
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                  fillColor: Colors.white.withOpacity(0.2),
                                  filled: true,
                                  prefixIcon: const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 10),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "+91", // Update the country code to match the image (+62 for Indonesia)
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontFamily: 'urmed',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17),
                                        ),
                                      ],
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: const BorderSide(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: const BorderSide(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: const BorderSide(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 5, bottom: 15),
                              child: TextField(
                                controller: _controller4,
                                onChanged: (val) {
                                  emailAddress = val;
                                  validateForm();
                                },
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 10),
                                  hintText: "Email",
                                  hintStyle: TextStyle(
                                      fontFamily: "urmed",
                                      fontSize: 19,
                                      color: Colors.white.withOpacity(0.6)),
                                  fillColor: Colors.white.withOpacity(0.2),
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: const BorderSide(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: const BorderSide(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: const BorderSide(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 0, bottom: 15),
                              child: TextField(
                                readOnly: true,
                                onTap: () => _selectDate(context),
                                controller: _dobController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 10),
                                  hintText: "Date of Birth",
                                  hintStyle: TextStyle(
                                      fontFamily: "urmed",
                                      fontSize: 19,
                                      color: Colors.white.withOpacity(0.6)),
                                  fillColor: Colors.white.withOpacity(0.2),
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: const BorderSide(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: const BorderSide(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: const BorderSide(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                  suffixIcon: const Icon(
                                    Icons.calendar_today,
                                    color: Color(0xff4e5dc1),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 5, bottom: 15),
                              child: TextField(
                                obscureText: !showPassword,
                                controller: _controller6,
                                onChanged: (val) {
                                  password = val;
                                  validateForm();
                                },
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 10),
                                  hintText: "Password",
                                  hintStyle: TextStyle(
                                    fontFamily: "urmed",
                                    fontSize: 19,
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                  fillColor: Colors.white.withOpacity(0.2),
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: const BorderSide(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: const BorderSide(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: const BorderSide(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                  suffixIcon: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        showPassword = !showPassword;
                                      });
                                    },
                                    child: showPassword
                                        ? const Icon(Icons.visibility,
                                            color: Color(0xff4e5dc1))
                                        : const Icon(Icons.visibility_off,
                                            color: Color(0xff4e5dc1)),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 5, bottom: 20),
                              child: TextField(
                                obscureText: !showPassword,
                                controller: _controller5,
                                onChanged: (val) {
                                  confirmPassword = val;
                                  validateForm();
                                },
                                onSubmitted: (_) => _handleSignUp(),
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 10),
                                  hintText: "Confirm Password",
                                  hintStyle: TextStyle(
                                    fontFamily: "urmed",
                                    fontSize: 19,
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                  fillColor: Colors.white.withOpacity(0.2),
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: const BorderSide(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: const BorderSide(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: const BorderSide(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                  suffixIcon: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        showPassword = !showPassword;
                                      });
                                    },
                                    child: showPassword
                                        ? const Icon(Icons.visibility,
                                            color: Color(0xff4e5dc1))
                                        : const Icon(Icons.visibility_off,
                                            color: Color(0xff4e5dc1)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 17),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isFormValid
                                    ? () async {
                                        await _handleSignUp();
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14, horizontal: 0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  backgroundColor: isFormValid
                                      ? Colors.white
                                      : Colors
                                          .grey, // Grey out the button when invalid
                                  foregroundColor: isFormValid
                                      ? const Color(0xff4e5dc1)
                                      : Colors.white,
                                ),
                                child: const Text(
                                  "SIGN UP",
                                  style: TextStyle(
                                      fontFamily: "urwbold", fontSize: 19),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            if (errorMessage.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: Center(
                                  child: Text(
                                    errorMessage,
                                    style: const TextStyle(
                                        color: Color.fromARGB(255, 239, 20, 4),
                                        fontFamily: "urmed",
                                        fontSize: 16),
                                  ),
                                ),
                              ),
                            if (successMessage.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Center(
                                  child: Text(
                                    successMessage,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        color: Color.fromARGB(255, 1, 222, 8),
                                        fontFamily: "urmed"),
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
            ),
            Container(
              padding: const EdgeInsets.all(15),
              child: GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginPage(),
                    ),
                  );
                },
                child: RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: "Already have an account? ",
                        style: TextStyle(
                          fontFamily: "urmed",
                          color: Colors.white,
                          fontSize: 19,
                        ),
                      ),
                      TextSpan(
                        text: "Login",
                        style: TextStyle(
                          fontFamily: "urwbold",
                          color: Color(0xff4e5dc1),
                          fontSize: 19,
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
