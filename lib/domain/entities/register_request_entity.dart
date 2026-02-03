class RegisterRequestEntity {
  final String name;
  final String email;
  final String phone;
  final String designation;
  final String password;
  final String confirmPassword;
  final String status;
  final String? imagePath;

  RegisterRequestEntity({
    required this.name,
    required this.email,
    required this.phone,
    required this.designation,
    required this.password,
    required this.confirmPassword,
    required this.status,
    this.imagePath,
  });
}