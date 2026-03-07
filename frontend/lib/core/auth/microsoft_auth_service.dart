import 'dart:convert';

import 'package:aad_oauth/aad_oauth.dart';
import 'package:aad_oauth/model/config.dart';

import '../navigation/app_navigator.dart';
import 'auth_token_store.dart';
import 'microsoft_auth_api.dart';

enum MicrosoftAuthStatus {
  authenticated,
  needsPasswordSetup,
  failed,
}

class MicrosoftAuthResult {
  final MicrosoftAuthStatus status;
  final String? email;
  final String? token;
  final String message;

  const MicrosoftAuthResult._({
    required this.status,
    required this.email,
    required this.token,
    required this.message,
  });

  bool get isAuthenticated => status == MicrosoftAuthStatus.authenticated;

  bool get needsPasswordSetup =>
      status == MicrosoftAuthStatus.needsPasswordSetup;

  factory MicrosoftAuthResult.authenticated({
    required String email,
    required String token,
  }) {
    return MicrosoftAuthResult._(
      status: MicrosoftAuthStatus.authenticated,
      email: email,
      token: token,
      message: 'Signed in successfully.',
    );
  }

  factory MicrosoftAuthResult.passwordSetupRequired({
    required String email,
    required String token,
  }) {
    return MicrosoftAuthResult._(
      status: MicrosoftAuthStatus.needsPasswordSetup,
      email: email,
      token: token,
      message: 'Password setup required.',
    );
  }

  factory MicrosoftAuthResult.failure(String message) {
    return MicrosoftAuthResult._(
      status: MicrosoftAuthStatus.failed,
      email: null,
      token: null,
      message: message,
    );
  }
}

enum PasswordSetupStatus {
  success,
  failed,
}

class PasswordSetupResult {
  final PasswordSetupStatus status;
  final String? token;
  final String message;

  const PasswordSetupResult._({
    required this.status,
    required this.token,
    required this.message,
  });

  bool get isSuccess => status == PasswordSetupStatus.success;

  factory PasswordSetupResult.success(String token) {
    return PasswordSetupResult._(
      status: PasswordSetupStatus.success,
      token: token,
      message: 'Password set successfully.',
    );
  }

  factory PasswordSetupResult.failure(String message) {
    return PasswordSetupResult._(
      status: PasswordSetupStatus.failed,
      token: null,
      message: message,
    );
  }
}

class MicrosoftAuthService {
  MicrosoftAuthService._();

  static final MicrosoftAuthService instance = MicrosoftAuthService._();

  static const String _clientId = 'acc07294-0e89-4caf-94c2-e593a12a807b';
  static const String _tenantId = '1e9461ec-5362-4329-ae46-61fa3e91c6d2';
  static const String _redirectUri =
      'msalacc07294-0e89-4caf-94c2-e593a12a807b://auth';

  static const List<String> _allowedDomains = ['student.cadt.edu.kh'];
  static const String _genericFailureMessage = 'Microsoft sign-in failed.';
  static const String _missingTokenMessage =
      'Microsoft sign-in failed. Missing access token.';
  static const String _passwordSetupFailedMessage =
      'Password setup failed. Please try again.';
  static const Set<String> _allowedMessages = {
    'Authentication failed',
    'Invalid request',
    'Invalid credentials',
    'Password is required',
    'Password already set',
    'Password must be at least 8 characters',
    'Password must contain uppercase, lowercase, and numbers',
    'Unauthorized',
  };

  final AadOAuth _oauth = AadOAuth(
    Config(
      tenant: _tenantId,
      clientId: _clientId,
      scope: 'openid profile email offline_access',
      redirectUri: _redirectUri,
      navigatorKey: appNavigatorKey,
      prompt: 'select_account',
    ),
  );
  final MicrosoftAuthApi _authApi = MicrosoftAuthApi();
  final AuthTokenStore _tokenStore = AuthTokenStore.instance;

  Future<MicrosoftAuthResult> signIn() async {
    try {
      await _oauth.login();
      final idToken = await _oauth.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        await _safeLogout();
        return MicrosoftAuthResult.failure(_genericFailureMessage);
      }

      // Use ID token claims to enforce tenant email domain early.
      final claims = _decodeJwt(idToken);
      final email = _extractEmail(claims);
      if (email == null || email.isEmpty) {
        await _safeLogout();
        return MicrosoftAuthResult.failure(_genericFailureMessage);
      }

      if (!_isAllowedDomain(email)) {
        await _safeLogout();
        return MicrosoftAuthResult.failure(_genericFailureMessage);
      }

      // Backend validates token and indicates whether password setup is needed.
      final response = await _authApi.signInWithMicrosoft(idToken);
      if (!response.isValid) {
        await _safeLogout();
        final safeMessage = _sanitizeMessage(response.message);
        return MicrosoftAuthResult.failure(
          safeMessage ?? _genericFailureMessage,
        );
      }

      final token = response.token;
      if (token == null || token.isEmpty) {
        await _safeLogout();
        return MicrosoftAuthResult.failure(_missingTokenMessage);
      }

      if (response.needsPasswordSetup) {
        return MicrosoftAuthResult.passwordSetupRequired(
          email: email,
          token: token,
        );
      }

      await _tokenStore.saveToken(token);
      return MicrosoftAuthResult.authenticated(
        email: email,
        token: token,
      );
    } catch (_) {
      await _safeLogout();
      return MicrosoftAuthResult.failure(_genericFailureMessage);
    }
  }

  Future<PasswordSetupResult> setPassword({
    required String accessToken,
    required String password,
  }) async {
    if (password.isEmpty || accessToken.isEmpty) {
      return PasswordSetupResult.failure(_passwordSetupFailedMessage);
    }

    final response = await _authApi.setPassword(
      accessToken: accessToken,
      password: password,
    );

    if (!response.isValid) {
      final safeMessage = _sanitizeMessage(response.message);
      return PasswordSetupResult.failure(
        safeMessage ?? _passwordSetupFailedMessage,
      );
    }

    // Backend returns a new JWT after a successful password setup.
    final token = response.token;
    if (token == null || token.isEmpty) {
      return PasswordSetupResult.failure(_passwordSetupFailedMessage);
    }

    await _tokenStore.saveToken(token);
    return PasswordSetupResult.success(token);
  }

  Map<String, dynamic> _decodeJwt(String token) {
    try {
      // Basic JWT payload decode (no signature verification).
      final parts = token.split('.');
      if (parts.length != 3) {
        return <String, dynamic>{};
      }

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return json.decode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  String? _extractEmail(Map<String, dynamic> claims) {
    final preferred = claims['preferred_username'];
    if (preferred is String && preferred.isNotEmpty) {
      return preferred;
    }

    final upn = claims['upn'];
    if (upn is String && upn.isNotEmpty) {
      return upn;
    }

    final email = claims['email'];
    if (email is String && email.isNotEmpty) {
      return email;
    }

    return null;
  }

  bool _isAllowedDomain(String email) {
    final parts = email.split('@');
    if (parts.length != 2) {
      return false;
    }
    final domain = parts.last.toLowerCase();
    return _allowedDomains.contains(domain);
  }

  String? _sanitizeMessage(String? message) {
    if (message == null) {
      return null;
    }
    return _allowedMessages.contains(message) ? message : null;
  }

  Future<void> _safeLogout() async {
    try {
      await _oauth.logout();
    } catch (_) {
      // Ignore logout failures.
    }
  }
}
