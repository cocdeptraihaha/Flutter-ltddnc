import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/secure_store.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

final secureStoreProvider = Provider<SecureStore>((ref) => SecureStore());

final dioProvider = Provider<Dio>((ref) {
  final store = ref.watch(secureStoreProvider);
  return createDio(store);
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(dioProvider));
});

// --- Auth state ---

sealed class AuthState {
  const AuthState();
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

final class AuthAdmin extends AuthState {
  const AuthAdmin(this.user, this.token);

  final AdminUser user;
  final String token;
}

final class AuthBlocked extends AuthState {
  const AuthBlocked(this.user);

  final AdminUser user;
}

/// Kết quả sau login / verify OTP (điều hướng UI).
sealed class AuthActionResult {
  const AuthActionResult();
}

final class AuthActionAdminOk extends AuthActionResult {
  const AuthActionAdminOk();
}

final class AuthActionBlockedUser extends AuthActionResult {
  const AuthActionBlockedUser(this.user);

  final AdminUser user;
}

final class AuthActionFailed extends AuthActionResult {
  const AuthActionFailed(this.message);

  final String message;
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<AuthState> {
  SecureStore get _store => ref.read(secureStoreProvider);

  AuthService get _svc => ref.read(authServiceProvider);

  @override
  Future<AuthState> build() async => const AuthInitial();

  /// Khởi động app: đọc token, gọi `/users/me`, phân loại admin / chặn.
  Future<AuthState> bootstrap() async {
    state = const AsyncLoading();
    try {
      final token = await _store.readToken();
      if (token == null || token.isEmpty) {
        const next = AuthUnauthenticated();
        state = const AsyncData(next);
        return next;
      }
      final user = await _svc.me();
      if (!user.isSuperuser) {
        await _store.clearToken();
        final next = AuthBlocked(user);
        state = AsyncData(next);
        return next;
      }
      final next = AuthAdmin(user, token);
      state = AsyncData(next);
      return next;
    } catch (_) {
      await _store.clearToken();
      const next = AuthUnauthenticated();
      state = const AsyncData(next);
      return next;
    }
  }

  Future<AuthActionResult> login(String identifier, String password) async {
    try {
      final res = await _svc.login(identifier: identifier, password: password);
      return await _applyTokenResponse(res);
    } catch (e) {
      return AuthActionFailed(dioErrorMessage(e));
    }
  }

  Future<AuthActionResult> verifyActivation(String email, String code) async {
    try {
      final res = await _svc.verifyActivationOtp(email: email, otpCode: code);
      return await _applyTokenResponse(res);
    } catch (e) {
      return AuthActionFailed(dioErrorMessage(e));
    }
  }

  Future<AuthActionResult> _applyTokenResponse(TokenResponse res) async {
    if (!res.user.isSuperuser) {
      await _store.clearToken();
      state = AsyncData(AuthBlocked(res.user));
      return AuthActionBlockedUser(res.user);
    }
    await _store.saveToken(res.accessToken);
    state = AsyncData(AuthAdmin(res.user, res.accessToken));
    return const AuthActionAdminOk();
  }

  Future<void> logout() async {
    await _store.clearToken();
    state = const AsyncData(AuthUnauthenticated());
  }
}
