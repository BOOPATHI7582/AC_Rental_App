import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../services/admin_api_service.dart';

class AdminInvoiceDetailScreen extends StatefulWidget {
  final AdminInvoiceDetail invoice;

  const AdminInvoiceDetailScreen({super.key, required this.invoice});

  @override
  State<AdminInvoiceDetailScreen> createState() =>
      _AdminInvoiceDetailScreenState();
}

class _AdminInvoiceDetailScreenState extends State<AdminInvoiceDetailScreen> {
  bool _downloading = false;
  bool _sharing = false;

  AdminInvoiceDetail get invoice => widget.invoice;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy');
    final isPaid = invoice.balance <= 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),

      // ============================================================
      // APP BAR
      // ============================================================
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              invoice.invoiceNo,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const Text(
              'Invoice Details',
              style: TextStyle(fontSize: 10, color: Colors.white60),
            ),
          ],
        ),

        actions: [
          IconButton(
            tooltip: 'Share PDF',
            onPressed: _sharing ? null : _sharePdf,
            icon: _sharing
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
          ),

          const SizedBox(width: 4),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 35),

        children: [
          // ========================================================
          // HEADER
          // ========================================================
          _invoiceHeader(dateFmt: dateFmt, isPaid: isPaid),

          const SizedBox(height: 14),

          // ========================================================
          // CREATED BY
          // ========================================================
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cardHeader(Icons.person_outline_rounded, 'Created By'),

                const SizedBox(height: 16),

                _infoRow(
                  'Name',
                  invoice.createdByName ?? '—',
                  Icons.person_outline,
                ),

                _infoRow(
                  'Email',
                  invoice.createdByEmail ?? '—',
                  Icons.email_outlined,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ========================================================
          // INVOICE INFORMATION
          // ========================================================
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cardHeader(Icons.receipt_long_outlined, 'Invoice Information'),

                const SizedBox(height: 16),

                _infoRow(
                  'Invoice Number',
                  invoice.invoiceNo,
                  Icons.tag_rounded,
                ),

                _infoRow(
                  'Invoice Date',
                  invoice.date != null ? dateFmt.format(invoice.date!) : '—',
                  Icons.calendar_today_outlined,
                ),

                if (invoice.rentalStartDate != null)
                  _infoRow(
                    'Rental Period',
                    '${dateFmt.format(invoice.rentalStartDate!)}'
                        '${invoice.rentalEndDate != null ? ' → ${dateFmt.format(invoice.rentalEndDate!)}' : ''}',
                    Icons.date_range_outlined,
                  ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ========================================================
          // CLIENT
          // ========================================================
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cardHeader(Icons.business_outlined, 'Client'),

                const SizedBox(height: 16),

                _infoRow(
                  'Name',
                  invoice.clientName.isEmpty ? '—' : invoice.clientName,
                  Icons.person_outline,
                ),

                if (invoice.clientPhone.isNotEmpty)
                  _infoRow('Phone', invoice.clientPhone, Icons.phone_outlined),

                if (invoice.clientGstin.isNotEmpty)
                  _infoRow('GSTIN', invoice.clientGstin, Icons.badge_outlined),

                if (invoice.clientAddress.isNotEmpty)
                  _infoRow(
                    'Address',
                    invoice.clientAddress,
                    Icons.location_on_outlined,
                  ),

                if (invoice.clientState.isNotEmpty)
                  _infoRow('State', invoice.clientState, Icons.map_outlined),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ========================================================
          // ITEMS
          // ========================================================
          _card(
            padding: EdgeInsets.zero,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  child: _cardHeader(Icons.inventory_2_outlined, 'Items'),
                ),

                const Divider(height: 1),

                _itemsTable(),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ========================================================
          // PAYMENT SUMMARY
          // ========================================================
          _amountCard(),

          // ========================================================
          // NOTES
          // ========================================================
          if (invoice.notes.isNotEmpty) ...[
            const SizedBox(height: 14),

            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cardHeader(Icons.notes_rounded, 'Notes'),

                  const SizedBox(height: 14),

                  Text(
                    invoice.notes,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ========================================================
          // DOWNLOAD PDF
          // ========================================================
          SizedBox(
            height: 54,

            child: ElevatedButton.icon(
              onPressed: _downloading ? null : _downloadPdf,

              icon: _downloading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download_rounded),

              label: Text(
                _downloading ? 'Preparing PDF...' : 'Download PDF',

                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.black54,
                elevation: 0,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ========================================================
          // SHARE PDF
          // ========================================================
          SizedBox(
            height: 54,

            child: OutlinedButton.icon(
              onPressed: _sharing ? null : _sharePdf,

              icon: _sharing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.share_rounded),

              label: Text(
                _sharing ? 'Preparing...' : 'Share PDF',

                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),

              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.black12),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ========================================================
          // SHARE TEXT
          // ========================================================
          TextButton.icon(
            onPressed: _shareText,

            icon: const Icon(Icons.text_snippet_outlined, size: 18),

            label: const Text('Share Invoice Details'),

            style: TextButton.styleFrom(foregroundColor: Colors.black54),
          ),

          const SizedBox(height: 8),

          const Center(
            child: Text(
              'Admin Invoice Viewer',
              style: TextStyle(fontSize: 10, color: Colors.black38),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // INVOICE HEADER
  // ================================================================

  Widget _invoiceHeader({required DateFormat dateFmt, required bool isPaid}) {
    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(22),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,

                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(15),
                ),

                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),

              const Spacer(),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),

                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                ),

                child: Text(
                  isPaid ? 'PAID' : 'PAYMENT DUE',

                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          const Text(
            'Invoice Total',
            style: TextStyle(color: Colors.white60, fontSize: 11),
          ),

          const SizedBox(height: 5),

          Text(
            'Rs. ${invoice.total.toStringAsFixed(2)}',

            style: const TextStyle(
              color: Colors.white,
              fontSize: 29,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                color: Colors.white54,
                size: 13,
              ),

              const SizedBox(width: 6),

              Text(
                invoice.date != null
                    ? dateFmt.format(invoice.date!)
                    : 'Date not available',

                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================================================================
  // CARD
  // ================================================================

  Widget _card({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Container(
      padding: padding,

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),

      child: child,
    );
  }

  // ================================================================
  // CARD HEADER
  // ================================================================

  Widget _cardHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,

          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
          ),

          child: Icon(icon, size: 18, color: Colors.black),
        ),

        const SizedBox(width: 10),

        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  // ================================================================
  // INFO ROW
  // ================================================================

  Widget _infoRow(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Icon(icon, size: 17, color: Colors.black38),

          const SizedBox(width: 10),

          SizedBox(
            width: 95,

            child: Text(
              title,
              style: const TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,

              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // ITEMS TABLE
  // ================================================================

  Widget _itemsTable() {
    if (invoice.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),

        child: Center(
          child: Text('No items', style: TextStyle(color: Colors.black45)),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,

      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 550),

        child: Table(
          border: const TableBorder(
            horizontalInside: BorderSide(color: Color(0xFFEDEDED), width: 1),
          ),

          columnWidths: const {
            0: FlexColumnWidth(2.4),
            1: FlexColumnWidth(0.8),
            2: FlexColumnWidth(1.2),
            3: FlexColumnWidth(1.0),
            4: FlexColumnWidth(1.4),
          },

          children: [
            const TableRow(
              decoration: BoxDecoration(color: Color(0xFFF7F7F8)),

              children: [
                _TableCell('ITEM', bold: true),
                _TableCell('QTY', bold: true),
                _TableCell('PRICE', bold: true),
                _TableCell('IGST', bold: true),
                _TableCell('TOTAL', bold: true),
              ],
            ),

            for (final item in invoice.items)
              TableRow(
                children: [
                  _TableCell('${item.itemName}\n${item.unit}'),
                  _TableCell(_fmt(item.quantity)),
                  _TableCell('Rs. ${_fmt(item.price)}'),
                  _TableCell('${_fmt(item.igstPercent)}%'),
                  _TableCell(
                    'Rs. ${item.totalAmount.toStringAsFixed(2)}',
                    bold: true,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // PAYMENT SUMMARY
  // ================================================================

  Widget _amountCard() {
    return _card(
      child: Column(
        children: [
          _cardHeader(Icons.account_balance_wallet_outlined, 'Payment Summary'),

          const SizedBox(height: 18),

          _amountRow('Sub Total', invoice.subTotal),

          _amountRow('IGST Total', invoice.igstTotal),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 5),
            child: Divider(),
          ),

          _amountRow('Total Amount', invoice.total, bold: true, large: true),

          const SizedBox(height: 8),

          _amountRow('Received', invoice.receivedAmount),

          _amountRow('Balance', invoice.balance, bold: true, balance: true),
        ],
      ),
    );
  }

  Widget _amountRow(
    String title,
    double amount, {
    bool bold = false,
    bool large = false,
    bool balance = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),

      child: Row(
        children: [
          Text(
            title,

            style: TextStyle(
              fontSize: large ? 14 : 12,
              color: balance ? Colors.black : Colors.black54,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            ),
          ),

          const Spacer(),

          Text(
            'Rs. ${amount.toStringAsFixed(2)}',

            style: TextStyle(
              fontSize: large ? 17 : 12,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: balance && amount > 0
                  ? Colors.orange.shade800
                  : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // CREATE PDF
  // ================================================================

  Future<Uint8List> _createPdf() async {
    final pdf = pw.Document();

    final dateFmt = DateFormat('dd-MM-yyyy');

    final invoiceDate = invoice.date != null
        ? dateFmt.format(invoice.date!)
        : '—';

    final rentalPeriod = invoice.rentalStartDate != null
        ? '${dateFmt.format(invoice.rentalStartDate!)}'
              '${invoice.rentalEndDate != null ? ' to ${dateFmt.format(invoice.rentalEndDate!)}' : ''}'
        : '—';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,

        margin: const pw.EdgeInsets.all(32),

        build: (context) {
          return [
            // --------------------------------------------------------
            // PDF HEADER
            // --------------------------------------------------------
            pw.Container(
              padding: const pw.EdgeInsets.all(18),

              decoration: pw.BoxDecoration(
                color: PdfColors.black,
                borderRadius: pw.BorderRadius.circular(10),
              ),

              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,

                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,

                    children: [
                      pw.Text(
                        'AC RENTAL INVOICE',

                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),

                      pw.SizedBox(height: 5),

                      pw.Text(
                        'Invoice Management System',

                        style: const pw.TextStyle(
                          color: PdfColors.grey300,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),

                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,

                    children: [
                      pw.Text(
                        invoice.invoiceNo,

                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),

                      pw.SizedBox(height: 5),

                      pw.Text(
                        invoiceDate,

                        style: const pw.TextStyle(
                          color: PdfColors.grey300,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 22),

            // --------------------------------------------------------
            // CREATED BY + CLIENT
            // --------------------------------------------------------
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,

              children: [
                pw.Expanded(
                  child: _pdfInfoBox('CREATED BY', [
                    invoice.createdByName ?? '—',
                    invoice.createdByEmail ?? '—',
                  ]),
                ),

                pw.SizedBox(width: 15),

                pw.Expanded(
                  child: _pdfInfoBox('CLIENT', [
                    invoice.clientName.isEmpty ? '—' : invoice.clientName,
                    if (invoice.clientPhone.isNotEmpty) invoice.clientPhone,
                    if (invoice.clientGstin.isNotEmpty)
                      'GSTIN: ${invoice.clientGstin}',
                  ]),
                ),
              ],
            ),

            pw.SizedBox(height: 18),

            // --------------------------------------------------------
            // RENTAL INFORMATION
            // --------------------------------------------------------
            _pdfSectionTitle('INVOICE INFORMATION'),

            pw.SizedBox(height: 8),

            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),

              children: [
                pw.TableRow(
                  children: [
                    _pdfCell('Invoice Number', bold: true),
                    _pdfCell(invoice.invoiceNo),
                    _pdfCell('Date', bold: true),
                    _pdfCell(invoiceDate),
                  ],
                ),

                pw.TableRow(
                  children: [
                    _pdfCell('Rental Period', bold: true),
                    _pdfCell(rentalPeriod),
                    _pdfCell('State', bold: true),
                    _pdfCell(
                      invoice.clientState.isEmpty ? '—' : invoice.clientState,
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 20),

            // --------------------------------------------------------
            // ITEMS
            // --------------------------------------------------------
            _pdfSectionTitle('ITEMS'),

            pw.SizedBox(height: 8),

            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),

              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1),
                4: const pw.FlexColumnWidth(1.7),
              },

              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),

                  children: [
                    _pdfCell('Item', bold: true),
                    _pdfCell('Qty', bold: true),
                    _pdfCell('Price', bold: true),
                    _pdfCell('IGST', bold: true),
                    _pdfCell('Total', bold: true),
                  ],
                ),

                for (final item in invoice.items)
                  pw.TableRow(
                    children: [
                      _pdfCell('${item.itemName} (${item.unit})'),

                      _pdfCell(_fmt(item.quantity)),

                      _pdfCell('Rs. ${_fmt(item.price)}'),

                      _pdfCell('${_fmt(item.igstPercent)}%'),

                      _pdfCell('Rs. ${item.totalAmount.toStringAsFixed(2)}'),
                    ],
                  ),
              ],
            ),

            pw.SizedBox(height: 20),

            // --------------------------------------------------------
            // PAYMENT SUMMARY
            // --------------------------------------------------------
            _pdfSectionTitle('PAYMENT SUMMARY'),

            pw.SizedBox(height: 8),

            pw.Align(
              alignment: pw.Alignment.centerRight,

              child: pw.Container(
                width: 270,

                padding: const pw.EdgeInsets.all(14),

                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),

                  borderRadius: pw.BorderRadius.circular(8),
                ),

                child: pw.Column(
                  children: [
                    _pdfAmountRow('Sub Total', invoice.subTotal),

                    _pdfAmountRow('IGST Total', invoice.igstTotal),

                    pw.Divider(),

                    _pdfAmountRow('Total Amount', invoice.total, bold: true),

                    _pdfAmountRow('Received', invoice.receivedAmount),

                    _pdfAmountRow('Balance', invoice.balance, bold: true),
                  ],
                ),
              ),
            ),

            // --------------------------------------------------------
            // NOTES
            // --------------------------------------------------------
            if (invoice.notes.isNotEmpty) ...[
              pw.SizedBox(height: 20),

              _pdfSectionTitle('NOTES'),

              pw.SizedBox(height: 7),

              pw.Container(
                width: double.infinity,

                padding: const pw.EdgeInsets.all(12),

                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                ),

                child: pw.Text(
                  invoice.notes,
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
            ],

            pw.SizedBox(height: 25),

            pw.Divider(),

            pw.SizedBox(height: 7),

            pw.Center(
              child: pw.Text(
                'Generated from AC Rental Invoice Manager',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // ================================================================
  // PDF INFO BOX
  // ================================================================

  pw.Widget _pdfInfoBox(String title, List<String> values) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),

      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(7),
      ),

      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,

        children: [
          pw.Text(
            title,

            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),

          pw.SizedBox(height: 7),

          for (final value in values)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),

              child: pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
            ),
        ],
      ),
    );
  }

  // ================================================================
  // PDF SECTION TITLE
  // ================================================================

  pw.Widget _pdfSectionTitle(String title) {
    return pw.Text(
      title,

      style: pw.TextStyle(
        fontSize: 11,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.black,
      ),
    );
  }

  // ================================================================
  // PDF CELL
  // ================================================================

  pw.Widget _pdfCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(7),

      child: pw.Text(
        text,

        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  // ================================================================
  // PDF AMOUNT ROW
  // ================================================================

  pw.Widget _pdfAmountRow(String title, double amount, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),

      child: pw.Row(
        children: [
          pw.Text(
            title,

            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),

          pw.Spacer(),

          pw.Text(
            'Rs. ${amount.toStringAsFixed(2)}',

            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // DOWNLOAD PDF
  // ================================================================

  Future<void> _downloadPdf() async {
    if (_downloading) return;

    setState(() {
      _downloading = true;
    });

    try {
      final bytes = await _createPdf();

      final safeInvoiceNo = invoice.invoiceNo.replaceAll(
        RegExp(r'[\\/:*?"<>|]'),
        '_',
      );

      await FileSaver.instance.saveFile(
        name: 'Invoice_$safeInvoiceNo',
        bytes: bytes,
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invoice PDF saved successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save PDF: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _downloading = false;
        });
      }
    }
  }

  // ================================================================
  // SHARE PDF
  // ================================================================

  Future<void> _sharePdf() async {
    if (_sharing) return;

    setState(() {
      _sharing = true;
    });

    try {
      final bytes = await _createPdf();

      final safeInvoiceNo = invoice.invoiceNo.replaceAll(
        RegExp(r'[\\/:*?"<>|]'),
        '_',
      );

      final tempFile = XFile.fromData(
        bytes,
        name: 'Invoice_$safeInvoiceNo.pdf',
        mimeType: 'application/pdf',
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [tempFile],
          subject: 'Invoice ${invoice.invoiceNo}',
          text:
              'Invoice ${invoice.invoiceNo} - Rs. ${invoice.total.toStringAsFixed(2)}',
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not share PDF: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sharing = false;
        });
      }
    }
  }

  // ================================================================
  // SHARE TEXT
  // ================================================================

  Future<void> _shareText() async {
    final dateFmt = DateFormat('dd-MM-yyyy');

    final buffer = StringBuffer();

    buffer.writeln('AC RENTAL INVOICE');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');

    buffer.writeln('Invoice No: ${invoice.invoiceNo}');

    if (invoice.date != null) {
      buffer.writeln('Date: ${dateFmt.format(invoice.date!)}');
    }

    buffer.writeln();

    buffer.writeln('CLIENT');

    buffer.writeln(
      'Name: ${invoice.clientName.isEmpty ? '—' : invoice.clientName}',
    );

    if (invoice.clientPhone.isNotEmpty) {
      buffer.writeln('Phone: ${invoice.clientPhone}');
    }

    if (invoice.clientGstin.isNotEmpty) {
      buffer.writeln('GSTIN: ${invoice.clientGstin}');
    }

    buffer.writeln();

    buffer.writeln('ITEMS');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');

    for (final item in invoice.items) {
      buffer.writeln('${item.itemName} (${item.unit})');

      buffer.writeln(
        'Qty: ${_fmt(item.quantity)}'
        ' | Price: Rs. ${_fmt(item.price)}'
        ' | Total: Rs. ${item.totalAmount.toStringAsFixed(2)}',
      );
    }

    buffer.writeln();

    buffer.writeln('PAYMENT SUMMARY');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');

    buffer.writeln('Sub Total: Rs. ${invoice.subTotal.toStringAsFixed(2)}');

    buffer.writeln('IGST: Rs. ${invoice.igstTotal.toStringAsFixed(2)}');

    buffer.writeln('Total: Rs. ${invoice.total.toStringAsFixed(2)}');

    buffer.writeln(
      'Received: Rs. ${invoice.receivedAmount.toStringAsFixed(2)}',
    );

    buffer.writeln('Balance: Rs. ${invoice.balance.toStringAsFixed(2)}');

    if (invoice.notes.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Notes: ${invoice.notes}');
    }

    buffer.writeln();
    buffer.writeln('Generated from AC Rental Invoice Manager');

    await SharePlus.instance.share(
      ShareParams(
        text: buffer.toString(),
        subject: 'Invoice ${invoice.invoiceNo}',
      ),
    );
  }

  // ================================================================
  // FORMAT
  // ================================================================

  static String _fmt(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
  }
}

// ==================================================================
// TABLE CELL
// ==================================================================

class _TableCell extends StatelessWidget {
  final String text;
  final bool bold;

  const _TableCell(this.text, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),

      child: Text(
        text,

        style: TextStyle(
          fontSize: 10,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          color: bold ? Colors.black87 : Colors.black54,
        ),
      ),
    );
  }
}
