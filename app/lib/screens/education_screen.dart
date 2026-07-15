import 'package:flutter/material.dart';
import '../models/education_item.dart';
import 'education_video_list_screen.dart';

class EducationScreen extends StatelessWidget {
  const EducationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = educationCategories.keys.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('EDUCATION')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Image.asset(
                'assets/images/educa.png',
                height: 200,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  itemCount: categories.length,
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 2.2,
                  ),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EducationVideoListScreen(
                              category: category,
                              items: educationCategories[category] ?? [],
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF29C8F2),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}