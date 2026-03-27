class UniversityDto {
  final int id;
  final String name;
  final String domain;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UniversityDto({
    required this.id,
    required this.name,
    required this.domain,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UniversityDto.fromJson(Map<String, dynamic> json) {
    return UniversityDto(
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'domain': domain,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UniversityDto copyWith({
    int? id,
    String? name,
    String? domain,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UniversityDto(
      id: id ?? this.id,
      name: name ?? this.name,
      domain: domain ?? this.domain,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
