import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../main.dart';
import '../screens/login_screen.dart';
import 'session_manager.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api/admin';

  // Helper to build authenticated headers
  static Future<Map<String, String>> _getHeaders() async {
    final token = await SessionManager.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Central Response Interceptor
  static http.Response _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      // Clear expired token
      SessionManager.clearSession();

      // Redirect immediately to login screen
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
      throw Exception('Session expired. Please log in again.');
    }
    return response;
  }

  // 1. Admin Login
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await SessionManager.saveSession(data['token'], data['admin']);
      return data['admin'];
    } else {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Login failed');
    }
  }

  // 2. Fetch Societies
  static Future<List<dynamic>> getSocieties() async {
    final headers = await _getHeaders();
    final rawResponse = await http.get(
      Uri.parse('$baseUrl/societies/'),
      headers: headers,
    );
    final response = _handleResponse(rawResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load societies');
    }
  }

  // 3. Create Society
  // 3. Create Society with Blocks & Flats
  static Future<bool> createSociety(Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final rawResponse = await http.post(
      Uri.parse('$baseUrl/societies/'),
      headers: headers,
      body: jsonEncode(data),
    );
    final response = _handleResponse(rawResponse);

    if (response.statusCode == 201) {
      return true;
    } else {
      // Decode backend error for clear user feedback
      try {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData is Map
            ? (errorData['error'] ??
                  errorData['detail'] ??
                  errorData.values.first.toString())
            : 'Failed to create society';
        throw Exception(errorMessage);
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Server error (${response.statusCode})');
      }
    }
  }

  // Fetch Blocks for a specific society (Useful for dropdowns / filters)
  static Future<List<dynamic>> getSocietyBlocks(String societyId) async {
    final headers = await _getHeaders();
    final rawResponse = await http.get(
      Uri.parse('$baseUrl/societies/$societyId/blocks/'),
      headers: headers,
    );
    final response = _handleResponse(rawResponse);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  // 4. Fetch Users
  static Future<List<dynamic>> getUsers({
    String? societyId,
    String? roleId,
  }) async {
    final headers = await _getHeaders();
    final params = <String, String>{};
    if (societyId != null && societyId.isNotEmpty) {
      params['society_id'] = societyId;
    }
    if (roleId != null && roleId.isNotEmpty) params['role_id'] = roleId;

    final uri = Uri.parse(
      '$baseUrl/users/',
    ).replace(queryParameters: params.isEmpty ? null : params);
    final rawResponse = await http.get(uri, headers: headers);
    final response = _handleResponse(rawResponse);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load users');
  }

  // 5. Toggle User Status
  static Future<bool> toggleUserStatus(
    String userId,
    bool currentStatus,
  ) async {
    final headers = await _getHeaders();
    final rawResponse = await http.patch(
      Uri.parse('$baseUrl/users/$userId/'),
      headers: headers,
      body: jsonEncode({'is_active': !currentStatus}),
    );
    final response = _handleResponse(rawResponse);
    return response.statusCode == 200;
  }

  // 6. Fetch Committee Requests
  static Future<List<dynamic>> getCommitteeRequests() async {
    final headers = await _getHeaders();
    final rawResponse = await http.get(
      Uri.parse('$baseUrl/committee-requests/'),
      headers: headers,
    );
    final response = _handleResponse(rawResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load committee requests');
    }
  }

  // 7. Handle Committee Request (Approve/Reject)
  static Future<bool> handleCommitteeRequest(
    String requestId,
    String action,
    int adminId,
  ) async {
    final headers = await _getHeaders();
    final rawResponse = await http.post(
      Uri.parse('$baseUrl/committee-requests/$requestId/$action/'),
      headers: headers,
      body: jsonEncode({'admin_id': adminId.toString()}),
    );
    final response = _handleResponse(rawResponse);
    return response.statusCode == 200;
  }

  // 8. Fetch Reports Summary
  static Future<Map<String, dynamic>> getReportsSummary({
    String? societyId,
  }) async {
    final headers = await _getHeaders();
    String url = '$baseUrl/reports/summary/';
    if (societyId != null && societyId.isNotEmpty) {
      url += '?society_id=$societyId';
    }
    final rawResponse = await http.get(Uri.parse(url), headers: headers);
    final response = _handleResponse(rawResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load reports data');
    }
  }

  // Fetch Society Feature Configuration
  static Future<Map<String, dynamic>?> getSocietyFeatures(
    String societyId,
  ) async {
    final headers = await _getHeaders();
    final rawResponse = await http.get(
      Uri.parse('$baseUrl/society-features/?society_id=$societyId'),
      headers: headers,
    );
    final response = _handleResponse(rawResponse);

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      if (list.isNotEmpty) {
        return list.first as Map<String, dynamic>;
      }
      return null;
    } else {
      throw Exception('Failed to load society features');
    }
  }

  // Update or Create Society Feature Configuration
  static Future<bool> saveSocietyFeatures(
    Map<String, dynamic> data, {
    String? configId,
  }) async {
    final headers = await _getHeaders();
    http.Response rawResponse;

    if (configId != null) {
      rawResponse = await http.put(
        Uri.parse('$baseUrl/society-features/$configId/'),
        headers: headers,
        body: jsonEncode(data),
      );
    } else {
      rawResponse = await http.post(
        Uri.parse('$baseUrl/society-features/'),
        headers: headers,
        body: jsonEncode(data),
      );
    }

    final response = _handleResponse(rawResponse);
    return response.statusCode == 200 || response.statusCode == 201;
  }

  // Soft delete / Toggle Society Active Status
  static Future<bool> toggleSocietyStatus(String societyId) async {
    final headers = await _getHeaders();
    final rawResponse = await http.post(
      Uri.parse('$baseUrl/societies/$societyId/toggle_status/'),
      headers: headers,
    );
    final response = _handleResponse(rawResponse);
    return response.statusCode == 200;
  }

  // Fetch Admin Profile
  static Future<Map<String, dynamic>> getAdminProfile() async {
    final headers = await _getHeaders();
    final rawResponse = await http.get(
      Uri.parse('$baseUrl/profile/'),
      headers: headers,
    );
    final response = _handleResponse(rawResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load profile');
    }
  }

  // Update Admin Profile & Password
  static Future<Map<String, dynamic>> updateAdminProfile({
    required String username,
    required String email,
    String? currentPassword,
    String? newPassword,
  }) async {
    final headers = await _getHeaders();
    final rawResponse = await http.put(
      Uri.parse('$baseUrl/profile/'),
      headers: headers,
      body: jsonEncode({
        'username': username,
        'email': email,
        if (currentPassword != null && currentPassword.isNotEmpty)
          'current_password': currentPassword,
        if (newPassword != null && newPassword.isNotEmpty)
          'new_password': newPassword,
      }),
    );
    final response = _handleResponse(rawResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Update locally cached profile
      final token = await SessionManager.getToken();
      if (token != null) {
        await SessionManager.saveSession(token, data['admin']);
      }
      return data;
    } else {
      throw Exception(
        jsonDecode(response.body)['error'] ?? 'Failed to update profile',
      );
    }
  }

  // Fetch Homepage Overview Data
  static Future<Map<String, dynamic>> getOverviewDashboard() async {
    final headers = await _getHeaders();
    final rawResponse = await http.get(
      Uri.parse('$baseUrl/dashboard/overview/'),
      headers: headers,
    );
    final response = _handleResponse(rawResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load dashboard overview');
    }
  }

  // Update Society Profile & Maintenance Configurations
  static Future<bool> updateSociety(
    String societyId,
    Map<String, dynamic> data,
  ) async {
    final headers = await _getHeaders();
    final rawResponse = await http.put(
      Uri.parse('$baseUrl/societies/$societyId/'),
      headers: headers,
      body: jsonEncode(data),
    );
    final response = _handleResponse(rawResponse);
    return response.statusCode == 200;
  }

  // 2. Create New User
  static Future<bool> createUser(Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final rawResponse = await http.post(
      Uri.parse('$baseUrl/users/'),
      headers: headers,
      body: jsonEncode(data),
    );
    final response = _handleResponse(rawResponse);
    return response.statusCode == 201;
  }

  // 4. Fetch Roles
  static Future<List<dynamic>> getRoles() async {
    final headers = await _getHeaders();
    final rawResponse = await http.get(
      Uri.parse('$baseUrl/roles/'),
      headers: headers,
    );
    final response = _handleResponse(rawResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load roles');
    }
  }

  static Future<bool> createRole(String roleId, String roleName) async {
    final headers = await _getHeaders();
    final rawResponse = await http.post(
      Uri.parse('$baseUrl/roles/'),
      headers: headers,
      body: jsonEncode({'role_id': roleId, 'role_name': roleName}),
    );
    final response = _handleResponse(rawResponse);
    return response.statusCode == 201;
  }

  // 5. Unified Committee Action
  static Future<bool> handleCommitteeAction(
    String requestId,
    String actionName,
  ) async {
    final headers = await _getHeaders();
    final rawResponse = await http.post(
      Uri.parse('$baseUrl/committee-requests/$requestId/action/'),
      headers: headers,
      body: jsonEncode({'action': actionName}),
    );
    final response = _handleResponse(rawResponse);
    return response.statusCode == 200;
  }

  // Financials Endpoint: /api/admin/reports/financials/
  static Future<Map<String, dynamic>> getFinancialsReport({
    String? societyId,
    String? month,
  }) async {
    final headers = await _getHeaders();
    final params = <String, String>{};
    if (societyId != null && societyId.isNotEmpty) {
      params['society_id'] = societyId;
    }
    if (month != null && month.isNotEmpty) params['month'] = month;

    final uri = Uri.parse(
      '$baseUrl/reports/financials/',
    ).replace(queryParameters: params.isEmpty ? null : params);
    final rawResponse = await http.get(uri, headers: headers);
    final response = _handleResponse(rawResponse);
    return jsonDecode(response.body);
  }

  // Security & Complaints Endpoint: /api/admin/reports/security-complaints/
  static Future<Map<String, dynamic>> getSecurityComplaintsReport({
    String? societyId,
  }) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/reports/security-complaints/').replace(
      queryParameters: (societyId != null && societyId.isNotEmpty)
          ? {'society_id': societyId}
          : null,
    );
    final rawResponse = await http.get(uri, headers: headers);
    final response = _handleResponse(rawResponse);
    return jsonDecode(response.body);
  }

  // Operations & Visitors Endpoint: /api/admin/reports/operations/
  static Future<Map<String, dynamic>> getOperationsReport({
    String? societyId,
  }) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/reports/operations/').replace(
      queryParameters: (societyId != null && societyId.isNotEmpty)
          ? {'society_id': societyId}
          : null,
    );
    final rawResponse = await http.get(uri, headers: headers);
    final response = _handleResponse(rawResponse);
    return jsonDecode(response.body);
  }

  // Scenario 1: Super Admin assigns initial role directly
  // Scenario 1: Super Admin assigns initial role directly
  static Future<bool> assignInitialRole(String userId, String roleId) async {
    final headers = await _getHeaders();
    final rawResponse = await http.post(
      Uri.parse('$baseUrl/users/$userId/assign-initial-role/'),
      headers: headers,
      body: jsonEncode({'role_id': roleId}),
    );
    final response = _handleResponse(rawResponse);

    if (response.statusCode == 200) {
      return true;
    } else {
      // Decode and surface the exact backend message
      try {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData is Map
            ? (errorData['error'] ??
                  errorData['detail'] ??
                  errorData.values.first.toString())
            : 'Failed to assign role';
        throw Exception(errorMessage);
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Server error (${response.statusCode})');
      }
    }
  }

  // Scenario 2: Super Admin initiates a committee change (requires Chairman approval)
  static Future<bool> createCommitteeChangeRequest(
    String targetUserId,
    String newRoleId,
  ) async {
    final headers = await _getHeaders();
    final rawResponse = await http.post(
      Uri.parse('$baseUrl/committee-requests/'),
      headers: headers,
      body: jsonEncode({'target_user': targetUserId, 'new_role': newRoleId}),
    );
    final response = _handleResponse(rawResponse);
    return response.statusCode == 201;
  }

  // Fetch Occupancy Records for a specific society
  static Future<List<dynamic>> getOccupancies({String? societyId}) async {
    final headers = await _getHeaders();
    final url = societyId != null && societyId.isNotEmpty
        ? '$baseUrl/occupancies/?society_id=$societyId'
        : '$baseUrl/occupancies/';
    final rawResponse = await http.get(Uri.parse(url), headers: headers);
    final response = _handleResponse(rawResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load occupancy data');
  }

  // Update Tenant Status (Emergency Override: 'terminated', 'evicted', 'inactive')
  static Future<bool> updateTenantStatus(String tenantId, String status) async {
    final headers = await _getHeaders();
    final rawResponse = await http.patch(
      Uri.parse('$baseUrl/tenants/$tenantId/update_status/'),
      headers: headers,
      body: jsonEncode({'status': status}),
    );
    final response = _handleResponse(rawResponse);

    if (response.statusCode == 200) {
      return true;
    } else {
      try {
        final err = jsonDecode(response.body);
        throw Exception(err['error'] ?? 'Failed to update tenant status');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Server error (${response.statusCode})');
      }
    }
  }
}
