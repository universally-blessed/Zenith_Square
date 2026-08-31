import 'dart:convert';
import 'package:http/http.dart' as http;
import './api_service.dart';

class FacilitiesApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api/facilities';

  // 1. Fetch All Amenities
  static Future<List<dynamic>> fetchAmenities() async {
    final token = await ApiService.getAccessToken();
    final res = await http.get(
      Uri.parse('$baseUrl/amenities/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data['amenities'] ?? [];
    } else {
      throw Exception(data['error'] ?? 'Failed to load amenities');
    }
  }

  // 2. Fetch All Bookings to calculate occupied slots
  static Future<List<dynamic>> fetchAmenityBookings(String amenityId) async {
    final token = await ApiService.getAccessToken();
    final res = await http.get(
      Uri.parse('$baseUrl/amenities/bookings/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      final List all = data['bookings'] ?? [];
      return all.where((b) {
        final status = (b['status'] ?? '').toString().toLowerCase();
        final isExpired = b['is_payment_expired'] == true;
        final matchesAmenity =
            b['amenity_id'].toString() == amenityId.toString();

        // Count as taken if confirmed OR in an active pending payment hold
        final isOccupied =
            (status == 'confirmed' ||
                status == 'pending_payment' ||
                status == 'pending') &&
            !isExpired;
        return matchesAmenity && isOccupied;
      }).toList();
    }
    return [];
  }

  // 7. Confirm / Approve Amenity Booking Payment (POST /api/facilities/amenities/bookings/<id>/confirm-payment/)
  static Future<Map<String, dynamic>> confirmBookingPayment(
    String bookingId, {
    String? paymentId,
  }) async {
    final token = await ApiService.getAccessToken();
    final res = await http.post(
      Uri.parse('$baseUrl/amenities/bookings/$bookingId/confirm-payment/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'payment_id': paymentId ?? ''}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to confirm booking payment');
    }
  }

  // 8. Cancel Amenity Booking (PATCH /api/facilities/amenities/bookings/<id>/cancel/)
  static Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    final token = await ApiService.getAccessToken();
    final res = await http.patch(
      Uri.parse('$baseUrl/amenities/bookings/$bookingId/cancel/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to cancel booking');
    }
  }

  // 3. Fetch Logged-in Resident's Bookings
  static Future<List<dynamic>> fetchMyBookings() async {
    final token = await ApiService.getAccessToken();
    final res = await http.get(
      Uri.parse('$baseUrl/amenities/bookings/?my=true'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data['bookings'] ?? [];
    } else {
      throw Exception(data['error'] ?? 'Failed to load my bookings');
    }
  }

  // 4. Fetch Society-wide Bookings for Chairman (GET /api/facilities/amenities/bookings/)
  static Future<List<dynamic>> fetchSocietyBookings() async {
    final token = await ApiService.getAccessToken();
    final res = await http.get(
      Uri.parse('$baseUrl/amenities/bookings/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data['bookings'] ?? [];
    } else {
      throw Exception(data['error'] ?? 'Failed to load society bookings');
    }
  }

  // 4. Book Amenity
  static Future<Map<String, dynamic>> bookAmenity({
    required String amenityId,
    required String bookingDate,
    required String startTime,
    required String endTime,
  }) async {
    final token = await ApiService.getAccessToken();
    final res = await http.post(
      Uri.parse('$baseUrl/amenities/book/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'amenity_id': amenityId,
        'booking_date': bookingDate,
        'start_time': startTime,
        'end_time': endTime,
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Booking failed');
    }
  }

  // 9. Fetch Society Assets (GET /api/facilities/assets/)
  static Future<List<dynamic>> fetchAssets() async {
    final token = await ApiService.getAccessToken();
    final res = await http.get(
      Uri.parse('$baseUrl/assets/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data['assets'] ?? [];
    } else {
      throw Exception(data['error'] ?? 'Failed to load society assets');
    }
  }

  // 10. Register Asset (POST /api/facilities/assets/)
  static Future<Map<String, dynamic>> createAsset({
    required String name,
    required String type,
    required String location,
    required String purchaseDate,
  }) async {
    final token = await ApiService.getAccessToken();
    final res = await http.post(
      Uri.parse('$baseUrl/assets/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'asset_name': name,
        'asset_type': type,
        'asset_location': location,
        'purchase_date': purchaseDate,
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to register asset');
    }
  }

  // 11. Fetch Asset Maintenance Logs (GET /api/facilities/assets/<asset_id>/maintenance/)
  static Future<List<dynamic>> fetchAssetMaintenance(String assetId) async {
    final token = await ApiService.getAccessToken();
    final res = await http.get(
      Uri.parse('$baseUrl/assets/$assetId/maintenance/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data['maintenance_logs'] ?? [];
    } else {
      throw Exception(data['error'] ?? 'Failed to load maintenance logs');
    }
  }

  // 12. Record Asset Maintenance (POST /api/facilities/assets/<asset_id>/maintenance/)
  static Future<Map<String, dynamic>> recordAssetMaintenance({
    required String assetId,
    required String description,
    required String maintenanceDate,
    required double cost,
  }) async {
    final token = await ApiService.getAccessToken();
    final res = await http.post(
      Uri.parse('$baseUrl/assets/$assetId/maintenance/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'description': description,
        'maintenance_date': maintenanceDate,
        'maintenance_cost': cost,
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to record maintenance log');
    }
  }

  // 2. Create New Amenity (POST /api/facilities/amenities/)
  static Future<Map<String, dynamic>> createAmenity({
    required String name,
    required String location,
    required int capacity,
    String status = 'available',
  }) async {
    final token = await ApiService.getAccessToken();
    final res = await http.post(
      Uri.parse('$baseUrl/amenities/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'amenity_name': name,
        'amenity_location': location,
        'amenity_capacity': capacity,
        'amenity_status': status,
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to create amenity');
    }
  }

  // Fetch Vehicles (GET /api/facilities/vehicles/ or /api/facilities/vehicles/?all=true)
  static Future<List<dynamic>> fetchVehicles({bool allSociety = false}) async {
    final token = await ApiService.getAccessToken();
    final url = allSociety
        ? '$baseUrl/vehicles/?all=true'
        : '$baseUrl/vehicles/';
    final res = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data['vehicles'] ?? [];
    } else {
      throw Exception(data['error'] ?? 'Failed to load vehicles');
    }
  }

  // 2. Register a New Vehicle (POST /api/facilities/vehicles/)
  static Future<Map<String, dynamic>> registerVehicle({
    required String vehicleNumber,
    required String vehicleType,
    required String allotmentNumber,
  }) async {
    final token = await ApiService.getAccessToken();
    final res = await http.post(
      Uri.parse('$baseUrl/vehicles/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'vehicle_number': vehicleNumber,
        'vehicle_type': vehicleType,
        'vehicle_allotment_number': allotmentNumber,
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to register vehicle');
    }
  }

  // 3. Remove a Vehicle (DELETE /api/facilities/vehicles/<vehicle_id>/)
  static Future<Map<String, dynamic>> deleteVehicle(String vehicleId) async {
    final token = await ApiService.getAccessToken();
    final res = await http.delete(
      Uri.parse('$baseUrl/vehicles/$vehicleId/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to remove vehicle');
    }
  }

  // Update Amenity Status (PATCH /api/facilities/amenities/<id>/status/)
  static Future<Map<String, dynamic>> updateAmenityStatus(
    String amenityId,
    String newStatus,
  ) async {
    final token = await ApiService.getAccessToken();
    final res = await http.patch(
      Uri.parse('$baseUrl/amenities/$amenityId/status/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'amenity_status': newStatus}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to update status');
    }
  }

  // Remove Asset (DELETE /api/facilities/assets/<asset_id>/)
  static Future<Map<String, dynamic>> deleteAsset(String assetId) async {
    final token = await ApiService.getAccessToken();
    final res = await http.delete(
      Uri.parse('$baseUrl/assets/$assetId/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to remove asset');
    }
  }
}
