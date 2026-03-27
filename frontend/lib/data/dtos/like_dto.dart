import 'seller_dto.dart';

class LikeDto {
  final int id;
  final int userId;
  final int productId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SellerDto? user;

  const LikeDto({
    required this.id,
    required this.userId,
    required this.productId,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  factory LikeDto.fromJson(Map<String, dynamic> json) {
    return LikeDto(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      productId: json['product_id'] as int? ?? 0,
      createdAt: (json['createdAt'] ?? json['created_at']) != null
          ? DateTime.parse((json['createdAt'] ?? json['created_at']) as String)
          : DateTime.now(),
      updatedAt: (json['updatedAt'] ?? json['updated_at']) != null
          ? DateTime.parse((json['updatedAt'] ?? json['updated_at']) as String)
          : DateTime.now(),
      user: json['User'] != null
          ? SellerDto.fromJson(json['User'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'product_id': productId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (user != null) 'User': user!.toJson(),
    };
  }

  LikeDto copyWith({
    int? id,
    int? userId,
    int? productId,
    DateTime? createdAt,
    DateTime? updatedAt,
    SellerDto? user,
  }) {
    return LikeDto(
      id: id ?? this.id,
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
      other is LikeDto && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
