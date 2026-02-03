// domain/entities/center_entity.dart
import 'package:equatable/equatable.dart';

class CenterEntity extends Equatable {
  final int id;
  final String name;
  final String? nameBn;
  final double? latitude;
  final double? longitude;
  final int? radius;
  final String? status;

  const CenterEntity({
    required this.id,
    required this.name,
    this.nameBn,
    this.latitude,
    this.longitude,
    this.radius,
    this.status,
  });

  @override
  List<Object?> get props => [id, name, nameBn, latitude, longitude, radius, status];
}