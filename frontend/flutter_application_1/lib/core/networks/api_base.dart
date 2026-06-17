// =========================================================================
// 🌐 NETWORK BASICS & HEADER UTILITIES
// =========================================================================
// Houses the global loopback proxy configuration, server environments, and
// automated Token handshake header compilation tools. All domain-specific
// endpoints inherit structural behaviors natively from this parent base.

import 'package:http/http.dart' as http;

class ApiBase {
  // Production Tip: If testing on the Android Emulator, use 'http://10.0.2.2:8000/api'
  // If testing on an iOS Simulator or web browser, use 'http://127.0.0.1:8000/api'
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  /// Compiles uniform application JSON parameters and secure Token authorization handshakes
  static Map<String, String> getHeaders({String? token, bool isJson = true}) {
    final Map<String, String> headers = {};
    if (isJson) headers['Content-Type'] = 'application/json';
    if (token != null) headers['Authorization'] = 'Token $token';
    return headers;
  }
}
