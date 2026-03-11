import 'api_exception.dart';

class AppErrorMessages {
  AppErrorMessages._();

  static String resolve(
    Object? error, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    final raw = _extract(error).trim();
    if (raw.isEmpty) return fallback;

    final normalized = raw.toLowerCase();

    if (isAlreadyFollowingMessage(raw)) {
      return 'You are already following this user.';
    }

    if (isNotFollowingMessage(raw)) {
      return 'You are no longer following this user.';
    }

    if (normalized.contains('timeout')) {
      return 'The request took too long. Please try again.';
    }

    if (normalized.contains('no internet') ||
        normalized.contains('network') ||
        normalized.contains('connection error') ||
        normalized.contains('socketexception')) {
      return 'Please check your internet connection and try again.';
    }

    if (normalized == 'unauthorized' ||
        normalized.contains('session has expired')) {
      return 'Your session has expired. Please sign in again.';
    }

    if (normalized.contains('forbidden')) {
      return 'You do not have permission to do that.';
    }

    if (normalized.contains('not found')) {
      return 'The requested item could not be found.';
    }

    if (_looksTechnical(raw, normalized)) {
      return fallback;
    }

    return raw;
  }

  static bool isAlreadyFollowingMessage(Object? error) {
    return _extract(error).trim().toLowerCase() == 'already following this user';
  }

  static bool isNotFollowingMessage(Object? error) {
    return _extract(error).trim().toLowerCase() == 'not following this user';
  }

  static String _extract(Object? error) {
    if (error == null) return '';
    if (error is ApiException) return error.message;
    if (error is Exception) return error.toString();
    return error.toString();
  }

  static bool _looksTechnical(String raw, String normalized) {
    return raw.contains('\n') ||
        normalized.contains('exception') ||
        normalized.contains('dioexception') ||
        normalized.contains('typeerror') ||
        normalized.contains('stack trace') ||
        normalized.contains('sequelize') ||
        normalized.contains('sql') ||
        normalized.contains('xmlhttprequest') ||
        normalized.contains('failed to fetch') ||
        normalized.contains('internal server error') ||
        normalized.contains('error:') ||
        normalized.startsWith('failed to ');
  }
}