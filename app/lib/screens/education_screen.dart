import 'package:flutter/material.dart';

class EducationScreen extends StatelessWidget {
  const EducationScreen({super.key});

  static const List<String> _categories = [
    'VERBS',
    'NOUNS',
    'PLACES',
    'OBJECTS',
    'DAYS',
    'TEXT',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EDUCATION')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Image.asset(
                'assets/images/educa.png',
                height: 220,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  itemCount: _categories.length,
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 2.2,
                  ),
                  itemBuilder: (context, index) {
                    final label = _categories[index];
                    return ElevatedButton(
                      onPressed: () {
                        // TODO: category ekata anuwa navigate karanna
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF29C8F2),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
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