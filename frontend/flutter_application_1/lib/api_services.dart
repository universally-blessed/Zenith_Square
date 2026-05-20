import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Production Tip: If testing on the Android Emulator, use 'http://10.0.2.2:8000/api'
  // If testing on an iOS Simulator or web browser, use 'http://127.0.0.1:8000/api'
  static const String baseUrl = 'http://127.0.1.1:8000/api';

  /// Dispatches fields directly to Django View controllers
  static Future<Map<String, dynamic>> login(
    String phone,
    String password,
  ) async {
    final url = Uri.parse('$baseUrl/auth/login/');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_phone': phone, 'password': password}),
      );

      final decodedResponse = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': decodedResponse};
      } else {
        return {
          'success': false,
          'error': decodedResponse['error'] ?? 'Authentication failed.',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection timeout: $e'};
    }
  }

  /// Concurrently hits your Django dual-table registration script
  static Future<Map<String, dynamic>> registerResident({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String flatId,
  }) async {
    final url = Uri.parse('$baseUrl/auth/register/');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_name': name,
          'user_phone': phone,
          'user_email': email,
          'password': password,
          'flat_id': flatId,
          'society_id': 'SO01', // Fallback master ID
        }),
      );

      final decodedResponse = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': decodedResponse};
      } else {
        return {
          'success': false,
          'error': decodedResponse['error'] ?? 'Registration failed.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to communicate with back-end pipeline: $e',
      };
    }
  }
}
