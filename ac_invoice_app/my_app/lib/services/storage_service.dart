import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/client.dart';
import '../models/company_settings.dart';
import '../models/invoice.dart';
import 'invoice_api_service.dart';

/// Simple JSON-over-SharedPreferences storage. Keeps clients, invoices and
/// company settings persisted locally on the device.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  static const _clientsKey = 'ac_invoice_clients';
  static const _invoicesKey = 'ac_invoice_invoices';
  static const _settingsKey = 'ac_invoice_settings';

  // ---------------- Clients ----------------

  Future<List<Client>> getClients() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_clientsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Client.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveClients(List<Client> clients) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(clients.map((c) => c.toJson()).toList());
    await prefs.setString(_clientsKey, raw);
  }

  Future<void> upsertClient(Client client) async {
    final clients = await getClients();
    final idx = clients.indexWhere((c) => c.id == client.id);
    if (idx >= 0) {
      clients[idx] = client;
    } else {
      clients.add(client);
    }
    await saveClients(clients);
  }

  Future<void> deleteClient(String clientId) async {
    final clients = await getClients();
    clients.removeWhere((c) => c.id == clientId);
    await saveClients(clients);
  }

  // ---------------- Invoices ----------------

  Future<List<Invoice>> getInvoices() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_invoicesKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Invoice.fromJson(e as Map<String, dynamic>)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> saveInvoices(List<Invoice> invoices) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(invoices.map((i) => i.toJson()).toList());
    await prefs.setString(_invoicesKey, raw);
  }

  /// Wipes the local invoice cache. Call this on logout so a different
  /// account logging in on the same device never sees the previous user's
  /// invoices before their own cloud sync completes.
  Future<void> clearLocalInvoices() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_invoicesKey);
  }

  Future<void> upsertInvoice(Invoice invoice) async {
    final invoices = await getInvoices();
    final idx = invoices.indexWhere((i) => i.id == invoice.id);
    if (idx >= 0) {
      invoices[idx] = invoice;
    } else {
      invoices.add(invoice);
    }
    await saveInvoices(invoices);

    // Fire-and-forget cloud backup - app stays fully usable offline/without
    // the server configured either way. Includes a client snapshot so an
    // Admin can view full invoice details without needing this user's
    // local client list.
    Client? client;
    final clients = await getClients();
    for (final c in clients) {
      if (c.id == invoice.clientId) {
        client = c;
        break;
      }
    }
    unawaited(InvoiceApiService.saveInvoice(invoice, client: client));
  }

  Future<void> deleteInvoice(String invoiceId) async {
    final invoices = await getInvoices();
    invoices.removeWhere((i) => i.id == invoiceId);
    await saveInvoices(invoices);
    unawaited(InvoiceApiService.deleteInvoice(invoiceId));
  }

  /// Pulls the user's invoices from MongoDB Atlas and merges them into local
  /// storage (cloud copy wins on conflict). Safe to call even when
  /// MongoDB isn't configured - it will just do nothing.
  Future<int> syncInvoicesFromCloud() async {
    final remote = await InvoiceApiService.fetchInvoices();
    if (remote.isEmpty) return 0;
    final local = await getInvoices();
    final byId = {for (final i in local) i.id: i};
    for (final r in remote) {
      byId[r.id] = r;
    }
    await saveInvoices(byId.values.toList());
    return remote.length;
  }

  // ---------------- Company settings ----------------

  Future<CompanySettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_settingsKey);
    if (raw == null || raw.isEmpty) return CompanySettings();
    return CompanySettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveSettings(CompanySettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  /// Copies a picked image file into the app's documents directory so it
  /// persists across app restarts, returning the new local path.
  Future<String> persistImage(File pickedFile, String fileNamePrefix) async {
    final dir = await getApplicationDocumentsDirectory();
    final ext = pickedFile.path.split('.').last;
    final destPath =
        '${dir.path}/${fileNamePrefix}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final saved = await pickedFile.copy(destPath);
    return saved.path;
  }

  /// Writes raw image bytes (e.g. a drawn signature) to a PNG file in the
  /// app's documents directory, returning the new local path.
  Future<String> persistImageBytes(List<int> bytes, String fileNamePrefix) async {
    final dir = await getApplicationDocumentsDirectory();
    final destPath = '${dir.path}/${fileNamePrefix}_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File(destPath);
    await file.writeAsBytes(bytes);
    return file.path;
  }
}
