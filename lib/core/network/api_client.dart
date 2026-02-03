import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import 'dart:io';

class ApiClient {
  final http.Client client;
  final storage = const FlutterSecureStorage();

  // NEW: Store token in memory for background isolate use
  String? manualToken;

  ApiClient(this.client);

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body, {bool auth = true}) async {
    print('Path: $path');
    print('Body: $body');
    print('URL: $baseUrl$path');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json', // IMPORTANT: Tells Laravel to return JSON, not 302 Redirects
    };

    if (auth) {
      // FIX: Check manualToken first (for background), then fall back to storage (for UI)
      String? token = manualToken;
      if (token == null) {
        try {
          token = await storage.read(key: tokenKey);
        } catch (e) {
          print("Storage read failed in this isolate: $e");
        }
      }

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    final response = await client.post(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );

    print('Response Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200 ) {
      print('Response Body: ${response.body}');
      return jsonDecode(response.body);
    } else {
      String errorMessage;
      try {
        final errorData = jsonDecode(response.body);
        errorMessage = errorData['message'] ?? 'An error occurred';
      } catch (e) {
        errorMessage = 'Server error: ${response.statusCode}';
      }
      throw errorMessage;
    }
  }

  // NEW: Multipart Request for Photo Upload
  Future<Map<String, dynamic>> postMultipart(String path, Map<String, dynamic> body, {bool auth = true}) async {
    print('Path (Multipart): $path');
    print('Body (Multipart): $body');
    print('URL: $baseUrl$path');

    final uri = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest('POST', uri);

    // Add headers
    request.headers['Accept'] = 'application/json';
    if (auth) {
      String? token = manualToken ?? await storage.read(key: tokenKey);
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }

    // Process Body: Separate file from other fields
    body.forEach((key, value) async {
      if (key == 'photo' && value != null && value is String && value.isNotEmpty) {
        // Add the file
        print('Adding file to request: $value');
        request.files.add(await http.MultipartFile.fromPath('photo', value));
      } else if (value != null) {
        // Add other fields as strings
        request.fields[key] = value.toString();
      }
    });

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print('Response Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      String errorMessage;
      try {
        final errorData = jsonDecode(response.body);
        errorMessage = errorData['message'] ?? 'An error occurred';
      } catch (e) {
        errorMessage = 'Server error: ${response.statusCode}';
      }
      throw errorMessage;
    }
  }

  Future<Map<String, dynamic>> get(String path) async {
    print('Path: $path');
    print('URL: $baseUrl$path');

    String? token = manualToken ?? await storage.read(key: tokenKey);

    final response = await client.get(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
    print('Response Body: ${response.body}');
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load profile');
  }
}