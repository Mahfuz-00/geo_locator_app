import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class ApiClient {
  final http.Client client;
  final storage = const FlutterSecureStorage();

  ApiClient(this.client);

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body, {bool auth = true}) async {
    print('Path: $path');
    print('Body: $body');
    print('URL: $baseUrl$path');
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await storage.read(key: tokenKey);
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    final response = await client.post(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );

    print('Response Code: ${response.statusCode}');

    if (response.statusCode == 200 ) {
      print('Response Body: ${response.body}');
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> get(String path) async {
    final token = await storage.read(key: tokenKey);
    final response = await client.get(
      Uri.parse('$baseUrl$path'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load profile');
  }
}