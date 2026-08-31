import 'dart:convert';
import 'package:http/http.dart' as http;
import './api_service.dart';

class HelpdeskApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api/helpdesk';

  // 1. Fetch Complaints List (GET /api/complaints/)
  static Future<List<dynamic>> fetchComplaints() async {
    final token = await ApiService.getAccessToken();
    final res = await http.get(
      Uri.parse('$baseUrl/complaints/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data['complaints'] ?? [];
    } else {
      throw Exception(data['error'] ?? 'Failed to load complaints');
    }
  }

  // 2. File Complaint (POST /api/complaints/)
  static Future<Map<String, dynamic>> fileComplaint({
    required String title,
    required String description,
  }) async {
    final token = await ApiService.getAccessToken();
    final res = await http.post(
      Uri.parse('$baseUrl/complaints/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'title': title, 'description': description}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to register complaint');
    }
  }

  // 3. Submit Feedback (POST /api/feedback/)
  static Future<Map<String, dynamic>> submitFeedback({
    required String feedbackText,
    int? rating,
  }) async {
    final token = await ApiService.getAccessToken();
    final res = await http.post(
      Uri.parse('$baseUrl/feedback/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'feedback_text': feedbackText, 'rating': rating}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to submit feedback');
    }
  }

  // 3. Update Complaint Status (PATCH /api/helpdesk/complaints/<id>/status/)
  static Future<Map<String, dynamic>> updateComplaintStatus(
    String complaintId,
    String newStatus,
  ) async {
    final token = await ApiService.getAccessToken();
    final res = await http.patch(
      Uri.parse('$baseUrl/complaints/$complaintId/status/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': newStatus}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to update complaint status');
    }
  }

  // 4. Fetch Society Feedbacks (GET /api/helpdesk/feedback/)
  static Future<List<dynamic>> fetchFeedbacks() async {
    final token = await ApiService.getAccessToken();
    final res = await http.get(
      Uri.parse('$baseUrl/feedback/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data['feedbacks'] ?? [];
    } else {
      throw Exception(data['error'] ?? 'Failed to load feedbacks');
    }
  }
}
