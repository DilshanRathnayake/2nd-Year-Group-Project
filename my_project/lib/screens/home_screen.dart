import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'sign_to_sinhala_screen.dart';
import 'sinhala_to_sign_screen.dart';
import 'education_menu_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        title: const Text("Detect Signs"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Text(
                "WELCOME",
                style: TextStyle(
                  fontSize: 22, 
                  fontWeight: FontWeight.bold, 
                  color: AppColors.darkBlue
                )
              ),
              const SizedBox(height: 20),
              
             
Image.asset(
  'assets/images/home.png',
  height: 300, 
  width: MediaQuery.of(context).size.width * 0.9, 
  fit: BoxFit.contain, 
  errorBuilder: (context, error, stackTrace) {
    return const Text('Image not found in assets folder!');
  },
),
              
              const SizedBox(height: 40),
              
              
              _buildNavButton(context, "Sign to Sinhala", const SignToSinhalaScreen()),
              const SizedBox(height: 15),
              _buildNavButton(context, "Sinhala to Sign", const SinhalaToSignScreen()),
              const SizedBox(height: 15),
              _buildNavButton(context, "Sign Education", const EducationMenuScreen()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(BuildContext context, String text, Widget destination) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        onPressed: () {
          
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => destination)
          );
        },
        child: Text(text, style: const TextStyle(fontSize: 18, color: Colors.white)),
      ),
    );
  }
}