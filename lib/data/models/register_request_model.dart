import '../../domain/entities/register_request_entity.dart';

class RegisterRequestModel extends RegisterRequestEntity {
  RegisterRequestModel({
    required super.name,
    required super.email,
    required super.phone,
    required super.designation,
    required super.password,
    required super.confirmPassword,
    required super.status,
    required super.imagePath,
  });

  // This is what the ApiClient will actually send
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'designation': designation,
      'password': password,
      'confirm_password': confirmPassword,
      'status': status,
      'photo': imagePath,
    };
  }

  // Helper to convert Entity to Model
  factory RegisterRequestModel.fromEntity(RegisterRequestEntity entity) {
    return RegisterRequestModel(
      name: entity.name,
      email: entity.email,
      phone: entity.phone,
      designation: entity.designation,
      password: entity.password,
      confirmPassword: entity.confirmPassword,
      status: entity.status,
      imagePath: entity.imagePath,
    );
  }
}