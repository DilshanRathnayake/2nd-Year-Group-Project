import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SignDetailScreen extends StatelessWidget {
  const SignDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("EDUCATION"), backgroundColor: AppColors.primaryBlue),
      body: Container(
        width: double.infinity,
        color: AppColors.accentGreen,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 100,
              backgroundColor: Colors.white,
              child: Icon(Icons.play_arrow, size: 100, color: Colors.black),
            ),
            const SizedBox(height: 40),
            const Text(
              "Sign name",
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // TODO: Connect trained model or dataset here to play specific sign video
          ],
        ),
      ),
    );
  }
}