class UserProfileEntity {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String status;
  final String createdAt;

  UserProfileEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
    required this.createdAt,
  });
}