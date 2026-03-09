import 'package:equatable/equatable.dart';

/// Domain entity representing a product category
class CategoryEntity extends Equatable {
  final int id;
  final String name;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CategoryEntity({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Returns true if this category has an image
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  /// Returns a display name for the category
  String get displayName => name;

  @override
  List<Object?> get props => [id, name, imageUrl, createdAt, updatedAt];
}
