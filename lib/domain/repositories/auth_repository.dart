import 'package:geo_tracker_app/domain/entities/user_entity.dart';

import '../entities/center_entity.dart';
import '../entities/register_request_entity.dart';

abstract class AuthRepository {
  Future<Map<String, dynamic>> login(String username, String password);
  Future<void> logout();
  Future<List<CenterEntity>> getCenters();
  Future<void> register(RegisterRequestEntity data);
  Future<UserProfileEntity> getProfile();
}