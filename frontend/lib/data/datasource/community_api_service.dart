import 'dart:convert';
import 'package:http/http.dart' as http;
import './api_service.dart';

class CommunityApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api/community';

  // 1. Fetch Society Meetings (GET /meetings/)
  static Future<List<dynamic>> fetchMeetings() async {
    final token = await ApiService.getAccessToken();
    final res = await http.get(
      Uri.parse('$baseUrl/meetings/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data['meetings'] ?? [];
    } else {
      throw Exception(data['error'] ?? 'Failed to load meetings');
    }
  }

  // 2. Schedule a New Meeting (POST /meetings/)
  static Future<Map<String, dynamic>> scheduleMeeting({
    required String title,
    required String agenda,
    required String meetingDate,
    required String startTime,
    required String location,
    String? minutesDoc,
  }) async {
    final token = await ApiService.getAccessToken();
    final res = await http.post(
      Uri.parse('$baseUrl/meetings/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': title,
        'agenda': agenda,
        'meeting_date': meetingDate,
        'start_time': startTime,
        'location': location,
        'minutes_doc': minutesDoc ?? '',
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to schedule meeting');
    }
  }

  // 3. Update Meeting Minutes / Agenda (PATCH /meetings/<id>/)
  static Future<Map<String, dynamic>> updateMeetingMinutes(
    String meetingId, {
    String? minutesDoc,
    String? agenda,
  }) async {
    final token = await ApiService.getAccessToken();
    final res = await http.patch(
      Uri.parse('$baseUrl/meetings/$meetingId/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        if (minutesDoc != null) 'minutes_doc': minutesDoc,
        if (agenda != null) 'agenda': agenda,
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to update meeting details');
    }
  }

  // 2. Fetch Active Committee Members (GET /committee/)
  static Future<List<dynamic>> fetchCommitteeMembers() async {
    final token = await ApiService.getAccessToken();
    final res = await http.get(
      Uri.parse('$baseUrl/committee/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data['committee_members'] ?? [];
    } else {
      throw Exception(data['error'] ?? 'Failed to load committee members');
    }
  }

  // 5. Fetch Role Change Requests (GET /committee/change-request/)
  static Future<List<dynamic>> fetchCommitteeChangeRequests() async {
    final token = await ApiService.getAccessToken();
    final res = await http.get(
      Uri.parse('$baseUrl/committee/change-request/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data['requests'] ?? [];
    } else {
      throw Exception(data['error'] ?? 'Failed to load change requests');
    }
  }

  // 6. Initiate Role Change Request (POST /committee/change-request/)
  static Future<Map<String, dynamic>> submitRoleChangeRequest({
    required String targetUserId,
    required String newRoleId,
  }) async {
    final token = await ApiService.getAccessToken();
    final res = await http.post(
      Uri.parse('$baseUrl/committee/change-request/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'target_user_id': targetUserId,
        'new_role_id': newRoleId,
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to submit role change request');
    }
  }

  // 7. Approve / Reject / Cancel Role Change (PATCH /committee/change-request/<id>/action/)
  static Future<Map<String, dynamic>> handleCommitteeChangeAction(
    String requestId,
    String action, // 'Approved', 'Rejected', or 'Cancelled'
  ) async {
    final token = await ApiService.getAccessToken();
    final res = await http.patch(
      Uri.parse('$baseUrl/committee/change-request/$requestId/action/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'action': action}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to process request action');
    }
  }

  // 1. Fetch Active Polls (GET /polls/active/)
  static Future<List<dynamic>> fetchActivePolls() async {
    final token = await ApiService.getAccessToken();
    final res = await http.get(
      Uri.parse('$baseUrl/polls/active/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data['polls'] ?? [];
    } else {
      throw Exception(data['error'] ?? 'Failed to load polls');
    }
  }

  // 2. Cast Vote (POST /polls/vote/)
  static Future<Map<String, dynamic>> castVote({
    required String pollId,
    required String optionId,
  }) async {
    final token = await ApiService.getAccessToken();
    final res = await http.post(
      Uri.parse('$baseUrl/polls/vote/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'poll_id': pollId, 'option_id': optionId}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to cast vote');
    }
  }

  // Fetch Lost & Found Items (GET /lost-found/)
  static Future<List<dynamic>> fetchLostFoundItems() async {
    final token = await ApiService.getAccessToken();
    final res = await http.get(
      Uri.parse('$baseUrl/lost-found/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data['items'] ?? [];
    } else {
      throw Exception(data['error'] ?? 'Failed to load lost & found items');
    }
  }

  // Delete Meeting (DELETE /api/community/meetings/<id>/delete/)
  static Future<Map<String, dynamic>> deleteMeeting(String meetingId) async {
    final token = await ApiService.getAccessToken();
    final res = await http.delete(
      Uri.parse('$baseUrl/meetings/$meetingId/delete/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to delete meeting');
    }
  }

  // Fetch Society Residents for Committee Dropdown (GET /api/community/committee/members-dropdown/)
  static Future<List<dynamic>> fetchSocietyMembersDropdown() async {
    final token = await ApiService.getAccessToken();
    final res = await http.get(
      Uri.parse('$baseUrl/committee/members-dropdown/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data['members'] ?? [];
    } else {
      throw Exception(data['error'] ?? 'Failed to load society members');
    }
  }

  // Create a New Poll (POST /api/community/polls/create/)
  static Future<Map<String, dynamic>> createPoll({
    required String title,
    required String description,
    required String endDate,
    required List<String> options,
  }) async {
    final token = await ApiService.getAccessToken();
    final res = await http.post(
      Uri.parse('$baseUrl/polls/create/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'poll_title': title,
        'poll_description': description,
        'end_date': endDate,
        'options': options,
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to create poll');
    }
  }

  // Delete Poll (DELETE /api/community/polls/<id>/delete/)
  static Future<Map<String, dynamic>> deletePoll(String pollId) async {
    final token = await ApiService.getAccessToken();
    final res = await http.delete(
      Uri.parse('$baseUrl/polls/$pollId/delete/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to delete poll');
    }
  }

  // 1. Report Lost or Found Item (POST /api/community/lost-found/)
  static Future<Map<String, dynamic>> reportLostFoundItem({
    required String itemName,
    required String itemDescription,
    required String itemStatus, // 'Lost' or 'Found'
    required String itemLocation,
  }) async {
    final token = await ApiService.getAccessToken();
    final res = await http.post(
      Uri.parse('$baseUrl/lost-found/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'item_name': itemName,
        'item_description': itemDescription,
        'item_status': itemStatus,
        'item_location': itemLocation,
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to report item');
    }
  }

  // 2. Update Resolution Status (PATCH /api/community/lost-found/<id>/claim/)
  static Future<Map<String, dynamic>> updateLostFoundStatus(
    String itemId,
    String newStatus, // 'Claimed', 'Resolved', 'Returned', 'Lost', 'Found'
  ) async {
    final token = await ApiService.getAccessToken();
    final res = await http.patch(
      Uri.parse('$baseUrl/lost-found/$itemId/claim/'),
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
      throw Exception(data['error'] ?? 'Failed to update item status');
    }
  }
}
