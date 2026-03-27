import '../dtos/student_dto.dart';

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

  factory Student.fromDto(StudentDto dto) {
    return Student(
      id: dto.id,
      name: dto.name,
      username: dto.username,
      avatarUrl: dto.avatarUrl,
      isFollowing: dto.isFollowing,
      isOnline: dto.isOnline,
      lastSeenAt: dto.lastSeenAt,
    );
  }
}