import 'dart:convert';
import 'package:http/http.dart' as http;
import './api_service.dart';

class CommunicationApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api/communication';

  // Fetch Notices (GET /api/notices/)
  static Future<List<dynamic>> fetchNotices() async {
    final token = await ApiService.getAccessToken();
    final res = await http.get(
      Uri.parse('$baseUrl/notices/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data['notices'] ?? [];
    } else {
      throw Exception(data['error'] ?? 'Failed to load notices');
    }
  }

  // 2. Publish Notice (POST /api/communication/notices/)
  static Future<Map<String, dynamic>> publishNotice({
    required String title,
    required String description,
    String priority = 'normal',
    String? blockId,
  }) async {
    final token = await ApiService.getAccessToken();
    final res = await http.post(
      Uri.parse('$baseUrl/notices/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': title,
        'description': description,
        'priority': priority,
        'block_id': blockId,
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to publish notice');
    }
  }

  // 3. Delete/Archive Notice (DELETE /api/communication/notices/<id>/)
  static Future<Map<String, dynamic>> deleteNotice(String noticeId) async {
    final token = await ApiService.getAccessToken();
    final res = await http.delete(
      Uri.parse('$baseUrl/notices/$noticeId/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to delete notice');
    }
  }
}
