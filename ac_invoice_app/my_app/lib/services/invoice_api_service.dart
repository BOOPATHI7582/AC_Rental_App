import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/client.dart';
import '../models/invoice.dart';
import 'auth_service.dart';

/// Backs invoices up to our own backend (server/README.md). Local storage
/// (StorageService) remains the source of truth for offline use — every
/// call here is best-effort and silently no-ops if the user isn't logged
/// in, so the app keeps working locally with or without the server.
class InvoiceApiService {
  static Future<Map<String, String>?> _authHeaders() async {
    final token = await AuthService.instance.currentToken();
    if (token == null || token.isEmpty) return null;
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// [client] is optional but strongly recommended: it's snapshotted onto
  /// the invoice document so an Admin can see full client details for any
  /// user's invoice without needing that user's local client list.
  static Future<void> saveInvoice(Invoice invoice, {Client? client}) async {
    try {
      final headers = await _authHeaders();
      if (headers == null) return; // not logged in - skip cloud sync

      final doc = invoice.toJson();
      doc.remove('id');
      if (client != null) {
        doc['clientName'] = client.name;
        doc['clientPhone'] = client.phone;
        doc['clientGstin'] = client.gstin;
        doc['clientAddress'] = client.address;
        doc['clientState'] = client.state;
      }

      await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/invoices/${invoice.id}'),
        headers: headers,
        body: jsonEncode(doc),
      );
    } catch (_) {
      // Best-effort cloud sync — local save already succeeded, so ignore.
    }
  }

  static Future<void> deleteInvoice(String invoiceId) async {
    try {
      final headers = await _authHeaders();
      if (headers == null) return;

      await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/invoices/$invoiceId'),
        headers: headers,
      );
    } catch (_) {
      // Ignore — local delete already succeeded.
    }
  }

  /// Pulls every invoice belonging to the logged-in user from the server.
  /// Returns an empty list if not logged in, server unreachable, or on error.
  static Future<List<Invoice>> fetchInvoices() async {
    try {
      final headers = await _authHeaders();
      if (headers == null) return [];

      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/invoices'),
        headers: headers,
      );
      if (res.statusCode != 200) return [];

      final docs = jsonDecode(res.body) as List<dynamic>;
      return docs.map((d) => Invoice.fromJson(d as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}
