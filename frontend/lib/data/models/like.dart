import '../dtos/like_dto.dart';
import 'seller.dart';

class Like {
  final int id;
  final int userId;
  final int productId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Seller? user;

  const Like({
    required this.id,
    required this.userId,
    required this.productId,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  factory Like.fromDto(LikeDto dto) {
    return Like(
      id: dto.id,
      userId: dto.userId,
      productId: dto.productId,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
      user: dto.user != null ? Seller.fromDto(dto.user!) : null,
    );
  }

  Like copyWith({
    int? id,
    int? userId,
    int? productId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Seller? user,
  }) {
    return Like(
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
      identical(this, other) || other is Like && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}