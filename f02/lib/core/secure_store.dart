import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kAccessToken = 'access_token';
const _kCachedUserJson = 'cached_user_json';

/// Lưu JWT và (tuỳ chọn) snapshot user JSON.
class SecureStore {
  SecureStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<String?> readToken() => _storage.read(key: _kAccessToken);

  Future<void> saveToken(String token) =>
      _storage.write(key: _kAccessToken, value: token);

  Future<void> clearToken() async {
    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kCachedUserJson);
  }

  Future<void> saveCachedUserJson(String json) =>
      _storage.write(key: _kCachedUserJson, value: json);

  Future<String?> readCachedUserJson() =>
      _storage.read(key: _kCachedUserJson);
}
