import 'seller_dto.dart';

class CommentDto {
  final int id;
  final String content;
  final int? rating;
  final int userId;
  final int productId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SellerDto? user;

  const CommentDto({
    required this.id,
    required this.content,
    this.rating,
    required this.userId,
    required this.productId,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  factory CommentDto.fromJson(Map<String, dynamic> json) {
    final createdRaw = json['createdAt'] ?? json['created_at'];
    final updatedRaw = json['updatedAt'] ?? json['updated_at'];
    final userJson = json['User'] ?? json['user'];
    final parsedUserId = _toInt(
      json['user_id'] ??
          json['userId'] ??
          (userJson is Map<String, dynamic> ? userJson['id'] : null),
    );

    return CommentDto(
      id: _toInt(json['id']),
      content: (json['content'] ?? '') as String,
      rating: json['rating'] is int
          ? json['rating'] as int
          : (json['rating'] is String
              ? int.tryParse(json['rating'] as String)
              : null),
      userId: parsedUserId,
      productId: _toInt(json['product_id'] ?? json['productId']),
      createdAt:
          createdRaw != null ? DateTime.parse(createdRaw as String) : DateTime.now(),
      updatedAt:
          updatedRaw != null ? DateTime.parse(updatedRaw as String) : DateTime.now(),
      user: userJson is Map<String, dynamic>
          ? SellerDto.fromJson(userJson)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      if (rating != null) 'rating': rating,
      'user_id': userId,
      'product_id': productId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (user != null) 'User': user!.toJson(),
    };
  }

  CommentDto copyWith({
    int? id,
    String? content,
    int? rating,
    int? userId,
    int? productId,
    DateTime? createdAt,
    DateTime? updatedAt,
    SellerDto? user,
  }) {
    return CommentDto(
      id: id ?? this.id,
      content: content ?? this.content,
      rating: rating ?? this.rating,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      user: user ?? this.user,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommentDto && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
