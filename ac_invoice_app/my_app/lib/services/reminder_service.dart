import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/client.dart';
import '../models/company_settings.dart';
import '../models/invoice.dart';
import 'storage_service.dart';

/// Builds and displays a "please pay the pending balance" reminder entirely
/// inside the app (dialog + copy-to-clipboard). Nothing is sent externally -
/// this is meant for on-device use while developing/running on a laptop.
class ReminderService {
  static String buildMessage({
    required Client client,
    required Invoice invoice,
    required CompanySettings settings,
  }) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ');
    return 'Dear ${client.name},\n\n'
        'This is a reminder that Invoice ${invoice.invoiceNo} dated '
        '${DateFormat('dd-MM-yyyy').format(invoice.date)} has a pending balance of '
        '${currency.format(invoice.balanceAmount)} out of the total '
        '${currency.format(invoice.totalAmount)}.\n\n'
        'Kindly arrange the payment at your earliest convenience.\n\n'
        'Thank you,\n${settings.companyName}\n${settings.phone}';
  }

  /// Shows the reminder message in a dialog. On "Copy & Mark Reminded" it
  /// copies the text to the clipboard and stamps the invoice with the
  /// current time so the list can show "Reminded on ...".
  static Future<void> remind({
    required BuildContext context,
    required Client client,
    required Invoice invoice,
    required CompanySettings settings,
    VoidCallback? onReminded,
  }) async {
    final message = buildMessage(client: client, invoice: invoice, settings: settings);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Payment Reminder'),
        content: SingleChildScrollView(
          child: Text(message, style: const TextStyle(fontSize: 13)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: message));
              invoice.lastReminderAt = DateTime.now();
              await StorageService.instance.upsertInvoice(invoice);
              if (ctx.mounted) Navigator.pop(ctx);
              onReminded?.call();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reminder text copied \u2014 paste it wherever you like')),
                );
              }
            },
            child: const Text('Copy & Mark Reminded'),
          ),
        ],
      ),
    );
  }
}
