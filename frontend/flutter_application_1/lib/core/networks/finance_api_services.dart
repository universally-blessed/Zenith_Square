// =========================================================================
// 💳 FINANCIAL TRANSPARENCY & BILLING MANAGEMENT
// =========================================================================
// Manages outstanding individual maintenance bills, payment gateway updates,
// cross-verified digital histories, and total public expense outflows
// broadcasted to support fiscal transparency requirements.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_base.dart';

class FinanceApiService {
  static const String _maintenanceDomain = '${ApiBase.baseUrl}/maintenance';

  /// Resolves pending personal maintenance invoice rows
  static Future<Map<String, dynamic>> fetchCurrentBill(String token) async {
    final url = Uri.parse('$_maintenanceDomain/current/');
    final response = await http.get(
      url,
      headers: ApiBase.getHeaders(token: token, isJson: false),
    );
    return jsonDecode(response.body);
  }

  /// Processes active billing parameters inside secure gateway steps
  static Future<bool> processBillPayment(String token, String billId) async {
    final url = Uri.parse('$_maintenanceDomain/pay/');
    final response = await http.post(
      url,
      headers: ApiBase.getHeaders(token: token, isJson: true),
    );
    return response.statusCode == 200;
  }

  /// Compiles public expenses data vectors from PostgreSQL structures
  static Future<List<dynamic>> fetchSocietyExpenses(String token) async {
    final url = Uri.parse('${ApiBase.baseUrl}/expenses/');
    try {
      final response = await http.get(
        url,
        headers: ApiBase.getHeaders(token: token, isJson: true),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Server rejected request status: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Network communication breakdown: $e');
    }
  }

  /// Pulls personal settled digital transaction receipts logs
  static Future<List<dynamic>> fetchPaymentHistory(String token) async {
    final url = Uri.parse('${ApiBase.baseUrl}/payments/history/');
    final response = await http.get(
      url,
      headers: ApiBase.getHeaders(token: token, isJson: true),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }
  // =========================================================================
  // 💳 SOCIETY RECONCILIATION & AUDIT HOOKS (CHAIRMAN CONTROL)
  // =========================================================================

  /// Pulls the dynamic verified stream of all inbound society payments
  /// (Online transactions and validated offline checks) across all wings.
  static Future<List<dynamic>> fetchGlobalInboundLedger(String token) async {
    final url = Uri.parse('${ApiBase.baseUrl}/payments/global-audit/');
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
