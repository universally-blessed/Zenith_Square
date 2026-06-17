// =========================================================================
// 🔐 AUTHENTICATION & IDENTITY GATEWAYS
// =========================================================================
// Manages the unauthenticated entry gateways, profiles initialization,
// account trace lookups, 4-digit security token confirmations, and cross-role
// password updates traveling downstream to verification clusters.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_base.dart';

class AuthApiService {
  static const String _domain = '${ApiBase.baseUrl}/auth';

  /// Dispatches phone credentials to Django view authentication models
  static Future<Map<String, dynamic>> login(
    String phone,
    String password,
  ) async {
    final url = Uri.parse('$_domain/login/');
    try {
      final response = await http.post(
        url,
        headers: ApiBase.getHeaders(isJson: true),
        body: jsonEncode({'user_phone': phone, 'password': password}),
      );

      final Map<String, dynamic> decodedResponse = jsonDecode(response.body);

      if (response.statusCode == 200 && decodedResponse['success'] == true) {
        return decodedResponse;
      } else {
        return {
          'success': false,
          'error': decodedResponse['error'] ?? 'Authentication rejected.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network connection interface failure: $e',
      };
    }
  }

  /// Concurrently hits your Django dual-table registration script
  static Future<Map<String, dynamic>> registerResident({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String flatId,
    String? societyId,
  }) async {
    final url = Uri.parse('$_domain/register/');
    try {
      final response = await http.post(
        url,
        headers: ApiBase.getHeaders(isJson: true),
        body: jsonEncode({
          'user_name': name,
          'user_phone': phone,
          'user_email': email,
          'password': password,
          'flat_id': flatId,
          'society_id': societyId ?? 'SO01',
        }),
      );

      final Map<String, dynamic> decodedResponse = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
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

  /// Dispatches a recovery helper token sequence to password reset pipelines
  static Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    final url = Uri.parse('$_domain/forgot-password/');
    try {
      final response = await http.post(
        url,
        headers: ApiBase.getHeaders(isJson: true),
        body: jsonEncode({'email': email}),
      );

      final Map<String, dynamic> decodedResponse = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': decodedResponse['message']};
      } else {
        return {
          'success': false,
          'error':
              decodedResponse['error'] ?? 'Email tracking validation failed.',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Server communication failure: $e'};
    }
  }

  /// Submits the 4-digit code to verify and activate an account profile
  static Future<Map<String, dynamic>> verifyRegistrationOTP(
    String email,
    String otpCode,
  ) async {
    final url = Uri.parse('$_domain/verify-otp/');
    try {
      final response = await http.post(
        url,
        headers: ApiBase.getHeaders(isJson: true),
        body: jsonEncode({'email': email, 'otp': otpCode}),
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': decoded['message']};
      } else {
        return {
          'success': false,
          'error': decoded['error'] ?? 'OTP verification rejected.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network pipeline connection failure: $e',
      };
    }
  }

  /// Mutates account parameters matching strict database column rules
  static Future<Map<String, dynamic>> updatePassword(
    String token,
    String oldPassword,
    String newPassword,
  ) async {
    final url = Uri.parse('$_domain/change-password/');
    try {
      final response = await http.post(
        url,
        headers: ApiBase.getHeaders(token: token, isJson: true),
        body: jsonEncode({
          'old_password': oldPassword,
          'new_password': newPassword,
        }),
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {
          'success': false,
          'error': decoded['error'] ?? 'Failed to alter account password.',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Communication error: $e'};
    }
  }
}
