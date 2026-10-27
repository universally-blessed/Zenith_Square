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

  static Future<Map<String, dynamic>> fetchExecutiveReport() async {
    final token = await ApiService.getAccessToken();
    final res = await http.get(
      Uri.parse('$baseUrl/executive-report/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        return data;
      } else {
        throw Exception(data['error'] ?? 'Failed to load financial report');
      }
    } else {
      try {
        final data = jsonDecode(res.body);
        throw Exception(data['error'] ?? 'Server returned error (${res.statusCode})');
      } catch (_) {
        throw Exception('Server error (${res.statusCode}). Please try again.');
      }
    }
  }

  // 7. Society Income (GET /api/finance/income/)
  static Future<List<dynamic>> fetchSocietyIncome() async {
    final token = await ApiService.getAccessToken();
    final res = await http.get(
      Uri.parse('$baseUrl/income/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data['incomes'] ?? [];
    } else {
      throw Exception(data['error'] ?? 'Failed to load society income');
    }
  }

  // 8. Chairman: Record Society Income (POST /api/finance/income/)
  static Future<Map<String, dynamic>> recordSocietyIncome({
    required String incomeType,
    required double amount,
    required String receivedDate,
    String? description,
  }) async {
    final token = await ApiService.getAccessToken();
    final res = await http.post(
      Uri.parse('$baseUrl/income/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'income_type': incomeType,
        'amount': amount,
        'received_date': receivedDate,
        'description': description ?? '',
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to record income');
    }
  }

<<<<<<< HEAD
=======
<<<<<<< HEAD
  static Future<Map<String, dynamic>> fetchBlockReport() async {
    final token = await ApiService.getAccessToken();
    final res = await http.get(
      Uri.parse('$baseUrl/block-report/'),
=======
>>>>>>> backup-work
  // 9. Treasurer & Chairman: Fetch All Maintenance Bills
  static Future<List<dynamic>> fetchAllBills() async {
    final token = await ApiService.getAccessToken();
    final res = await http.get(
      Uri.parse('$baseUrl/bills/all/'),
<<<<<<< HEAD
=======
>>>>>>> 86843ea (completed the treasure and security pannel)
>>>>>>> backup-work
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
<<<<<<< HEAD
=======
<<<<<<< HEAD
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to load block report');
=======
>>>>>>> backup-work
      return data['bills'] ?? [];
    } else {
      throw Exception(data['error'] ?? 'Failed to load maintenance bills');
    }
  }

  // 10. Generate Monthly Bills for All Flats
  static Future<Map<String, dynamic>> generateBills({
    String? billMonth,
    String? dueDate,
  }) async {
    final token = await ApiService.getAccessToken();
    final res = await http.post(
      Uri.parse('$baseUrl/bills/generate/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        if (billMonth != null) 'bill_month': billMonth,
        if (dueDate != null) 'due_date': dueDate,
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to generate bills');
    }
  }

  // 11. Record Offline Payment (Cash / Cheque / Bank Transfer)
  static Future<Map<String, dynamic>> recordOfflinePayment({
    required String billId,
    required String paymentMethod,
  }) async {
    final token = await ApiService.getAccessToken();
    final res = await http.post(
      Uri.parse('$baseUrl/payment/offline/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'bill_id': billId,
        'payment_method': paymentMethod,
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to record offline payment');
    }
  }

  // 12. Fetch All Society Payment Receipts
  static Future<List<dynamic>> fetchAllReceipts() async {
    final token = await ApiService.getAccessToken();
    final res = await http.get(
      Uri.parse('$baseUrl/receipts/all/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data['receipts'] ?? [];
    } else {
      throw Exception(data['error'] ?? 'Failed to load receipts');
    }
  }

  // 13. Fetch Society Bank Details
  static Future<Map<String, dynamic>> fetchBankDetails() async {
    final token = await ApiService.getAccessToken();
    final res = await http.get(
      Uri.parse('$baseUrl/bank-details/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data['bank_details'] ?? {};
    } else {
      throw Exception(data['error'] ?? 'Failed to load bank details');
<<<<<<< HEAD
=======
>>>>>>> 86843ea (completed the treasure and security pannel)
>>>>>>> backup-work
    }
  }
}

