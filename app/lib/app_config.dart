import 'package:shared_preferences/shared_preferences.dart';

/// Stores the inference server address (host:port) and derives URLs.
///
/// The app is host-agnostic: point it at your PC LAN IP for local Wi-Fi use,
/// or a public URL if the API is hosted elsewhere.
class AppConfig {
  static const _kHostKey = 'server_host';

  /// Optional build-time default:
  /// flutter run --dart-define=SIGN_SERVER_HOST=192.168.1.42:8000
  static const String defaultHost =
      String.fromEnvironment('SIGN_SERVER_HOST', defaultValue: '');

  static Future<String> getHost() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kHostKey) ?? defaultHost;
  }

  static Future<void> setHost(String host) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kHostKey, normalizeHost(host));
  }

  static String normalizeHost(String host) {
    var value = host.trim();
    value = value.replaceFirst(RegExp(r'^https?://'), '');
    value = value.replaceFirst(RegExp(r'^wss?://'), '');
    if (value.contains('/')) {
      value = value.substring(0, value.indexOf('/'));
    }
    return value;
  }

  static bool isConfigured(String host) => normalizeHost(host).isNotEmpty;

  static Uri wsUri(String host) => Uri.parse('ws://${normalizeHost(host)}/ws');

  static Uri healthUri(String host) => httpUri(host, '/');

  static Uri translateUri(String host) => httpUri(host, '/translate');

  static Uri httpUri(String host, String path) {
    final normalized = normalizeHost(host);
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('http://$normalized$cleanPath');
  }
}
