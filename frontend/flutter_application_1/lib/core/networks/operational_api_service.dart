// =========================================================================
// ⚙️ SOCIETY SYSTEM CORES & BROADCAST INFRASTRUCTURE
// =========================================================================
// Consolidates all core day-to-day society functions: Amenities reservations,
// grievance tracking pipelines, board meeting notices, consultative polling
// records, lost item bulletins, emergency SOS triggers, and personal contact indexes.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_base.dart';

class OperationalApiService {
  // -------------------------------------------------------------------------
  // 🚗 VEHICLE FLEET RECKONERS
  // -------------------------------------------------------------------------
  static Future<List<dynamic>> fetchVehicles(String token) async {
    final url = Uri.parse('${ApiBase.baseUrl}/vehicles/');
    final response = await http.get(
      url,
      headers: ApiBase.getHeaders(token: token),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load registered fleet parameters.');
  }

  static Future<bool> addVehicle(String token, Map<String, String> data) async {
    final url = Uri.parse('${ApiBase.baseUrl}/vehicles/');
    final response = await http.post(
      url,
      headers: ApiBase.getHeaders(token: token),
      body: jsonEncode({
        'vehicle_number': data['number'],
        'vehicle_type': data['type'],
        'vehicle_allotment_number': data['spot'],
      }),
    );
    return response.statusCode == 201;
  }

  static Future<bool> deleteVehicle(String token, int databaseId) async {
    final url = Uri.parse('${ApiBase.baseUrl}/vehicles/$databaseId/');
    final response = await http.delete(
      url,
      headers: ApiBase.getHeaders(token: token, isJson: false),
    );
    return response.statusCode == 200;
  }

  // -------------------------------------------------------------------------
  // 🛠️ GRIEVANCE & COMPLAINTS WORKFLOWS
  // -------------------------------------------------------------------------
  static Future<List<dynamic>> fetchComplaints(String token) async {
    final url = Uri.parse('${ApiBase.baseUrl}/complaints/');
    final response = await http.get(
      url,
      headers: ApiBase.getHeaders(token: token, isJson: false),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  static Future<bool> submitComplaint(
    String token,
    String title,
    String description,
  ) async {
    final url = Uri.parse('${ApiBase.baseUrl}/complaints/');
    try {
      final response = await http.post(
        url,
        headers: ApiBase.getHeaders(token: token),
        body: jsonEncode({'title': title, 'description': description}),
      );
      return response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  static Future<List<dynamic>> fetchGlobalComplaints(String token) async {
    final url = Uri.parse('${ApiBase.baseUrl}/complaints/');
    try {
      final response = await http.get(
        url,
        headers: ApiBase.getHeaders(token: token, isJson: false),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<bool> updateComplaintStatus(
    String token,
    String complaintId,
    String statusText,
  ) async {
    final url = Uri.parse('${ApiBase.baseUrl}/complaints/$complaintId/update/');
    try {
      final response = await http.put(
        url,
        headers: ApiBase.getHeaders(token: token),
        body: jsonEncode({'status': statusText}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // -------------------------------------------------------------------------
  // 📅 AMENITY RESERVATIONS LIFECYCLE
  // -------------------------------------------------------------------------
  static Future<List<dynamic>> fetchLiveReservations(String token) async {
    final url = Uri.parse('${ApiBase.baseUrl}/bookings/');
    try {
      final response = await http.get(
        url,
        headers: ApiBase.getHeaders(token: token),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> submitBookingRequest({
    required String token,
    required String amenityName,
    required String bookingDate,
    required String slotTime,
  }) async {
    final url = Uri.parse('${ApiBase.baseUrl}/bookings/');
    try {
      final response = await http.post(
        url,
        headers: ApiBase.getHeaders(token: token),
        body: jsonEncode({
          'amenity_name': amenityName,
          'booking_date': bookingDate,
          'slots': slotTime,
        }),
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': decoded['message'] ?? 'Booking confirmed!',
        };
      } else {
        return {
          'success': false,
          'error': decoded['error'] ?? 'Slot window conflicted.',
        };
      }
    } catch (_) {
      return {'success': false, 'error': 'Server validation offline.'};
    }
  }

  // -------------------------------------------------------------------------
  // 📊 CONSULTATIVE POLL TILES
  // -------------------------------------------------------------------------
  static Future<List<dynamic>> fetchActivePolls(String token) async {
    final url = Uri.parse('${ApiBase.baseUrl}/polls/active/');
    final response = await http.get(
      url,
      headers: ApiBase.getHeaders(token: token, isJson: false),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  static Future<bool> submitVote(
    String token,
    String pollId,
    String optionId,
  ) async {
    final url = Uri.parse('${ApiBase.baseUrl}/polls/vote/');
    final response = await http.post(
      url,
      headers: ApiBase.getHeaders(token: token),
      body: jsonEncode({'poll_id': pollId, 'option_id': optionId}),
    );
    return response.statusCode == 201;
  }

  // -------------------------------------------------------------------------
  // 🔍 BULLETINS, MEETINGS & NOTICES ALERTS
  // -------------------------------------------------------------------------
  static Future<List<dynamic>> fetchLostFoundItems(String token) async {
    final url = Uri.parse('${ApiBase.baseUrl}/lost-found/');
    final response = await http.get(
      url,
      headers: ApiBase.getHeaders(token: token, isJson: false),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  static Future<bool> postLostFoundReport(
    String token,
    Map<String, String> data,
  ) async {
    final url = Uri.parse('${ApiBase.baseUrl}/lost-found/');
    final response = await http.post(
      url,
      headers: ApiBase.getHeaders(token: token),
      body: jsonEncode({
        'item_name': data['item_name'],
        'item_description': data['item_description'],
        'item_location': data['item_location'],
        'item_status': data['item_status'],
      }),
    );
    return response.statusCode == 201;
  }

  static Future<List<dynamic>> fetchNotices(String token) async {
    final url = Uri.parse('${ApiBase.baseUrl}/broadcasts/notices/');
    final response = await http.get(
      url,
      headers: ApiBase.getHeaders(token: token, isJson: false),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  static Future<List<dynamic>> fetchMeetings(String token) async {
    final url = Uri.parse('${ApiBase.baseUrl}/broadcasts/meetings/');
    final response = await http.get(
      url,
      headers: ApiBase.getHeaders(token: token, isJson: false),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  static Future<bool> createSocietyMeeting(
    String token,
    Map<String, dynamic> payload,
  ) async {
    final url = Uri.parse('${ApiBase.baseUrl}/broadcasts/meetings/create/');
    try {
      final response = await http.post(
        url,
        headers: ApiBase.getHeaders(token: token),
        body: jsonEncode(payload),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> updateMeetingMinutes(
    String token,
    String meetingId,
    String momText,
  ) async {
    final url = Uri.parse(
      '${ApiBase.baseUrl}/broadcasts/meetings/$meetingId/mom/',
    );
    try {
      final response = await http.put(
        url,
        headers: ApiBase.getHeaders(token: token),
        body: jsonEncode({'mom': momText}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> createSocietyNotice(
    String token,
    String title,
    String description,
  ) async {
    final url = Uri.parse('${ApiBase.baseUrl}/broadcasts/notices/create/');
    try {
      final response = await http.post(
        url,
        headers: ApiBase.getHeaders(token: token),
        body: jsonEncode({'title': title, 'description': description}),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteSocietyNotice(
    String token,
    dynamic noticeId,
  ) async {
    final url = Uri.parse(
      '${ApiBase.baseUrl}/broadcasts/notices/$noticeId/delete/',
    );
    try {
      final response = await http.delete(
        url,
        headers: ApiBase.getHeaders(token: token, isJson: false),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  // -------------------------------------------------------------------------
  // 👤 RECONCILED PROFILE & DIRECTORY ENTRIES
  // -------------------------------------------------------------------------
  static Future<Map<String, dynamic>> fetchDashboardMeta(String token) async {
    final url = Uri.parse('${ApiBase.baseUrl}/resident/dashboard-meta/');
    try {
      final response = await http.get(
        url,
        headers: ApiBase.getHeaders(token: token),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'error': 'Failed to resolve layout details.'};
    } catch (e) {
      return {'success': false, 'error': 'Network timeout: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateProfileData(
    String token,
    String phone,
    String email,
  ) async {
    final url = Uri.parse('${ApiBase.baseUrl}/resident/update-profile/');
    try {
      final response = await http.post(
        url,
        headers: ApiBase.getHeaders(token: token),
        body: jsonEncode({'user_phone': phone, 'user_email': email}),
      );
      final decoded = jsonDecode(response.body);
      return response.statusCode == 200
          ? {'success': true}
          : {
              'success': false,
              'error': decoded['error'] ?? 'Profile modification rejected.',
            };
    } catch (e) {
      return {'success': false, 'error': 'Network pipeline failure: $e'};
    }
  }

  static Future<Map<String, dynamic>> fetchNomineeDetails(String token) async {
    final url = Uri.parse('${ApiBase.baseUrl}/resident/nominee/');
    final response = await http.get(
      url,
      headers: ApiBase.getHeaders(token: token, isJson: false),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return {'no_nominee': true};
  }

  static Future<bool> saveNomineeDetails(
    String token,
    Map<String, String> payload,
  ) async {
    final url = Uri.parse('${ApiBase.baseUrl}/resident/nominee/');
    final response = await http.post(
      url,
      headers: ApiBase.getHeaders(token: token),
      body: jsonEncode(payload),
    );
    return response.statusCode == 200;
  }

  // -------------------------------------------------------------------------
  // 🚨 SECURITY PANIC BROADCAST SYSTEM
  // -------------------------------------------------------------------------
  static Future<bool> triggerEmergencySOS(String token) async {
    final url = Uri.parse('${ApiBase.baseUrl}/security/sos/');
    try {
      final response = await http.post(
        url,
        headers: ApiBase.getHeaders(token: token, isJson: false),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // =========================================================================
  // ⚖️ EXECUTIVE WORKFLOW PIPELINES (CHAIRMAN ONLY)
  // =========================================================================

  /// Pulls all committee proposals and budget reallocation ledger rows currently pending review
  static Future<List<dynamic>> fetchExecutiveDecisions(String token) async {
    final url = Uri.parse('${ApiBase.baseUrl}/chairman/proposals/pending/');
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

  /// Commits an executive mutation choice status (Approved or Rejected) for a target proposal row
  static Future<bool> updateDecisionApprovalStatus(
    String token,
    String requestId,
    String statusText,
  ) async {
    final url = Uri.parse(
      '${ApiBase.baseUrl}/chairman/proposals/$requestId/action/',
    );
    try {
      final response = await http.post(
        url,
        headers: ApiBase.getHeaders(token: token, isJson: true),
        body: jsonEncode({'action_status': statusText}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
  // =========================================================================
  // 🏢 HARDWARE ASSETS & INVENTORY (CHAIRMAN ONLY)
  // =========================================================================

  /// Pulls the complete inventory collection of hardware assets installed in the society framework
  static Future<List<dynamic>> fetchSocietyAssets(String token) async {
    final url = Uri.parse('${ApiBase.baseUrl}/chairman/assets/');
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

  /// Logs a newly validated physical hardware asset entry into the registry backend
  static Future<bool> addSocietyAsset(
    String token,
    Map<String, String> payload,
  ) async {
    final url = Uri.parse('${ApiBase.baseUrl}/chairman/assets/');
    try {
      final response = await http.post(
        url,
        headers: ApiBase.getHeaders(token: token, isJson: true),
        body: jsonEncode({
          'name': payload['name'],
          'location': payload['location'],
          'status': payload['status'],
        }),
      );
      return response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  /// Cycles or updates the specific health status variable of a managed hardware asset
  static Future<bool> changeAssetStatus(
    String token,
    dynamic assetId,
    String targetStatus,
  ) async {
    final url = Uri.parse(
      '${ApiBase.baseUrl}/chairman/assets/$assetId/status/',
    );
    try {
      final response = await http.put(
        url,
        headers: ApiBase.getHeaders(token: token, isJson: true),
        body: jsonEncode({'status': targetStatus}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Deletes a physical asset permanently from the PostgreSQL database registry map
  static Future<bool> purgeAssetRecord(String token, dynamic assetId) async {
    final url = Uri.parse('${ApiBase.baseUrl}/chairman/assets/$assetId/');
    try {
      final response = await http.delete(
        url,
        headers: ApiBase.getHeaders(token: token, isJson: false),
      );
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Pulls the historical audit trail of all security panic alerts and
  /// system-wide emergency broadcasts from the database
  static Future<List<dynamic>> fetchEmergencyLogHistory(String token) async {
    final url = Uri.parse('${ApiBase.baseUrl}/security/logs/');
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

  // =========================================================================
  // 🏛️ COMMITTEE MANAGEMENT & CLEARANCE (FEATURE 18)
  // =========================================================================

  /// Pulls the current society committee roster and pending clearance requests
  static Future<Map<String, dynamic>> fetchCommitteeData(String token) async {
    final url = Uri.parse('${ApiBase.baseUrl}/chairman/committee/');
    try {
      final response = await http.get(
        url,
        headers: ApiBase.getHeaders(token: token),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'members': [], 'requests': []};
    } catch (_) {
      return {'members': [], 'requests': []};
    }
  }

  static Future<List<dynamic>> fetchPublicSocieties() async {
    final url = Uri.parse('${ApiBase.baseUrl}/public/societies/');
    final response = await http.get(url);
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  static Future<List<dynamic>> fetchPublicBlocks(String societyId) async {
    final url = Uri.parse(
      '${ApiBase.baseUrl}/public/societies/$societyId/blocks/',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }
}
