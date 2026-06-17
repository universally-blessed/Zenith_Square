// =========================================================================
// 🏢 PUBLIC UTILITY DATA LOOKUPS
// =========================================================================
// Handles unauthenticated society and block relational map requests used
// during registration dropdown builds. This file isolates structural query
// properties, preventing them from mixing with active session logic blocks.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_base.dart';

class SocietyApiService {
  /// Yields registered society identities for user signup lookups
  static Future<List<dynamic>> fetchPublicSocieties() async {
    final url = Uri.parse('${ApiBase.baseUrl}/public/societies/');
    final response = await http.get(url);
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  /// Pulls relational blocks linked to the chosen parent society
  static Future<List<dynamic>> fetchPublicBlocks(String societyId) async {
    final url = Uri.parse(
      '${ApiBase.baseUrl}/public/societies/$societyId/blocks/',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }
  // =========================================================================
  // 📊 EXECUTIVE MANAGEMENT AUDITS & METRICS (CHAIRMAN ONLY)
  // =========================================================================

  /// Pulls high-level society analytics summaries (e.g., total active occupants,
  /// billing deficits, open grievances) to populate dashboard metrics graphs.
  static Future<Map<String, dynamic>> fetchSocietyReportMetrics(
    String token,
  ) async {
    final url = Uri.parse('${ApiBase.baseUrl}/chairman/reports/summary/');
    try {
      final response = await http.get(
        url,
        headers: ApiBase.getHeaders(token: token, isJson: true),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = jsonDecode(response.body);
        return {'success': true, 'metrics': decodedData};
      }
      return {
        'success': false,
        'error': 'Failed to compile analytical society report data vectors.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Network communication loopback interface failure: $e',
      };
    }
  }
  // =========================================================================
  // 👥 MEMBER DIRECTORIES & INTRALINK COMMUNICATIONS (CHAIRMAN ONLY)
  // =========================================================================

  /// Pulls the complete society roster breakdown (Owners and Tenants) from Django tables
  static Future<List<dynamic>> fetchGlobalResidentsDirectory(
    String token,
  ) async {
    final url = Uri.parse('${ApiBase.baseUrl}/chairman/directory/residents/');
    try {
      final response = await http.get(
        url,
        headers: ApiBase.getHeaders(token: token, isJson: false),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Dispatches a direct text payload back to a targeted flat row entry
  static Future<bool> sendDirectResidentMessage({
    required String token,
    required String residentId,
    required String messageText,
  }) async {
    final url = Uri.parse('${ApiBase.baseUrl}/chairman/directory/message/');
    try {
      final response = await http.post(
        url,
        headers: ApiBase.getHeaders(token: token, isJson: true),
        body: jsonEncode({
          'recipient_id': residentId,
          'message_body': messageText,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  /// Pulls individual chat history between the Chairman and a specific resident node
  static Future<List<dynamic>> fetchChatRoomPayload(
    String token,
    String residentId,
  ) async {
    final url = Uri.parse(
      '${ApiBase.baseUrl}/chairman/directory/messages/$residentId/',
    );
    try {
      final response = await http.get(
        url,
        headers: ApiBase.getHeaders(token: token, isJson: false),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
