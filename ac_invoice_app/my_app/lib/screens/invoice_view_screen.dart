import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

import '../models/client.dart';
import '../models/company_settings.dart';
import '../models/invoice.dart';
import '../services/pdf_service.dart';
import '../services/reminder_service.dart';
import '../services/storage_service.dart';
import 'invoice_form_screen.dart';

class InvoiceViewScreen extends StatefulWidget {
  final String invoiceId;
  const InvoiceViewScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceViewScreen> createState() => _InvoiceViewScreenState();
}

class _InvoiceViewScreenState extends State<InvoiceViewScreen> {
  Invoice? _invoice;
  Client? _client;
  CompanySettings? _settings;
  Uint8List? _pdfBytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final invoices = await StorageService.instance.getInvoices();
    final invoice = invoices.firstWhere((i) => i.id == widget.invoiceId);
    final clients = await StorageService.instance.getClients();
    Client? client;
    for (final c in clients) {
      if (c.id == invoice.clientId) client = c;
    }
    final settings = await StorageService.instance.getSettings();

    client ??= Client(id: 'unknown', name: 'Unknown Client');

    final bytes = await PdfService.buildInvoicePdf(
      invoice: invoice,
      client: client,
      settings: settings,
    );

    setState(() {
      _invoice = invoice;
      _client = client;
      _settings = settings;
      _pdfBytes = bytes;
      _loading = false;
    });
  }

  Future<void> _share() async {
    if (_pdfBytes == null || _invoice == null) return;
    await Printing.sharePdf(bytes: _pdfBytes!, filename: '${_invoice!.invoiceNo}.pdf');
  }

  Future<void> _download() async {
    if (_pdfBytes == null || _invoice == null) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory('${dir.path}/Invoices');
      if (!await folder.exists()) await folder.create(recursive: true);
      final file = File('${folder.path}/${_invoice!.invoiceNo}.pdf');
      await file.writeAsBytes(_pdfBytes!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved: ${file.path}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save file: $e')),
      );
    }
  }

  Future<void> _remind() async {
    if (_invoice == null || _client == null || _settings == null) return;
    await ReminderService.remind(
      context: context,
      client: _client!,
      invoice: _invoice!,
      settings: _settings!,
      onReminded: _load,
    );
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete invoice?'),
        content: Text('This will permanently delete invoice ${_invoice?.invoiceNo ?? ''}.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      await StorageService.instance.deleteInvoice(widget.invoiceId);
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _pdfBytes == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.black)));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_invoice!.invoiceNo),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => InvoiceFormScreen(existing: _invoice)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: _delete,
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => _pdfBytes!,
        allowPrinting: true,
        allowSharing: false,
        canChangeOrientation: false,
        canChangePageFormat: false,
        actions: const [],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_invoice!.balanceAmount > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _remind,
                      icon: const Icon(Icons.notifications_active_outlined),
                      label: Text(
                        'Remind Client \u2014 Balance Due Rs. ${_invoice!.balanceAmount.toStringAsFixed(0)}',
                      ),
                    ),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _download,
                      icon: const Icon(Icons.download),
                      label: const Text('Download'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _share,
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
