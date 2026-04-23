import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Base URL API (ví dụ `http://10.0.2.2:8000/api/v1`).
String apiBaseUrl() {
  final v = dotenv.env['API_BASE_URL']?.trim();
  if (v != null && v.isNotEmpty) {
    return v.endsWith('/') ? v.substring(0, v.length - 1) : v;
  }
  return 'http://127.0.0.1:8000/api/v1';
}
