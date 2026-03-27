import '../dtos/category_dto.dart';

class Category {
  final int id;
  final String name;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Category({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  factory Category.fromDto(CategoryDto dto) {
    return Category(
      id: dto.id,
      name: dto.name,
      imageUrl: dto.imageUrl,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
    );
  }

  Category copyWith({
    int? id,
    String? name,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}