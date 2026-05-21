import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Production Tip: If testing on the Android Emulator, use 'http://10.0.2.2:8000/api'
  // If testing on an iOS Simulator or web browser, use 'http://127.0.0.1:8000/api'
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  // ==========================================
  // 🔐 1. AUTHENTICATION & IDENTITY GATEWAYS
  // ==========================================

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

  static Future<Map<String, dynamic>> fetchDashboardMeta(String token) async {
    final url = Uri.parse('$baseUrl/resident/dashboard-meta/');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'error': 'Failed to resolve layout details.'};
    } catch (e) {
      return {'success': false, 'error': 'Network timeout: $e'};
    }
  }

  // ==========================================
  // 🏢 2. PUBLIC UTILITY LOOKUPS
  // ==========================================

  static Future<List<dynamic>> fetchPublicSocieties() async {
    final url = Uri.parse('$baseUrl/public/societies/');
    final response = await http.get(url);
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  static Future<List<dynamic>> fetchPublicBlocks(String societyId) async {
    final url = Uri.parse('$baseUrl/public/societies/$societyId/blocks/');
    final response = await http.get(url);
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  // ==========================================
  // 🚗 3. VEHICLE CRUD SERVICE HANDLERS
  // ==========================================

  static Future<List<dynamic>> fetchVehicles(String token) async {
    final url = Uri.parse('$baseUrl/vehicles/');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load registered fleet parameters.');
  }

  static Future<bool> addVehicle(String token, Map<String, String> data) async {
    final url = Uri.parse('$baseUrl/vehicles/');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: jsonEncode({
        'vehicle_number': data['number'],
        'vehicle_type': data['type'],
        'vehicle_allotment_number': data['spot'],
      }),
    );
    return response.statusCode == 201;
  }

  static Future<bool> deleteVehicle(String token, int databaseId) async {
    final url = Uri.parse('$baseUrl/vehicles/$databaseId/');
    final response = await http.delete(
      url,
      headers: {'Authorization': 'Token $token'},
    );
    return response.statusCode == 200;
  }

  // ==========================================
  // 🛠️ 4. COMPLAINTS SERVICE HANDLERS
  // ==========================================

  static Future<List<dynamic>> fetchComplaints(String token) async {
    final url = Uri.parse('$baseUrl/complaints/');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Token $token'},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  static Future<bool> submitComplaint(
    String token,
    String title,
    String description,
  ) async {
    final url = Uri.parse('$baseUrl/complaints/');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({'title': title, 'description': description}),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // ==========================================
  // 📅 5. AMENITY RESERVATIONS TIMED LIFECYCLE
  // ==========================================

  /// Pulls the complete list of amenity reservations for the active resident profile
  static Future<List<dynamic>> fetchAmenityBookings(String token) async {
    final url = Uri.parse('$baseUrl/bookings/');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Token $token', // Handshake authorization header pass
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      throw Exception('Failed to resolve reservation ledger vectors: $e');
    }
  }

  /// Dispatches a fresh booking payload to check conflict constraints and log requests
  static Future<bool> submitBookingRequest(
    String token,
    Map<String, dynamic> payload,
  ) async {
    final url = Uri.parse('$baseUrl/bookings/');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({
          'amenity_name': payload['amenity_name'],
          'booking_date': payload['booking_date'],
          'slots': payload['slots'], // Transmits format: '04:00 PM - 07:00 PM'
        }),
      );

      // Dynamic validation handling backend success codes cleanly
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ==========================================
  // 💳 6. FINANCIAL & MAINTENANCE HANDLERS
  // ==========================================

  static Future<Map<String, dynamic>> fetchCurrentBill(String token) async {
    final url = Uri.parse('$baseUrl/maintenance/current/');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Token $token'},
    );
    return jsonDecode(response.body);
  }

  static Future<bool> processBillPayment(String token, String billId) async {
    final url = Uri.parse('$baseUrl/maintenance/pay/');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: jsonEncode({'bill_id': billId}),
    );
    return response.statusCode == 200;
  }

  static Future<List<dynamic>> fetchSocietyExpenses(String token) async {
    final url = Uri.parse('$baseUrl/expenses/');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Server rejected request with status: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Network communication breakdown: $e');
    }
  }

  // ==========================================
  // 📊 7. CONSULTATIVE POLL LOGIC SYSTEM
  // ==========================================

  static Future<List<dynamic>> fetchActivePolls(String token) async {
    final url = Uri.parse('$baseUrl/polls/active/');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Token $token'},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  static Future<bool> submitVote(
    String token,
    String pollId,
    String optionId,
  ) async {
    final url = Uri.parse('$baseUrl/polls/vote/');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: jsonEncode({'poll_id': pollId, 'option_id': optionId}),
    );
    return response.statusCode == 201;
  }

  // ==========================================
  // 🔍 8. MISPLACED BULLETINS NOTICE BOARD
  // ==========================================

  static Future<List<dynamic>> fetchLostFoundItems(String token) async {
    final url = Uri.parse('$baseUrl/lost-found/');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Token $token'},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  static Future<bool> postLostFoundReport(
    String token,
    Map<String, String> data,
  ) async {
    final url = Uri.parse('$baseUrl/lost-found/');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
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
    final url = Uri.parse('$baseUrl/broadcasts/notices/');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Token $token'},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  static Future<List<dynamic>> fetchMeetings(String token) async {
    final url = Uri.parse('$baseUrl/broadcasts/meetings/');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Token $token'},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  static Future<List<dynamic>> fetchPaymentHistory(String token) async {
    final url = Uri.parse('$baseUrl/payments/history/');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  static Future<Map<String, dynamic>> updatePassword(
    String token,
    String oldPassword,
    String newPassword,
  ) async {
    final url = Uri.parse('$baseUrl/auth/change-password/');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
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

  // ==========================================
  // 🚨 SECURITY & EMERGENCY ALERT HANDLERS
  // ==========================================

  /// Commits a live panic trigger row inside the 'security_alerts' table
  static Future<bool> triggerEmergencySOS(String token) async {
    final url = Uri.parse('$baseUrl/security/sos/');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token', // Authorized token handshake pass
        },
      );

      // Validates database insertion status response keys
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (_) {
      return false; // Safely catches network connection timeout states
    }
  }

  static Future<Map<String, dynamic>> updateProfileData(
    String token,
    String phone,
    String email,
  ) async {
    final url = Uri.parse('$baseUrl/resident/update-profile/');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({'user_phone': phone, 'user_email': email}),
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {
          'success': false,
          'error': decoded['error'] ?? 'Profile modification rejected.',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network pipeline failure: $e'};
    }
  }

  static Future<Map<String, dynamic>> fetchNomineeDetails(String token) async {
    final url = Uri.parse('$baseUrl/resident/nominee/');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Token $token'},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return {'no_nominee': true};
  }

  static Future<bool> saveNomineeDetails(
    String token,
    Map<String, String> payload,
  ) async {
    final url = Uri.parse('$baseUrl/resident/nominee/');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: jsonEncode(payload),
    );
    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>> verifyRegistrationOTP(
    String email,
    String otpCode,
  ) async {
    final url = Uri.parse('$baseUrl/auth/verify-otp/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
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
}
