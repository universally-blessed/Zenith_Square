import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _keyToken = 'jwt_token';
  static const String _keyAdmin = 'admin_profile';

  // Save session upon successful login
  static Future<void> saveSession(
    String token,
    Map<String, dynamic> adminData,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyAdmin, jsonEncode(adminData));
  }

  // Retrieve stored token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  // Retrieve stored admin profile
  static Future<Map<String, dynamic>?> getAdminProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyAdmin);
    if (data != null) {
      return jsonDecode(data);
    }
    return null;
  }

  // Check if session is active
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Clear session on logout
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyAdmin);
  }
}
