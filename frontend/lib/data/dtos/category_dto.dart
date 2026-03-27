class CategoryDto {
  final int id;
  final String name;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CategoryDto({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  factory CategoryDto.fromJson(Map<String, dynamic> json) {
    return CategoryDto(
      id: json['id'] as int? ?? 0,
      name: (json['name'] ?? '') as String,
      imageUrl: json['image_url'] as String?,
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
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CategoryDto copyWith({
    int? id,
    String? name,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryDto(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
