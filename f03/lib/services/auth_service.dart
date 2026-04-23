import 'package:dio/dio.dart';

import '../models/user.dart';

class AuthService {
  AuthService(this._dio);

  final Dio _dio;

  Future<void> register({
    required String email,
    required String username,
    String? fullName,
    required String password,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: <String, dynamic>{
        'email': email,
        'username': username,
        if (fullName != null && fullName.trim().isNotEmpty)
          'full_name': fullName.trim(),
        'password': password,
      },
    );
  }

  Future<TokenResponse> verifyActivationOtp({
    required String email,
    required String otpCode,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/verify-otp',
      data: <String, dynamic>{
        'email': email,
        'otp_code': otpCode,
      },
    );
    return TokenResponse.fromJson(res.data!);
  }

  Future<void> resendOtp(String email) async {
    await _dio.post<Map<String, dynamic>>(
      '/auth/resend-otp',
      data: <String, dynamic>{'email': email},
    );
  }

  Future<TokenResponse> login({
    required String identifier,
    required String password,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: <String, dynamic>{
        'username': identifier,
        'password': password,
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
      ),
    );
    return TokenResponse.fromJson(res.data!);
  }

  Future<void> forgotPassword(String email) async {
    await _dio.post<Map<String, dynamic>>(
      '/auth/forgot-password',
      data: <String, dynamic>{'email': email},
    );
  }

  Future<void> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/auth/reset-password',
      data: <String, dynamic>{
        'email': email,
        'otp_code': otpCode,
        'new_password': newPassword,
      },
    );
  }

  Future<AdminUser> me() async {
    final res = await _dio.get<Map<String, dynamic>>('/users/me');
    return AdminUser.fromJson(res.data!);
  }
}
