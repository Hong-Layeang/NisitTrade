import 'dart:convert';

import 'auth_token_store.dart';

class AuthSession {
  AuthSession._();

  static final AuthSession instance = AuthSession._();

  final AuthTokenStore _tokenStore = AuthTokenStore.instance;

  Future<bool> hasValidSession() async {
    final token = await _tokenStore.readToken();
    if (token == null || token.isEmpty) {
      return false;
    }

    if (_isExpired(token)) {
      await _tokenStore.clearToken();
      return false;
    }

    return true;
  }

  bool _isExpired(String token) {
    final payload = _decodePayload(token);
    if (payload.isEmpty) {
      return true;
    }

    final exp = payload['exp'];
    if (exp is! int) {
      return true;
    }

    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return nowSeconds >= exp;
  }

  Map<String, dynamic> _decodePayload(String token) {
    try {
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
}
