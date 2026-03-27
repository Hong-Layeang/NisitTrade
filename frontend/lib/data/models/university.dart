import '../dtos/university_dto.dart';

class University {
  final int id;
  final String name;
  final String domain;
  final DateTime createdAt;
  final DateTime updatedAt;

  const University({
    required this.id,
    required this.name,
    required this.domain,
    required this.createdAt,
    required this.updatedAt,
  });

  factory University.fromDto(UniversityDto dto) {
    return University(
      id: dto.id,
      name: dto.name,
      domain: dto.domain,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
    );
  }

  University copyWith({
    int? id,
    String? name,
    String? domain,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return University(
      id: id ?? this.id,
      name: name ?? this.name,
      domain: domain ?? this.domain,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}