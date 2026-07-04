import 'package:flutter/foundation.dart';

class ApiConfig {
  const ApiConfig._();

  static String get baseUrl {
    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.isNotEmpty) return configured;
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.iOS) {
      return 'http://localhost:4000';
    }
    return 'http://localhost:4000';
  }
}
