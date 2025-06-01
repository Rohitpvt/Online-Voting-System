// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'LoginPage.dart'; // Import the LoginPage screen
import 'RegisterScreen.dart'; // Import the RegisterPage screen

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF696eff), Color(0xFFf8acff)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween, // Distributes space evenly
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    height: 105,
                  ),
                  Image.network(
                    "https://firebasestorage.googleapis.com/v0/b/voting-469a3.appspot.com/o/iconelect.png?alt=media&token=70c37b40-812e-41b9-817b-09d1aa4f5a71",
                    height: 350,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: Colors.white, // Pure white background
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'LOG IN',
                        style: TextStyle(
                          fontFamily: "urmed",
                          color: Colors.black, // Button text color
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterPage(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor:
                            Colors.transparent, // Fully transparent background
                        side: const BorderSide(
                            color: Colors.white, width: 2), // White border
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'SIGN UP',
                        style: TextStyle(
                          fontFamily: "urmed",
                          color: Colors.white, // Button text color
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  bottom: 15.0), // Adjust padding as needed
              child: Text(
                "© 2024 Rohit, Aman & Gurjyot. All Rights Reserved.",
                style: TextStyle(
                    fontFamily: "urwbold",
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
