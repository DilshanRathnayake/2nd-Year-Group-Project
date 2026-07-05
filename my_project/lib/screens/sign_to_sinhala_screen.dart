import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../theme/app_colors.dart';

class SignToSinhalaScreen extends StatefulWidget {
  const SignToSinhalaScreen({super.key});

  @override
  State<SignToSinhalaScreen> createState() => _SignToSinhalaScreenState();
}

class _SignToSinhalaScreenState extends State<SignToSinhalaScreen> {
  CameraController? controller;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
  final cameras = await availableCameras();

 
  final frontCamera = cameras.firstWhere(
    (camera) => camera.lensDirection == CameraLensDirection.front,
    orElse: () => cameras[0], 
  );

  controller = CameraController(frontCamera, ResolutionPreset.medium);
  await controller!.initialize();
  
  if (!mounted) return;
  setState(() {});
}

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign to Sinhala"), backgroundColor: AppColors.primaryBlue),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey, width: 2)),
              child: (controller?.value.isInitialized ?? false)
                  ? CameraPreview(controller!)
                  : const Center(child: CircularProgressIndicator()),
            ),
          ),
          const Icon(Icons.circle, color: Colors.red, size: 60), // Record Button
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.lightBlueBox,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Text(
                "Live Conversion ... \nHello", // TODO: Connect trained ML model here
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}