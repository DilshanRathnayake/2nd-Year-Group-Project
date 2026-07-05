import 'package:flutter/material.dart';
import 'dart:async';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // තත්පර 3කට පස්සේ Home Screen එකට යනවා
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    });
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
   
    backgroundColor: const Color(0xFF00E5FF), 
    body: Container(
      width: double.infinity,
      height: double.infinity,
     
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/logo.png'),
          fit: BoxFit.cover, 
        ),
      ),
      
      /*
      child: Center(
        child: Image.asset(
          'assets/images/logo.png',
          width: MediaQuery.of(context).size.width, // Screen එකේ පළලට සමාන කරයි
          fit: BoxFit.contain,
        ),
      ),
      */
    ),
  );
}
}