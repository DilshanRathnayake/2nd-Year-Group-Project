import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app_config.dart';

class SignVideo {
  const SignVideo({
    required this.file,
    required this.asset,
    required this.url,
    required this.index,
  });

  final String file;
  final String asset;
  final String url;
  final int index;

  factory SignVideo.fromJson(Map<String, dynamic> json) {
    return SignVideo(
      file: json['file'] as String? ?? '',
      asset: json['asset'] as String? ?? '',
      url: json['url'] as String? ?? '',
      index: (json['index'] as num?)?.toInt() ?? 0,
    );
  }
}

class TranslateResult {
  const TranslateResult({
    required this.text,
    required this.tokens,
    required this.unknownWords,
    required this.videos,
    required this.missing,
    required this.truncated,
  });

  final String text;
  final List<String> tokens;
  final List<String> unknownWords;
  final List<SignVideo> videos;
  final List<String> missing;
  final bool truncated;

  factory TranslateResult.fromJson(Map<String, dynamic> json) {
    List<String> readStringList(String key) {
      final value = json[key];
      if (value is! List) return const [];
      return value.whereType<String>().toList(growable: false);
    }

    final videoJson = json['videos'];
    final videos = videoJson is List
        ? videoJson
            .whereType<Map>()
            .map((item) => SignVideo.fromJson(
                item.map((key, value) => MapEntry(key.toString(), value))))
            .where((item) => item.url.isNotEmpty)
            .toList(growable: false)
        : const <SignVideo>[];

    return TranslateResult(
      text: json['text'] as String? ?? '',
      tokens: readStringList('tokens'),
      unknownWords: readStringList('unknown_words'),
      missing: readStringList('missing'),
      videos: videos,
      truncated: json['truncated'] as bool? ?? false,
    );
  }
}

class TranslateService {
  Future<TranslateResult> translate(String host, String text) async {
    final normalizedHost = AppConfig.normalizeHost(host);
    if (normalizedHost.isEmpty) {
      throw const FormatException('Server is not configured.');
    }

    final response = await http
        .post(
          AppConfig.translateUri(normalizedHost),
          headers: {'Content-Type': 'application/json; charset=utf-8'},
          body: jsonEncode({'text': text}),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    return TranslateResult.fromJson(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
    );
  }
}
