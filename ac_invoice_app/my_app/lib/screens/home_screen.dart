import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/client.dart';
import '../models/company_settings.dart';
import '../models/invoice.dart';
import '../services/reminder_service.dart';
import '../services/storage_service.dart';
import 'invoice_form_screen.dart';
import 'invoice_view_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Invoice> _invoices = [];
  Map<String, Client> _clientsById = {};
  CompanySettings _settings = CompanySettings();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final invoices = await StorageService.instance.getInvoices();
    final clients = await StorageService.instance.getClients();
    final settings = await StorageService.instance.getSettings();
    setState(() {
      _invoices = invoices;
      _clientsById = {for (final c in clients) c.id: c};
      _settings = settings;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalBilled = _invoices.fold(0.0, (s, i) => s + i.totalAmount);
    final totalReceived = _invoices.fold(0.0, (s, i) => s + i.receivedAmount);
    final totalPending = totalBilled - totalReceived;

    return Scaffold(
      appBar: AppBar(title: const Text('AC Rental Invoices')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InvoiceFormScreen()),
          );
          _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('New Invoice'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : RefreshIndicator(
              onRefresh: _load,
              color: Colors.black,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _statsRow(totalBilled, totalReceived, totalPending),
                  const SizedBox(height: 12),
                  if (_invoices.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: Center(
                        child: Text(
                          'No invoices yet.\nTap "New Invoice" to create your first bill.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    )
                  else
                    ..._invoices.map(_invoiceTile),
                ],
              ),
            ),
    );
  }

  Widget _statsRow(double billed, double received, double pending) {
    Widget stat(String label, double value) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black26),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                Text('Rs. ${NumberFormat('#,##,##0').format(value)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ),
          ),
        );
    return Row(
      children: [
        stat('Total Billed', billed),
        const SizedBox(width: 8),
        stat('Received', received),
        const SizedBox(width: 8),
        stat('Pending', pending),
      ],
    );
  }

  Widget _invoiceTile(Invoice inv) {
    final client = _clientsById[inv.clientId];
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(inv.invoiceNo, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${client?.name ?? 'Unknown client'} • ${DateFormat('dd-MM-yyyy').format(inv.date)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (inv.balanceAmount > 0 && client != null)
              IconButton(
                icon: const Icon(Icons.notifications_active_outlined, color: Colors.black87),
                tooltip: 'Remind client to pay',
                onPressed: () => ReminderService.remind(
                  context: context,
                  client: client,
                  invoice: inv,
                  settings: _settings,
                  onReminded: _load,
                ),
              ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Rs. ${inv.totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  inv.balanceAmount > 0 ? 'Due Rs. ${inv.balanceAmount.toStringAsFixed(0)}' : 'Paid',
                  style: TextStyle(
                    fontSize: 11,
                    color: inv.balanceAmount > 0 ? Colors.black : Colors.black54,
                    fontWeight: inv.balanceAmount > 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (inv.lastReminderAt != null)
                  Text(
                    'Reminded ${DateFormat('dd-MM-yy').format(inv.lastReminderAt!)}',
                    style: const TextStyle(fontSize: 10, color: Colors.black45),
                  ),
              ],
            ),
          ],
        ),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => InvoiceViewScreen(invoiceId: inv.id)),
          );
          _load();
        },
      ),
    );
  }
}
