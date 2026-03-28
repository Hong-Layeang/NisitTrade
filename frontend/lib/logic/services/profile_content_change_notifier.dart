import 'package:flutter/material.dart';

enum ProfileContentEntity { product, communityPost }

class ProfileContentChangeEvent {
  const ProfileContentChangeEvent({
    required this.changeId,
    required this.ownerUserId,
    required this.entity,
  });

  final int changeId;
  final int ownerUserId;
  final ProfileContentEntity entity;
}

class ProfileContentChangeNotifier extends ChangeNotifier {
  int _changeId = 0;
  ProfileContentChangeEvent? _lastEvent;

  ProfileContentChangeEvent? get lastEvent => _lastEvent;

  void markProductChanged({required int ownerUserId}) {
    _markChanged(
      ownerUserId: ownerUserId,
      entity: ProfileContentEntity.product,
    );
  }

  void markCommunityPostChanged({required int ownerUserId}) {
    _markChanged(
      ownerUserId: ownerUserId,
      entity: ProfileContentEntity.communityPost,
    );
  }

  void _markChanged({
    required int ownerUserId,
    required ProfileContentEntity entity,
  }) {
    _changeId += 1;
    _lastEvent = ProfileContentChangeEvent(
      changeId: _changeId,
      ownerUserId: ownerUserId,
      entity: entity,
    );
    notifyListeners();
  }
}