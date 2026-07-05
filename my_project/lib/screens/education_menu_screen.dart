import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'category_grid_screen.dart';

class EducationMenuScreen extends StatelessWidget {
  const EducationMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> categories = ["VERBS", "NOUNS", "PLACES", "OBJECTS", "DAYS", "TEXT"];

    return Scaffold(
      appBar: AppBar(title: const Text("EDUCATION"), backgroundColor: AppColors.primaryBlue),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // Illustration Image Placeholder
          Image.asset(
  'assets/images/educa.png',
  height: 270, 
  width: MediaQuery.of(context).size.width * 0.9, 
  fit: BoxFit.contain, 
  errorBuilder: (context, error, stackTrace) {
    return const Text('Image not found in assets folder!');
  },
),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CategoryGridScreen(title: categories[index]))),
                  child: Text(categories[index], style: const TextStyle(color: Colors.white)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}