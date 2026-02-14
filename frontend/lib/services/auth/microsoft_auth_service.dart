import 'dart:convert';

import 'package:aad_oauth/aad_oauth.dart';
import 'package:aad_oauth/model/config.dart';

import '../../utils/navigation/app_navigator.dart';
import 'microsoft_auth_api.dart';

class MicrosoftAuthResult {
  final bool isSuccess;
  final String? email;
  final String message;

  const MicrosoftAuthResult._(this.isSuccess, this.email, this.message);

  factory MicrosoftAuthResult.success(String email) {
    return MicrosoftAuthResult._(true, email, 'Signed in successfully.');
  }

  factory MicrosoftAuthResult.failure(String message) {
    return MicrosoftAuthResult._(false, null, message);
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

  final AadOAuth _oauth = AadOAuth(
    Config(
      tenant: _tenantId,
      clientId: _clientId,
      scope: 'openid profile email offline_access',
      redirectUri: _redirectUri,
      navigatorKey: appNavigatorKey,
      prompt: 'select_account'
    ),
  );
  final MicrosoftAuthApi _authApi = MicrosoftAuthApi();

  Future<MicrosoftAuthResult> signIn() async {
    try {
      await _oauth.login();
      final idToken = await _oauth.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        await _oauth.logout();
        return MicrosoftAuthResult.failure('Microsoft sign-in failed.');
      }

      final claims = _decodeJwt(idToken);
      final email = _extractEmail(claims);
      if (email == null || email.isEmpty) {
        await _oauth.logout();
        return MicrosoftAuthResult.failure('Microsoft sign-in failed.');
      }

      if (!_isAllowedDomain(email)) {
        await _oauth.logout();
        return MicrosoftAuthResult.failure(
          'Microsoft sign-in failed.',
        );
      }

      final backendAccepted = await _validateTokenWithBackend(idToken);
      if (!backendAccepted) {
        await _oauth.logout();
        return MicrosoftAuthResult.failure('Microsoft sign-in failed.');
      }

      return MicrosoftAuthResult.success(email);
    } catch (_) {
      return MicrosoftAuthResult.failure('Microsoft sign-in failed.');
    }
  }

  Map<String, dynamic> _decodeJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      return <String, dynamic>{};
    }

    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));
    return json.decode(decoded) as Map<String, dynamic>;
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

  Future<bool> _validateTokenWithBackend(String idToken) async {
    return _authApi.validateToken(idToken);
  }
}
