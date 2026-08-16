import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class AdminUser {
  final String id;
  final String name;
  final String phone;
  final String email;
  String role;
  final DateTime? createdAt;

  AdminUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.role,
    this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> j) => AdminUser(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
        email: j['email'] as String? ?? '',
        role: j['role'] as String? ?? 'user',
        createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt'] as String) : null,
      );
}

class AdminInvoiceItem {
  final String itemName;
  final String unit;
  final double quantity;
  final double price;
  final double igstPercent;

  AdminInvoiceItem({
    required this.itemName,
    required this.unit,
    required this.quantity,
    required this.price,
    required this.igstPercent,
  });

  double get taxableAmount => quantity * price;
  double get igstAmount => taxableAmount * igstPercent / 100;
  double get totalAmount => taxableAmount + igstAmount;

  factory AdminInvoiceItem.fromJson(Map<String, dynamic> j) => AdminInvoiceItem(
        itemName: j['itemName'] as String? ?? '',
        unit: j['unit'] as String? ?? '',
        quantity: (j['quantity'] as num?)?.toDouble() ?? 0,
        price: (j['price'] as num?)?.toDouble() ?? 0,
        igstPercent: (j['igstPercent'] as num?)?.toDouble() ?? 0,
      );
}

/// Full detail for one invoice as seen by an admin - includes the client
/// snapshot and every line item, so the admin can open and read any user's
/// invoice without needing that user's local client list.
class AdminInvoiceDetail {
  final String invoiceNo;
  final DateTime? date;
  final DateTime? rentalStartDate;
  final DateTime? rentalEndDate;
  final double receivedAmount;
  final String notes;
  final String? createdByName;
  final String? createdByEmail;

  final String clientName;
  final String clientPhone;
  final String clientGstin;
  final String clientAddress;
  final String clientState;

  final List<AdminInvoiceItem> items;

  AdminInvoiceDetail({
    required this.invoiceNo,
    required this.date,
    required this.receivedAmount,
    required this.items,
    this.rentalStartDate,
    this.rentalEndDate,
    this.notes = '',
    this.createdByName,
    this.createdByEmail,
    this.clientName = '',
    this.clientPhone = '',
    this.clientGstin = '',
    this.clientAddress = '',
    this.clientState = '',
  });

  double get subTotal => items.fold(0.0, (s, i) => s + i.taxableAmount);
  double get igstTotal => items.fold(0.0, (s, i) => s + i.igstAmount);
  double get total => subTotal + igstTotal;
  double get balance => total - receivedAmount;

  factory AdminInvoiceDetail.fromJson(Map<String, dynamic> j) {
    final items = (j['items'] as List<dynamic>? ?? [])
        .map((d) => AdminInvoiceItem.fromJson(d as Map<String, dynamic>))
        .toList();
    return AdminInvoiceDetail(
      invoiceNo: j['invoiceNo'] as String? ?? '',
      date: j['date'] != null ? DateTime.tryParse(j['date'] as String) : null,
      rentalStartDate: j['rentalStartDate'] != null ? DateTime.tryParse(j['rentalStartDate'] as String) : null,
      rentalEndDate: j['rentalEndDate'] != null ? DateTime.tryParse(j['rentalEndDate'] as String) : null,
      receivedAmount: (j['receivedAmount'] as num?)?.toDouble() ?? 0,
      notes: j['notes'] as String? ?? '',
      createdByName: j['createdByName'] as String?,
      createdByEmail: j['createdByEmail'] as String?,
      clientName: j['clientName'] as String? ?? '',
      clientPhone: j['clientPhone'] as String? ?? '',
      clientGstin: j['clientGstin'] as String? ?? '',
      clientAddress: j['clientAddress'] as String? ?? '',
      clientState: j['clientState'] as String? ?? '',
      items: items,
    );
  }
}

class AdminApiService {
  static Future<Map<String, String>?> _authHeaders() async {
    final token = await AuthService.instance.currentToken();
    if (token == null || token.isEmpty) return null;
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }

  static Future<List<AdminUser>> fetchUsers() async {
    final headers = await _authHeaders();
    if (headers == null) return [];
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/admin/users'), headers: headers);
    if (res.statusCode != 200) return [];
    final docs = jsonDecode(res.body) as List<dynamic>;
    return docs.map((d) => AdminUser.fromJson(d as Map<String, dynamic>)).toList();
  }

  /// All invoices across all users (full detail), sorted newest-first by
  /// the server.
  static Future<List<AdminInvoiceDetail>> fetchAllInvoices() async {
    final headers = await _authHeaders();
    if (headers == null) return [];
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/admin/invoices'), headers: headers);
    if (res.statusCode != 200) return [];
    final docs = jsonDecode(res.body) as List<dynamic>;
    return docs.map((d) => AdminInvoiceDetail.fromJson(d as Map<String, dynamic>)).toList();
  }

  /// Promotes or demotes a user. Returns null on success, or an error message.
  static Future<String?> setUserRole(String userId, String role) async {
    final headers = await _authHeaders();
    if (headers == null) return 'Not logged in';
    final res = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/users/$userId/role'),
      headers: headers,
      body: jsonEncode({'role': role}),
    );
    if (res.statusCode == 200) return null;
    try {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['error'] as String? ?? 'Could not update role (${res.statusCode})';
    } catch (_) {
      return 'Could not update role (${res.statusCode})';
    }
  }

  /// Deletes a user (and their invoices). Returns null on success, or an error message.
  static Future<String?> deleteUser(String userId) async {
    final headers = await _authHeaders();
    if (headers == null) return 'Not logged in';
    final res = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/users/$userId'),
      headers: headers,
    );
    if (res.statusCode == 200) return null;
    try {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['error'] as String? ?? 'Could not delete user (${res.statusCode})';
    } catch (_) {
      return 'Could not delete user (${res.statusCode})';
    }
  }
}
