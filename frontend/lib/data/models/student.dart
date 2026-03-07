class Student {
  final String id;
  final String name;
  final String username;
  final String avatarUrl;
  final bool isFollowing;

  const Student({
    required this.id,
    required this.name,
    required this.username,
    required this.avatarUrl,
    this.isFollowing = false,
  });
}
