// lib/screens/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'auth_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Display the splash screen for 3 seconds before navigating to AuthScreen
    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AuthScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // Display your logo centered on the screen
      body: Center(
        child: Image.asset(
          'assets/logo.png',
          width: 200,
          height: 200,
        ),
      ),
    );
  }
}
