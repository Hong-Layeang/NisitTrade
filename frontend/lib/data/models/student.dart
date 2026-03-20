class Student {
  final int id;
  final String name;
  final String username;
  final String? avatarUrl;
  final bool isFollowing;
  final bool isOnline;
  final DateTime? lastSeenAt;

  const Student({
    required this.id,
    required this.name,
    required this.username,
    this.avatarUrl,
    this.isFollowing = false,
    this.isOnline = false,
    this.lastSeenAt,
  });

  String? get profileImage => avatarUrl;

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: _toInt(json['id']),
      name: (json['full_name'] ?? json['name'] ?? '') as String,
      username: (json['email'] ?? json['username'] ?? '') as String,
      avatarUrl: json['profile_image'] as String?,
      isFollowing: json['is_following'] as bool? ?? false,
      isOnline: json['is_online'] as bool? ?? false,
      lastSeenAt: (json['last_seen_at'] ?? json['lastSeenAt']) is String
          ? DateTime.tryParse((json['last_seen_at'] ?? json['lastSeenAt']) as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': name,
    'email': username,
    'profile_image': avatarUrl,
    'is_following': isFollowing,
    'is_online': isOnline,
    'last_seen_at': lastSeenAt?.toIso8601String(),
  };
}
