import 'package:flutter/widgets.dart';

/// Extensions for State class to reduce boilerplate code.
extension SafeSetState on State {
  /// Calls setState only if the widget is still mounted.
  /// This prevents the common "setState called after dispose" error.
  ///
  /// Usage:
  /// ```dart
  /// setStateIfMounted(() {
  ///   _isLoading = false;
  /// });
  /// ```
  void setStateIfMounted(VoidCallback fn) {
    if (mounted) {
      // ignore: invalid_use_of_protected_member
      setState(fn);
    }
  }
}
