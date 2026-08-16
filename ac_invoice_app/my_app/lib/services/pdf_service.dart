import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/client.dart';
import '../models/company_settings.dart';
import '../models/invoice.dart';
import 'number_to_words.dart';

class PdfService {
  static const _thin = pw.BorderSide(width: 0.6, color: PdfColors.black);

  /// Builds the full tax invoice as a single grid: everything is laid out in
  /// table rows/columns (no floating boxes), in pure black & white.
  static Future<Uint8List> buildInvoicePdf({
    required Invoice invoice,
    required Client client,
    required CompanySettings settings,
  }) async {
    final doc = pw.Document();
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ');

    pw.MemoryImage? logo;
    if (settings.logoPath != null && File(settings.logoPath!).existsSync()) {
      logo = pw.MemoryImage(File(settings.logoPath!).readAsBytesSync());
    }
    pw.MemoryImage? signature;
    if (settings.signaturePath != null && File(settings.signaturePath!).existsSync()) {
      signature = pw.MemoryImage(File(settings.signaturePath!).readAsBytesSync());
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Center(
                child: pw.Text('TAX INVOICE',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 8),
              _headerRow(logo, settings),
              _billToAndInvoiceDetailsRow(client, invoice),
              _itemsTable(invoice, currency),
              _totalsAndBankRow(invoice, settings, currency),
              pw.SizedBox(height: 4),
              _amountInWordsRow(invoice),
              _termsAndSignatureRow(settings, signature),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  // Logo on the left, company details on the right - one bordered row.
  static pw.Widget _headerRow(pw.MemoryImage? logo, CompanySettings s) {
    return pw.Table(
      border: const pw.TableBorder(
        top: _thin, left: _thin, right: _thin, bottom: _thin,
        horizontalInside: _thin, verticalInside: _thin,
      ),
      columnWidths: const {0: pw.FlexColumnWidth(1), 1: pw.FlexColumnWidth(2)},
      children: [
        pw.TableRow(children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(6),
            alignment: pw.Alignment.center,
            height: 70,
            child: logo != null
                ? pw.Image(logo, fit: pw.BoxFit.contain)
                : pw.Text(s.companyName,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(6),
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(s.companyName,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 15)),
                if (s.tagline.isNotEmpty) pw.Text(s.tagline, style: const pw.TextStyle(fontSize: 8)),
                if (s.address.isNotEmpty)
                  pw.Text(s.address, style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right),
                if (s.phone.isNotEmpty) pw.Text('Phone: ${s.phone}', style: const pw.TextStyle(fontSize: 8)),
                if (s.email.isNotEmpty) pw.Text('Email: ${s.email}', style: const pw.TextStyle(fontSize: 8)),
                if (s.gstin.isNotEmpty)
                  pw.Text('GSTIN: ${s.gstin}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                if (s.state.isNotEmpty) pw.Text('State: ${s.state}', style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
          ),
        ]),
      ],
    );
  }

  static pw.Widget _billToAndInvoiceDetailsRow(Client c, Invoice inv) {
    final dateStr = DateFormat('dd-MM-yyyy').format(inv.date);
    return pw.Table(
      border: const pw.TableBorder(
        left: _thin, right: _thin, bottom: _thin,
        verticalInside: _thin,
      ),
      columnWidths: const {0: pw.FlexColumnWidth(1), 1: pw.FlexColumnWidth(1)},
      children: [
        pw.TableRow(children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Bill To', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                pw.Text(c.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                if (c.address.isNotEmpty) pw.Text(c.address, style: const pw.TextStyle(fontSize: 8)),
                if (c.phone.isNotEmpty) pw.Text('Mob: ${c.phone}', style: const pw.TextStyle(fontSize: 8)),
                if (c.gstin.isNotEmpty)
                  pw.Text('GSTIN: ${c.gstin}', style: const pw.TextStyle(fontSize: 8)),
                if (c.state.isNotEmpty) pw.Text('State: ${c.state}', style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Invoice Details', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                pw.Text('Invoice No: ${inv.invoiceNo}', style: const pw.TextStyle(fontSize: 8)),
                pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 8)),
                if (inv.rentalStartDate != null)
                  pw.Text(
                    'Rental Period: ${DateFormat('dd-MM-yyyy').format(inv.rentalStartDate!)}'
                    '${inv.rentalEndDate != null ? ' to ${DateFormat('dd-MM-yyyy').format(inv.rentalEndDate!)}' : ''}',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                pw.Text('Place of Supply: ${c.state}', style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
          ),
        ]),
      ],
    );
  }

  static pw.Widget _itemsTable(Invoice inv, NumberFormat currency) {
    final headers = ['#', 'Item', 'Unit', 'Qty', 'Price/Unit', 'Amount', 'IGST %', 'IGST Amt', 'Total'];
    final rows = <List<String>>[];
    for (var i = 0; i < inv.items.length; i++) {
      final it = inv.items[i];
      rows.add([
        '${i + 1}',
        it.itemName,
        it.unit,
        _fmtNum(it.quantity),
        currency.format(it.price),
        currency.format(it.taxableAmount),
        '${_fmtNum(it.igstPercent)}%',
        currency.format(it.igstAmount),
        currency.format(it.totalAmount),
      ]);
    }

    return pw.Table(
      border: const pw.TableBorder(
        left: _thin, right: _thin, bottom: _thin,
        horizontalInside: _thin, verticalInside: _thin,
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(0.5),
        1: pw.FlexColumnWidth(2.1),
        2: pw.FlexColumnWidth(0.8),
        3: pw.FlexColumnWidth(0.7),
        4: pw.FlexColumnWidth(1.2),
        5: pw.FlexColumnWidth(1.2),
        6: pw.FlexColumnWidth(0.8),
        7: pw.FlexColumnWidth(1.2),
        8: pw.FlexColumnWidth(1.3),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: headers
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(h,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
                        textAlign: pw.TextAlign.center),
                  ))
              .toList(),
        ),
        for (final r in rows)
          pw.TableRow(
            children: r
                .map((v) => pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(v, style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center),
                    ))
                .toList(),
          ),
      ],
    );
  }

  static pw.Widget _totalsAndBankRow(Invoice inv, CompanySettings s, NumberFormat currency) {
    pw.Widget kv(String k, String v, {bool bold = false}) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 1.5, horizontal: 4),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(k, style: pw.TextStyle(fontSize: 8, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
              pw.Text(v, style: pw.TextStyle(fontSize: 8, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
            ],
          ),
        );

    return pw.Table(
      border: const pw.TableBorder(
        left: _thin, right: _thin, bottom: _thin, verticalInside: _thin,
      ),
      columnWidths: const {0: pw.FlexColumnWidth(1), 1: pw.FlexColumnWidth(1)},
      children: [
        pw.TableRow(children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Bank Details', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                pw.Text('Name: ${s.bankName}', style: const pw.TextStyle(fontSize: 8)),
                if (s.bankBranch.isNotEmpty)
                  pw.Text('Branch: ${s.bankBranch}', style: const pw.TextStyle(fontSize: 8)),
                pw.Text('A/c No: ${s.accountNumber}', style: const pw.TextStyle(fontSize: 8)),
                pw.Text('IFSC: ${s.ifscCode}', style: const pw.TextStyle(fontSize: 8)),
                pw.Text('A/c Holder: ${s.accountHolderName}', style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Column(
              children: [
                kv('Sub Total', currency.format(inv.subTotal)),
                kv('IGST Total', currency.format(inv.totalIgst)),
                pw.Divider(thickness: 0.5),
                kv('Total Amount', currency.format(inv.totalAmount), bold: true),
                kv('Received', currency.format(inv.receivedAmount)),
                kv('Balance', currency.format(inv.balanceAmount), bold: true),
              ],
            ),
          ),
        ]),
      ],
    );
  }

  static pw.Widget _amountInWordsRow(Invoice inv) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(left: _thin, right: _thin, bottom: _thin),
      ),
      padding: const pw.EdgeInsets.all(6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Invoice Amount In Words', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
          pw.Text(numberToIndianWords(inv.totalAmount), style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
  }

  static pw.Widget _termsAndSignatureRow(CompanySettings s, pw.MemoryImage? signature) {
    return pw.Table(
      border: const pw.TableBorder(
        left: _thin, right: _thin, bottom: _thin, verticalInside: _thin,
      ),
      columnWidths: const {0: pw.FlexColumnWidth(2), 1: pw.FlexColumnWidth(1)},
      children: [
        pw.TableRow(children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Terms and Conditions', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                pw.Text(s.termsAndConditions, style: const pw.TextStyle(fontSize: 7)),
              ],
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(6),
            alignment: pw.Alignment.center,
            child: pw.Column(
              children: [
                pw.Text('For ${s.companyName}',
                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                if (signature != null)
                  pw.Image(signature, height: 40, fit: pw.BoxFit.contain)
                else
                  pw.SizedBox(height: 40),
                pw.Text('Authorised Signatory', style: const pw.TextStyle(fontSize: 7)),
              ],
            ),
          ),
        ]),
      ],
    );
  }

  static String _fmtNum(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }
}
