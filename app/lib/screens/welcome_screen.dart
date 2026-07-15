import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'education_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detect Signs')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 8),
              const Text(
                'WELCOME',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Image.asset(
                'assets/images/home.png',
                height: 240,
                fit: BoxFit.contain,
              ),
              const Spacer(),
              const SizedBox(height: 24),
              _MenuButton(
                label: 'Sign to Sinhala',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HomeScreen(initialTab: 0),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _MenuButton(
                label: 'Sinhala to Sign',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HomeScreen(initialTab: 1),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _MenuButton(
                label: 'Sign Education',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EducationScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _MenuButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 68,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF29C8F2),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}