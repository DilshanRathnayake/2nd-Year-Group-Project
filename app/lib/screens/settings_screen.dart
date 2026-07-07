import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../app_config.dart';

/// Configure the inference server address (host:port) and test it.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _controller = TextEditingController();
  String _test = '';
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    AppConfig.getHost().then((h) => setState(() => _controller.text = h));
  }

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _test = '';
    });
    try {
      final host = AppConfig.normalizeHost(_controller.text);
      if (host.isEmpty) {
        setState(() => _test = 'Enter server address');
        return;
      }

      final resp = await http
          .get(AppConfig.healthUri(host))
          .timeout(const Duration(seconds: 4));
      if (resp.statusCode == 200) {
        final body = jsonDecode(utf8.decode(resp.bodyBytes));
        final reverse = body['sinhala_to_sign'];
        final videos = reverse is Map ? reverse['videos'] : null;
        setState(() =>
            _test = 'OK - ${body['classes']} classes, ${videos ?? 0} videos');
      } else {
        setState(() => _test = 'HTTP ${resp.statusCode}');
      }
    } catch (e) {
      setState(() => _test = 'Could not reach server');
    } finally {
      setState(() => _testing = false);
    }
  }

  Future<void> _save() async {
    final host = AppConfig.normalizeHost(_controller.text);
    await AppConfig.setHost(host);
    _controller.text = host;
    if (mounted) Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Server settings')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Inference server (host:port)'),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '192.168.1.42:8000',
                prefixIcon: Icon(Icons.dns),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Use your PC Wi-Fi IPv4. The phone and PC must be on the same '
              'network, and the server must be started with --host 0.0.0.0.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _testing ? null : _testConnection,
                  icon: _testing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.wifi_tethering),
                  label: const Text('Test'),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(_test)),
              ],
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
