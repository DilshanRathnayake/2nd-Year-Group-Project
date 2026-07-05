import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../theme/app_colors.dart';

class SinhalaToSignScreen extends StatefulWidget {
  const SinhalaToSignScreen({super.key});

  @override
  State<SinhalaToSignScreen> createState() => _SinhalaToSignScreenState();
}

class _SinhalaToSignScreenState extends State<SinhalaToSignScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

 
  void _listen() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (val) => setState(() {
          _textController.text = val.recognizedWords;
        }),
      );
    }
  }

 
  void _stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sinhala to Sign"), backgroundColor: AppColors.primaryBlue),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
  children: [
    
    Image.asset(
      'assets/images/sinhala_to_sign_illustration.png',
      height: 140,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const SizedBox(height: 180, child: Icon(Icons.image)),
    ),
    
    const SizedBox(height: 20),

    const Text("Enter your sentence", style: TextStyle(fontWeight: FontWeight.bold)),
    const SizedBox(height: 10),

    
    Row(
      children: [
        Expanded(
          child: TextField(
            controller: _textController,
            decoration: InputDecoration(
              hintText: "Type the sentence...",
              filled: true,
              fillColor: Colors.grey[200],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onLongPressStart: (_) => _listen(),
          onLongPressEnd: (_) => _stopListening(),
          child: CircleAvatar(
            backgroundColor: _isListening ? Colors.red : Colors.green,
            radius: 25,
            child: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.white),
          ),
        ),
      ],
    ),

    const SizedBox(height: 20),
    
    ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
      onPressed: () { /* Convert Function */ },
      child: const Text("CONVERT", style: TextStyle(color: Colors.white)),
    ),

    const SizedBox(height: 30),
    
   
    const Text("SIGN LANGUAGE VIDEO", style: TextStyle(fontWeight: FontWeight.bold)),
    const SizedBox(height: 10),
    Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.lightBlueBox,
        border: Border.all(color: AppColors.primaryBlue),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Center(
        child: Icon(Icons.play_circle_fill, size: 50, color: Colors.red),
      ),
    )
  ],
),
      ),
    );
  }
}