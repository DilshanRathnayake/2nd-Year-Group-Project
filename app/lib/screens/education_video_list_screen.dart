import 'package:flutter/material.dart';
import '../models/education_item.dart';
import 'education_video_player_screen.dart';

class EducationVideoListScreen extends StatelessWidget {
  final String category;
  final List<EducationItem> items;

  const EducationVideoListScreen({
    super.key,
    required this.category,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.4,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EducationVideoPlayerScreen(item: item),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF29C8F2),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                item.sinhalaLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}