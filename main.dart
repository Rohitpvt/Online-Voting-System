import 'package:flutter/material.dart';
import 'election_screen.dart';
//import 'package:voting/welcomescreen.dart';
import 'LoginPage.dart';
//import 'package:voting/LoginScreen.dart';
//import 'package:voting/RegisterScreen.dart';
import 'RegisterScreen.dart';
//import 'package:voting/screens/election_screen.dart';
//import 'screens/voting_screen.dart';
import 'package:firebase_core/firebase_core.dart';
//import 'Gurj codes/RegisterPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'welcomescreen.dart';
import 'package:email_otp/email_otp.dart';
import 'WelcomeScreen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final String phone = prefs.getString("phone") ?? "null";
  await Firebase.initializeApp();
  EmailOTP.config(
    appName: 'Elect India',
    otpType: OTPType.numeric,
    emailTheme: EmailTheme.v3,
  );
  runApp(MyApp(isLoggedIn: isLoggedIn, phone: phone,));

  
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String phone;
  const MyApp({super.key, required this.isLoggedIn, required this.phone});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      
      routes: {
        "/routeLogin":(context) => const LoginPage(),
        "/routeRegis":(context) => const RegisterPage()
      },
      debugShowCheckedModeBanner: false,
      title: 'Elect India',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: isLoggedIn ? ElectionScreen(phone: phone,) : const WelcomeScreen(),  // Load the VotingScreen as the home screen
    );
  }
}
