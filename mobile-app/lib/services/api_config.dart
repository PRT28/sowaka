class ApiConfig {
  const ApiConfig._();

  static const String _defaultBaseUrl = 'http://15.207.72.29';

  static String get baseUrl {
    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.isNotEmpty) return configured;
    return _defaultBaseUrl;
  }
}
