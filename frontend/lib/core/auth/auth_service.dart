import '../../data/providers/auth_api.dart';
import 'auth_token_store.dart';

enum LoginStatus {
  authenticated,
  failed,
}

class LoginResult {
  final LoginStatus status;
  final String? token;
  final Map<String, dynamic>? user;
  final String message;

  const LoginResult._({
    required this.status,
    required this.token,
    required this.user,
    required this.message,
  });

  bool get isAuthenticated => status == LoginStatus.authenticated;

  factory LoginResult.authenticated({
    required String token,
    required Map<String, dynamic>? user,
  }) {
    return LoginResult._(
      status: LoginStatus.authenticated,
      token: token,
      user: user,
      message: 'Signed in successfully.',
    );
  }

  factory LoginResult.failure(String message) {
    return LoginResult._(
      status: LoginStatus.failed,
      token: null,
      user: null,
      message: message,
    );
  }
}

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  static const String _defaultFailureMessage = 'Login failed. Please try again.';
  static const Set<String> _allowedMessages = {
    'Email and password are required',
    'Invalid credentials',
  };

  final AuthApi _authApi = AuthApi();
  final AuthTokenStore _tokenStore = AuthTokenStore.instance;

  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _authApi.login(
      email: email,
      password: password,
    );

    if (!response.isValid) {
      final safeMessage = _sanitizeMessage(response.message);
      return LoginResult.failure(safeMessage ?? _defaultFailureMessage);
    }

    final token = response.token;
    if (token == null || token.isEmpty) {
      return LoginResult.failure(_defaultFailureMessage);
    }

    await _tokenStore.saveToken(token);
    return LoginResult.authenticated(
      token: token,
      user: response.user,
    );
  }

  Future<void> logout() async {
    await _tokenStore.clearToken();
  }

  static String? _sanitizeMessage(String? message) {
    if (message == null) {
      return null;
    }
    return _allowedMessages.contains(message) ? message : null;
  }
}
