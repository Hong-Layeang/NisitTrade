import 'package:equatable/equatable.dart';

/// Domain entity representing a seller/user
/// This is a pure business object with no framework dependencies
class SellerEntity extends Equatable {
  final int id;
  final String fullName;
  final String? profileImage;
  final String? major;

  const SellerEntity({
    required this.id,
    required this.fullName,
    this.profileImage,
    this.major,
  });

  /// Returns true if the seller has a profile image
  bool get hasProfileImage => profileImage != null && profileImage!.isNotEmpty;

  /// Returns display name for the seller
  String get displayName => fullName;

  @override
  List<Object?> get props => [id, fullName, profileImage, major];
}
