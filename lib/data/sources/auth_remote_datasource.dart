import '../../core/network/api_client.dart';
import '../../core/constants/app_constants.dart';

abstract class AuthRemoteDataSource {
  Future<String> login(String username, String password);
  Future<void> logout();
  Future<Map<String, dynamic>> getProfile();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient client;

  AuthRemoteDataSourceImpl({required this.client});

  @override
  Future<String> login(String username, String password) async {
    print('username: $username, password: $password}');
    final res = await client.post(loginEndpoint, {'email': username, 'password': password}, auth: false);
    final token = res['token'] as String;
    await client.storage.write(key: tokenKey, value: token);
    return token;
  }

  @override
  Future<void> logout() async {
    await client.post(logoutEndpoint, {});
    await client.storage.delete(key: tokenKey);
  }

  @override
  Future<Map<String, dynamic>> getProfile() => client.get(profileEndpoint);
}