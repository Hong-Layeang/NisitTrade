import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../core/auth/auth_token_store.dart';
import '../services/presence_websocket_service.dart';

class UserPresence {
  final int userId;
  final bool isOnline;
  final DateTime? lastSeenAt;

  const UserPresence({
    required this.userId,
    required this.isOnline,
    required this.lastSeenAt,
  });
}

class PresenceViewModel extends ChangeNotifier with WidgetsBindingObserver {
  PresenceViewModel({
    required PresenceWebSocketService presenceService,
    AuthTokenStore? tokenStore,
  }) : _presenceService = presenceService,
       _tokenStore = tokenStore ?? AuthTokenStore.instance {
    WidgetsBinding.instance.addObserver(this);
    _subscription = _presenceService.events.listen(_onPresenceEvent);

    unawaited(ensureConnected());
    _ensureConnectionTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => unawaited(ensureConnected()),
    );
  }

  final PresenceWebSocketService _presenceService;
  final AuthTokenStore _tokenStore;

  final Map<int, UserPresence> _presenceByUserId = <int, UserPresence>{};
  final Set<int> _watchedUserIds = <int>{};

  StreamSubscription<UserPresenceEvent>? _subscription;
  Timer? _ensureConnectionTimer;
  bool _isEnsuringConnection = false;
  bool _isDisposed = false;

  UserPresence? presenceForUser(int userId) => _presenceByUserId[userId];

  void watchUserIds(Iterable<int> userIds) {
    final sanitized = userIds.where((id) => id > 0).toList();
    if (sanitized.isEmpty) {
      return;
    }

    final prevSize = _watchedUserIds.length;
    _watchedUserIds.addAll(sanitized);

    if (_watchedUserIds.length > prevSize) {
      _presenceService.watchUserIds(_watchedUserIds);
      unawaited(ensureConnected());
    }
  }

  Future<void> ensureConnected() async {
    if (_isDisposed || _isEnsuringConnection) {
      return;
    }

    _isEnsuringConnection = true;
    try {
      final token = await _tokenStore.readToken();
      if (token == null || token.isEmpty) {
        await _presenceService.disconnect();
        return;
      }

      await _presenceService.connect(token: token);
      if (_watchedUserIds.isNotEmpty) {
        _presenceService.watchUserIds(_watchedUserIds);
      }
    } catch (error, stackTrace) {
      debugPrint(
        'PresenceViewModel.ensureConnected error: $error\n$stackTrace',
      );
    } finally {
      _isEnsuringConnection = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) {
      return;
    }

    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(ensureConnected());
        break;
      case AppLifecycleState.detached:
        unawaited(_presenceService.disconnect());
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _ensureConnectionTimer?.cancel();
    _subscription?.cancel();
    unawaited(_presenceService.dispose());
    super.dispose();
  }

  void _onPresenceEvent(UserPresenceEvent event) {
    if (_isDisposed) {
      return;
    }

    _presenceByUserId[event.userId] = UserPresence(
      userId: event.userId,
      isOnline: event.isOnline,
      lastSeenAt: event.lastSeenAt,
    );
    notifyListeners();
  }
}
