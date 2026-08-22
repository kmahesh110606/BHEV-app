import 'package:flutter_test/flutter_test.dart';
import 'package:uei_app/config/api_config.dart';

void main() {
  group('ApiConfig', () {
    test('uses production API when the configured value is empty or relative',
        () {
      expect(ApiConfig.normalizeBaseUrl(''), ApiConfig.productionBaseUrl);
      expect(
        ApiConfig.normalizeBaseUrl('/api'),
        ApiConfig.productionBaseUrl,
      );
    });

    test('normalizes a configured API root', () {
      expect(
        ApiConfig.normalizeBaseUrl('https://example.com/api/v1/'),
        'https://example.com',
      );
      expect(
        ApiConfig.normalizeBaseUrl('http://10.0.2.2:3000/'),
        'http://10.0.2.2:3000',
      );
    });

    test('creates absolute endpoints with query parameters', () {
      final endpoint = ApiConfig.endpoint(
        '',
        '/api/v1/stations',
        queryParameters: {'limit': '25'},
      );

      expect(endpoint.hasScheme, isTrue);
      expect(endpoint.host, isNotEmpty);
      expect(endpoint.path, '/api/v1/stations');
      expect(endpoint.queryParameters['limit'], '25');
    });
  });
}
