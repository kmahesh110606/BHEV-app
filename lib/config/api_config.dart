class ApiConfig {
  static const productionBaseUrl =
      'https://bhev-api.wittybay-7a064b00.centralindia.azurecontainerapps.io';

  static String normalizeBaseUrl(String? configuredValue) {
    final candidate = configuredValue?.trim() ?? '';
    if (candidate.isEmpty) return productionBaseUrl;

    final parsed = Uri.tryParse(candidate);
    if (parsed == null ||
        !parsed.hasScheme ||
        parsed.host.isEmpty ||
        (parsed.scheme != 'http' && parsed.scheme != 'https')) {
      return productionBaseUrl;
    }

    final normalizedPath = parsed.path
        .replaceFirst(RegExp(r'/api(?:/v1)?/?$'), '')
        .replaceFirst(RegExp(r'/+$'), '');
    return parsed
        .replace(path: normalizedPath, query: null, fragment: null)
        .toString()
        .replaceFirst(RegExp(r'/+$'), '');
  }

  static Uri endpoint(
    String baseUrl,
    String path, {
    Map<String, String>? queryParameters,
  }) {
    final normalizedBase = normalizeBaseUrl(baseUrl);
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBase$normalizedPath').replace(
      queryParameters:
          queryParameters?.isEmpty == true ? null : queryParameters,
    );
  }
}
