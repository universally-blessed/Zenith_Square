import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Society {
  final String id;
  final String name;

  Society({required this.id, required this.name});

  factory Society.fromJson(Map<String, dynamic> json) =>
      Society(id: json['id'] ?? '', name: json['name'] ?? '');
}

class Block {
  final String id;
  final String name;

  Block({required this.id, required this.name});

  factory Block.fromJson(Map<String, dynamic> json) =>
      Block(id: json['id'] ?? '', name: json['name'] ?? '');
}

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  static const _storage = FlutterSecureStorage();

  static Future<List<Society>> fetchSocieties() async {
    final res = await http.get(Uri.parse('$baseUrl/societies/'));
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Society.fromJson(e)).toList();
    }
    throw Exception('Failed to load societies');
  }

  static Future<List<Block>> fetchBlocks(String societyId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/societies/$societyId/blocks/'),
    );
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Block.fromJson(e)).toList();
    }
    throw Exception('Failed to load blocks');
  }

  static Future<Map<String, dynamic>> registerResident(
    Map<String, dynamic> payload,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Registration failed');
    }
  }

  static Future<Map<String, dynamic>> verifyOtp(
    String email,
    String otp,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/verify-otp/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'OTP verification failed');
    }
  }

  static Future<void> saveAuthData({
    required String access,
    required String refresh,
    required String role,
    required String userName,
  }) async {
    await _storage.write(key: 'access_token', value: access);
    await _storage.write(key: 'refresh_token', value: refresh);
    await _storage.write(key: 'user_role', value: role);
    await _storage.write(key: 'user_name', value: userName);
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  static Future<void> clearAuthData() async {
    await _storage.deleteAll();
  }

  // Login Request
  static Future<Map<String, dynamic>> login(
    String phone,
    String password,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'password': password}),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      await saveAuthData(
        access: data['access'],
        refresh: data['refresh'],
        role: data['role'],
        userName: data['user_name'],
      );
      return data;
    } else {
      throw Exception(data['error'] ?? 'Login failed');
    }
  }

  static Future<Map<String, dynamic>> fetchUserProfile() async {
    final token = await getAccessToken();
    if (token == null) throw Exception('No authentication token found');

    final res = await http.get(
      Uri.parse('$baseUrl/profile/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data['profile'];
    } else {
      throw Exception(data['error'] ?? 'Failed to fetch profile');
    }
  }

  // 1. Request Password Reset OTP (POST /auth/forgot-password/)
  static Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to send reset code');
    }
  }

  // 2. Confirm Reset with OTP & New Password (POST /auth/reset-password-confirm/)
  static Future<Map<String, dynamic>> confirmPasswordReset({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/reset-password-confirm/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'otp': otp,
        'new_password': newPassword,
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to reset password');
    }
  }

  // 1. Update Profile (PUT /profile/)
  static Future<Map<String, dynamic>> updateUserProfile(
    Map<String, dynamic> data,
  ) async {
    final token = await getAccessToken();
    final res = await http.put(
      Uri.parse('$baseUrl/profile/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    final resData = jsonDecode(res.body);
    if (res.statusCode == 200 && resData['success'] == true) {
      return resData;
    } else {
      throw Exception(resData['error'] ?? 'Failed to update profile');
    }
  }

  // 2. Change Password (POST /profile/change-password/)
  static Future<Map<String, dynamic>> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    final token = await getAccessToken();
    final res = await http.post(
      Uri.parse('$baseUrl/profile/change-password/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'old_password': oldPassword,
        'new_password': newPassword,
      }),
    );
    final resData = jsonDecode(res.body);
    if (res.statusCode == 200 && resData['success'] == true) {
      return resData;
    } else {
      throw Exception(resData['error'] ?? 'Failed to change password');
    }
  }

  // 3. Fetch Nominee (GET /profile/nominee/)
  static Future<Map<String, dynamic>?> fetchNominee() async {
    final token = await getAccessToken();
    final res = await http.get(
      Uri.parse('$baseUrl/profile/nominee/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final resData = jsonDecode(res.body);
    if (res.statusCode == 200 && resData['success'] == true) {
      return resData['nominee'];
    } else {
      throw Exception(resData['error'] ?? 'Failed to load nominee details');
    }
  }

  // 4. Save/Update Nominee (POST /profile/nominee/)
  static Future<Map<String, dynamic>> saveNominee(
    Map<String, dynamic> data,
  ) async {
    final token = await getAccessToken();
    final res = await http.post(
      Uri.parse('$baseUrl/profile/nominee/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    final resData = jsonDecode(res.body);
    if (res.statusCode == 200 && resData['success'] == true) {
      return resData;
    } else {
      throw Exception(resData['error'] ?? 'Failed to save nominee details');
    }
  }
}
