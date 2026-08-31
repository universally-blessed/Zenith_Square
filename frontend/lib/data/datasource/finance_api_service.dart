import 'dart:convert';
import 'package:http/http.dart' as http;
import './api_service.dart';

class FinanceApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api/finance';

  static Future<Map<String, dynamic>> fetchLatestBill() async {
    final token = await ApiService.getAccessToken();
    final res = await http.get(
      Uri.parse('$baseUrl/bill/latest/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to load maintenance bill');
    }
  }

  // 2. Pay Bill (POST /api/finance/bill/pay/)
  static Future<Map<String, dynamic>> payBill(
    String billId, {
    String method = 'ONLINE',
  }) async {
    final token = await ApiService.getAccessToken();
    final res = await http.post(
      Uri.parse('$baseUrl/bill/pay/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'bill_id': billId, 'payment_method': method}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Payment processing failed');
    }
  }

  // 3. Payment History (GET /api/finance/payment/history/)
  static Future<List<dynamic>> fetchPaymentHistory() async {
    final token = await ApiService.getAccessToken();
    final res = await http.get(
      Uri.parse('$baseUrl/payment/history/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data['history'] ?? [];
    } else {
      throw Exception(data['error'] ?? 'Failed to load payment history');
    }
  }

  // 4. Society Expenses (GET /api/finance/expenses/)
  static Future<List<dynamic>> fetchSocietyExpenses() async {
    final token = await ApiService.getAccessToken();
    final res = await http.get(
      Uri.parse('$baseUrl/expenses/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data['expenses'] ?? [];
    } else {
      throw Exception(data['error'] ?? 'Failed to load society expenses');
    }
  }

  // 5. Chairman: Financial Summary Overview
  static Future<Map<String, dynamic>> fetchFinancialSummary() async {
    final token = await ApiService.getAccessToken();
    final res = await http.get(
      Uri.parse('$baseUrl/summary/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to load financial summary');
    }
  }

  // 6. Chairman: Record Society Expense
  static Future<Map<String, dynamic>> recordSocietyExpense({
    required String expenseType,
    required double amount,
    required String paymentDate,
    String? description,
  }) async {
    final token = await ApiService.getAccessToken();
    final res = await http.post(
      Uri.parse('$baseUrl/expenses/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'expense_type': expenseType,
        'amount': amount,
        'payment_date': paymentDate,
        'description': description ?? '',
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to record expense');
    }
  }
}
