import '../../domain/entities/university_entity.dart';

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

  factory University.fromJson(Map<String, dynamic> json) {
    return University(
      id: json['id'] as int? ?? 0,
      name: (json['name'] ?? '') as String,
      domain: (json['domain'] ?? '') as String,
      createdAt: (json['createdAt'] ?? json['created_at']) != null
          ? DateTime.parse((json['createdAt'] ?? json['created_at']) as String)
          : DateTime.now(),
      updatedAt: (json['updatedAt'] ?? json['updated_at']) != null
          ? DateTime.parse((json['updatedAt'] ?? json['updated_at']) as String)
          : DateTime.now(),
    );
  }

  /// Convert to domain entity
  UniversityEntity toEntity() {
    return UniversityEntity(
      id: id,
      name: name,
      domain: domain,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create from domain entity
  factory University.fromEntity(UniversityEntity entity) {
    return University(
      id: entity.id,
      name: entity.name,
      domain: entity.domain,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
