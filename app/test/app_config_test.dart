import 'package:flutter_test/flutter_test.dart';
import 'package:sign_app/app_config.dart';

void main() {
  test('normalizes server host input', () {
    expect(AppConfig.normalizeHost('192.168.1.42:8000'), '192.168.1.42:8000');
    expect(AppConfig.normalizeHost(' http://192.168.1.42:8000/ '),
        '192.168.1.42:8000');
    expect(AppConfig.normalizeHost('ws://localhost:8000/ws'), 'localhost:8000');
  });
}
