import 'dart:convert';
import 'package:http/http.dart' as http;
import './api_service.dart';

class SecurityApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api/security';

  // 1. Broadcast SOS Alert (POST /security/trigger-emergency/)
  static Future<Map<String, dynamic>> triggerEmergencyAlert({
    required String alertType,
    required String description,
  }) async {
    final token = await ApiService.getAccessToken();
    final res = await http.post(
      Uri.parse('$baseUrl/trigger-emergency/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'alert_type': alertType, 'description': description}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to broadcast emergency alert');
    }
  }

  // 2. Fetch Active Emergency Alerts (GET /security/alerts/)
  static Future<List<dynamic>> fetchActiveSecurityAlerts() async {
    final token = await ApiService.getAccessToken();
    final res = await http.get(
      Uri.parse('$baseUrl/alerts/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data['alerts'] ?? [];
    } else {
      throw Exception(data['error'] ?? 'Failed to load security alerts');
    }
  }

  // 3. Fetch Flat Visitor Logs (GET /security/visitors/logs/)
  static Future<List<dynamic>> fetchVisitorLogs() async {
    final token = await ApiService.getAccessToken();
    final res = await http.get(
      Uri.parse('$baseUrl/visitors/logs/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data['logs'] ?? [];
    } else {
      throw Exception(data['error'] ?? 'Failed to load visitor logs');
    }
  }

  // 3. Dismiss / Resolve Emergency Alert (PATCH /security/alerts/<id>/dismiss/)
  static Future<Map<String, dynamic>> dismissSecurityAlert(
    String alertId,
  ) async {
    final token = await ApiService.getAccessToken();
    final res = await http.patch(
      Uri.parse('$baseUrl/alerts/$alertId/dismiss/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to dismiss security alert');
    }
  }
}
