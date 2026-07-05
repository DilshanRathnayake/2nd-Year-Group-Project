import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'sign_detail_screen.dart';

class CategoryGridScreen extends StatelessWidget {
  final String title;
  const CategoryGridScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: AppColors.primaryBlue),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 0.8,
        ),
        itemCount: 15,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignDetailScreen())),
            child: Column(
              children: [
                CircleAvatar(radius: 35, backgroundColor: Colors.grey[300], child: const Text("IMG")),
                const SizedBox(height: 5),
                const Text("TEXT", style: TextStyle(fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }
}