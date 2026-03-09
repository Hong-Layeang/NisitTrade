import 'package:equatable/equatable.dart';

/// Domain entity representing a university
class UniversityEntity extends Equatable {
  final int id;
  final String name;
  final String domain;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UniversityEntity({
    required this.id,
    required this.name,
    required this.domain,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, name, domain, createdAt, updatedAt];
}
