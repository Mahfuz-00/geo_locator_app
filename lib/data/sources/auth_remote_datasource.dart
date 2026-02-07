import 'package:flutter_background_service/flutter_background_service.dart';

import '../../core/network/api_client.dart';
import '../../core/constants/app_constants.dart';
import '../models/center_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login(String username, String password);
  Future<void> logout();
  Future<List<CenterModel>> getCenters();
  Future<void> register(Map<String, dynamic> data);
  Future<UserProfileModel> getProfile();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient client;

  AuthRemoteDataSourceImpl({required this.client});

  @override
  Future<Map<String, dynamic>> login(String username, String password) async {
    print('username: $username, password: $password}');
    final res = await client.post(loginEndpoint, {'email': username, 'password': password}, auth: false);
    // Save token to storage
    final token = res['token'] as String;
    print('Token: $token');
    // 1. Write and WAIT
    await client.storage.write(key: tokenKey, value: token);

    // 2. Read back to verify
    final savedToken = await client.storage.read(key: tokenKey);
    if (savedToken == token) {
      print('✅ [AuthSource] Token successfully saved to Storage: ${token.substring(0, 10)}...');
    } else {
      print('❌ [AuthSource] Token failed to save to Storage!');
    }

    // 3. INFORM BACKGROUND SERVICE
    try {
      FlutterBackgroundService().invoke('updateToken', {'token': token});
      print('📢 [AuthSource] updateToken event sent to Background Service');
    } catch (e) {
      print('⚠️ [AuthSource] Could not invoke Background Service: $e');
    }


    // Save district name to storage so CheckAuth can find it later
    if (res['district_name'] != null) {
      await client.storage.write(key: 'district_name', value: res['district_name']);
    }

    return res; // Return the WHOLE Map, not just the token string
  }

  @override
  Future<void> logout() async {
    await client.post(logoutEndpoint, {});
    await client.storage.delete(key: tokenKey);
    await client.storage.delete(key: 'district_name');
  }

  @override
  @override
  Future<List<CenterModel>> getCenters() async {
    final response = await client.get('/centers');

    // 1. Check if the response is a Map and contains the 'data' key
    if (response is Map<String, dynamic> && response['data'] != null) {
      final List<dynamic> dataList = response['data'];

      // 2. Map the list of JSON objects to CenterModel objects
      return dataList.map((json) => CenterModel.fromJson(json)).toList();
    }

    // Fallback return empty list if structure is unexpected
    return [];
  }

  @override
  Future<void> register(Map<String, dynamic> data) async {
    await client.postMultipart('/register', data, auth: false);
  }

  @override
  Future<UserProfileModel> getProfile() async {
    final res = await client.get(profileEndpoint);
    return UserProfileModel.fromJson(res);
  }
}