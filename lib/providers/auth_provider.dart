import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService api;

  bool isLoading = false;
  String? error;
  String? authMessage;

  String? email;
  String? role;
  int? userId;

  bool _handlingSessionExpired = false;

  AuthProvider({required this.api}) {
    api.onUnauthorized = () {
      unawaited(_expireSession());
    };
  }

  bool get isAuthenticated {
    final token = api.token;

    if (token == null || token.isEmpty) {
      return false;
    }

    return !_isJwtExpired(token);
  }

  String get normalizedRole {
    return (role ?? '').trim().toLowerCase();
  }

  bool get isTutor => normalizedRole == 'tutor';
  bool get isParent => normalizedRole == 'parent';
  bool get isStudent => normalizedRole == 'student';
  bool get isLearner => isParent || isStudent;
  bool get isAdmin => normalizedRole == 'admin';

  String get landingRouteAfterLogin {
    if (isAdmin) return '/admin';
    if (isTutor) return '/tutor-verification';
    return '/home';
  }

  Future<void> bootstrap() async {
    final token = api.token;

    if (token == null || token.isEmpty) {
      _clearUserState();
      notifyListeners();
      return;
    }

    if (_isJwtExpired(token)) {
      await logout(sessionExpired: true);
      return;
    }

    _readClaimsFromToken();
    notifyListeners();
  }

  Future<void> login(
      String inputEmail,
      String password, {
        List<String>? allowedRoles,
      }) async {
    authMessage = null;

    await _guard(() async {
      final data = await api.login(
        email: inputEmail,
        password: password,
      );

      authMessage = null;
      email = inputEmail;

      final responseRole = data['role']?.toString();
      final responseUserId = int.tryParse(data['userId']?.toString() ?? '');

      if (responseRole != null && responseRole.trim().isNotEmpty) {
        role = responseRole.trim();
      }

      if (responseUserId != null) {
        userId = responseUserId;
      }

      _readClaimsFromToken();

      if (allowedRoles != null && allowedRoles.isNotEmpty) {
        final currentRole = normalizedRole;

        final allowed = allowedRoles
            .map((e) => e.trim().toLowerCase())
            .where((e) => e.isNotEmpty)
            .toSet();

        if (!allowed.contains(currentRole)) {
          await api.clearTokens();

          _clearUserState();

          final displayRole = currentRole.isEmpty ? 'unknown role' : currentRole;

          throw Exception(
            'This account is $displayRole. Please use the correct login type.',
          );
        }
      }
    });
  }

  Future<void> register({
    required String name,
    required String inputEmail,
    required String password,
    required String role,
    required String phone,
    String? school,
    String? bio,
    String? address,
  }) async {
    authMessage = null;

    await _guard(() async {
      await api.register(
        name: name,
        email: inputEmail,
        password: password,
        role: role,
        phone: phone,
        school: school,
        bio: bio,
        address: address,
      );
    });
  }

  Future<void> verifyEmail({
    required String inputEmail,
    required String code,
  }) async {
    await _guard(() async {
      await api.verifyEmail(
        email: inputEmail,
        code: code,
      );
    });
  }

  Future<void> resendVerificationCode({
    required String inputEmail,
  }) async {
    await _guard(() async {
      await api.resendVerificationCode(
        email: inputEmail,
      );
    });
  }

  Future<void> logout({bool sessionExpired = false}) async {
    await api.clearTokens();

    _clearUserState();

    error = null;

    authMessage = sessionExpired
        ? 'Session has expired. Please sign in again.'
        : null;

    _handlingSessionExpired = false;

    notifyListeners();
  }

  Future<void> _expireSession() async {
    if (_handlingSessionExpired) return;

    _handlingSessionExpired = true;

    await logout(sessionExpired: true);
  }

  void clearError() {
    error = null;
    notifyListeners();
  }

  void clearAuthMessage() {
    authMessage = null;
    notifyListeners();
  }

  Future<void> _guard(Future<void> Function() task) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await task();
    } catch (e) {
      final message = apiErrorMessage(e).replaceFirst('Exception: ', '').trim();

      error = message;

      if (_shouldShowAsAuthMessage(message)) {
        authMessage = message;
      }

      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  bool _shouldShowAsAuthMessage(String message) {
    final value = message.toLowerCase();

    return value.contains('deactivated') ||
        value.contains('inactive') ||
        value.contains('disabled') ||
        value.contains('not active') ||
        value.contains('contact edunest support') ||
        value.contains('contact support');
  }

  bool _isJwtExpired(String jwt) {
    try {
      final parts = jwt.split('.');

      if (parts.length != 3) {
        return true;
      }

      final payload = utf8.decode(
        base64Url.decode(
          base64Url.normalize(parts[1]),
        ),
      );

      final data = jsonDecode(payload) as Map<String, dynamic>;

      final exp = data['exp'];

      if (exp == null) {
        return true;
      }

      final expiryDate = DateTime.fromMillisecondsSinceEpoch(
        int.parse(exp.toString()) * 1000,
      );

      return DateTime.now().isAfter(expiryDate);
    } catch (_) {
      return true;
    }
  }

  void _readClaimsFromToken() {
    final token = api.token;

    if (token == null || token.isEmpty || !token.contains('.')) {
      _clearUserState();
      return;
    }

    try {
      final parts = token.split('.');

      if (parts.length < 2) return;

      final payload = utf8.decode(
        base64Url.decode(
          base64Url.normalize(parts[1]),
        ),
      );

      final data = jsonDecode(payload) as Map<String, dynamic>;

      final idValue = data['nameid'] ??
          data['sub'] ??
          data['userId'] ??
          data[
          'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'];

      final roleValue = data['role'] ??
          data[
          'http://schemas.microsoft.com/ws/2008/06/identity/claims/role'];

      final emailValue = data['email'] ??
          data[
          'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress'];

      final parsedUserId = int.tryParse(idValue?.toString() ?? '');

      if (parsedUserId != null) {
        userId = parsedUserId;
      }

      final parsedRole = _parseRole(roleValue);

      if (parsedRole != null && parsedRole.trim().isNotEmpty) {
        role = parsedRole.trim();
      }

      if (emailValue != null && emailValue.toString().trim().isNotEmpty) {
        email = emailValue.toString().trim();
      }
    } catch (_) {
      _clearUserState();
    }
  }

  String? _parseRole(dynamic value) {
    if (value == null) return null;

    if (value is List && value.isNotEmpty) {
      return value.first.toString();
    }

    return value.toString();
  }

  void _clearUserState() {
    email = null;
    role = null;
    userId = null;
  }
}