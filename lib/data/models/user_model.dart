

import '../../domain/entities/user_entity.dart';

class UserProfileModel extends UserProfileEntity {
  UserProfileModel({
    required super.id,
    required super.name,
    required super.email,
    required super.phone,
    required super.status,
    required super.createdAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    // Assuming your API returns { "user": { ... } } or just the user object
    final user = json['user'] ?? json;

    return UserProfileModel(
      id: user['id'] ?? 0,
      name: user['name'] ?? 'N/A',
      email: user['email'] ?? 'N/A',
      phone: user['phone'] ?? 'N/A',
      status: user['status'] ?? 'inactive',
      createdAt: user['created_at'] ?? '',
    );
  }
}