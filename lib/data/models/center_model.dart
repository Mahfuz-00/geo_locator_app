import '../../domain/entities/center_entity.dart';

class CenterModel extends CenterEntity {
  const CenterModel({
    required super.id,
    required super.name,
    super.nameBn,
    required super.latitude,
    required super.longitude,
    required super.radius,
    required super.status,
  });

  factory CenterModel.fromJson(Map<String, dynamic> json) {
    return CenterModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown Center',
      nameBn: json['name_bn'],
      // API returns these as Strings, we convert to double
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      radius: json['radius'] ?? 0,
      status: json['status'] ?? 'inactive',
    );
  }
}