import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/client.dart';
import '../models/company_settings.dart';
import '../models/invoice.dart';
import '../services/storage_service.dart';
import 'client_form_screen.dart';
import 'invoice_view_screen.dart';

class InvoiceFormScreen extends StatefulWidget {
  final Invoice? existing;
  const InvoiceFormScreen({super.key, this.existing});

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _ItemRow {
  final itemNameCtrl = TextEditingController();
  final unitCtrl = TextEditingController(text: '-');
  final qtyCtrl = TextEditingController(text: '1');
  final priceCtrl = TextEditingController();
  final igstCtrl = TextEditingController(text: '18');

  _ItemRow();

  _ItemRow.fromItem(InvoiceItem it) {
    itemNameCtrl.text = it.itemName;
    unitCtrl.text = it.unit;
    qtyCtrl.text = _trim(it.quantity);
    priceCtrl.text = _trim(it.price);
    igstCtrl.text = _trim(it.igstPercent);
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  double get qty => double.tryParse(qtyCtrl.text) ?? 0;
  double get price => double.tryParse(priceCtrl.text) ?? 0;
  double get igst => double.tryParse(igstCtrl.text) ?? 0;
  double get taxable => qty * price;
  double get igstAmount => taxable * igst / 100;
  double get total => taxable + igstAmount;

  InvoiceItem toItem() => InvoiceItem(
    itemName: itemNameCtrl.text.trim(),
    unit: unitCtrl.text.trim(),
    quantity: qty,
    price: price,
    igstPercent: igst,
  );

  void dispose() {
    itemNameCtrl.dispose();
    unitCtrl.dispose();
    qtyCtrl.dispose();
    priceCtrl.dispose();
    igstCtrl.dispose();
  }
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  List<Client> _clients = [];
  Client? _selectedClient;
  final _invoiceNoCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  DateTime? _rentalStart;
  DateTime? _rentalEnd;
  final _receivedCtrl = TextEditingController(text: '0');
  final List<_ItemRow> _rows = [];
  CompanySettings _settings = CompanySettings();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final clients = await StorageService.instance.getClients();
    final settings = await StorageService.instance.getSettings();
    setState(() {
      _clients = clients;
      _settings = settings;
      if (widget.existing != null) {
        final inv = widget.existing!;
        _invoiceNoCtrl.text = inv.invoiceNo;
        _date = inv.date;
        _rentalStart = inv.rentalStartDate;
        _rentalEnd = inv.rentalEndDate;
        _receivedCtrl.text = _ItemRow._trim(inv.receivedAmount);
        for (final c in clients) {
          if (c.id == inv.clientId) {
            _selectedClient = c;
            break;
          }
        }
        for (final it in inv.items) {
          _rows.add(_ItemRow.fromItem(it));
        }
      } else {
        _invoiceNoCtrl.text =
            'INV-${settings.nextInvoiceNumber.toString().padLeft(4, '0')}';
        _rows.add(_ItemRow());
      }
      _loading = false;
    });
  }

  double get _subTotal => _rows.fold(0.0, (s, r) => s + r.taxable);
  double get _igstTotal => _rows.fold(0.0, (s, r) => s + r.igstAmount);
  double get _grandTotal => _subTotal + _igstTotal;
  double get _received => double.tryParse(_receivedCtrl.text) ?? 0;
  double get _balance => _grandTotal - _received;

  Future<void> _addNewClient() async {
    final client = await Navigator.push<Client>(
      context,
      MaterialPageRoute(builder: (_) => const ClientFormScreen()),
    );
    if (client != null) {
      setState(() {
        _clients.add(client);
        _selectedClient = client;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickRentalStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _rentalStart ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _rentalStart = picked);
  }

  Future<void> _pickRentalEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _rentalEnd ?? (_rentalStart ?? DateTime.now()),
      firstDate: _rentalStart ?? DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _rentalEnd = picked);
  }

  Future<void> _saveAndPreview() async {
    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or add a client')),
      );
      return;
    }
    final validRows = _rows
        .where((r) => r.itemNameCtrl.text.trim().isNotEmpty)
        .toList();
    if (validRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one service/item')),
      );
      return;
    }

    final invoice = Invoice(
      id: widget.existing?.id ?? const Uuid().v4(),
      invoiceNo: _invoiceNoCtrl.text.trim(),
      date: _date,
      clientId: _selectedClient!.id,
      items: validRows.map((r) => r.toItem()).toList(),
      receivedAmount: _received,
      rentalStartDate: _rentalStart,
      rentalEndDate: _rentalEnd,
    );

    await StorageService.instance.upsertInvoice(invoice);

    if (widget.existing == null) {
      _settings.nextInvoiceNumber += 1;
      await StorageService.instance.saveSettings(_settings);
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => InvoiceViewScreen(invoiceId: invoice.id),
      ),
    );
  }

  @override
  void dispose() {
    _invoiceNoCtrl.dispose();
    _receivedCtrl.dispose();
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'New Invoice' : 'Edit Invoice'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Client'),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<Client>(
                  value: _selectedClient,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Select Client'),
                  items: _clients
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.name, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (c) => setState(() => _selectedClient = c),
                ),
              ),
              IconButton(
                onPressed: _addNewClient,
                icon: const Icon(Icons.person_add_alt_1),
                tooltip: 'Add new client',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _sectionTitle('Invoice Details'),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _invoiceNoCtrl,
                  decoration: const InputDecoration(labelText: 'Invoice No.'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Date'),
                    child: Text(DateFormat('dd-MM-yyyy').format(_date)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _pickRentalStart,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Rental Period From',
                    ),
                    child: Text(
                      _rentalStart != null
                          ? DateFormat('dd-MM-yyyy').format(_rentalStart!)
                          : '—',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: _pickRentalEnd,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Rental Period To',
                    ),
                    child: Text(
                      _rentalEnd != null
                          ? DateFormat('dd-MM-yyyy').format(_rentalEnd!)
                          : '—',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _sectionTitle('Service / Item Details'),
          _itemsGrid(),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _rows.add(_ItemRow())),
              icon: const Icon(Icons.add, color: Colors.black),
              label: const Text(
                'Add Row',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle('Amounts'),
          _summaryRow('Sub Total', _subTotal),
          _summaryRow('IGST Total', _igstTotal),
          const Divider(),
          _summaryRow('Total Amount', _grandTotal, bold: true),
          const SizedBox(height: 8),
          TextFormField(
            controller: _receivedCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Received Amount'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          _summaryRow('Balance Amount', _balance, bold: true),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: _saveAndPreview,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Save & Preview Invoice'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
    ),
  );

  Widget _summaryRow(String label, double value, {bool bold = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontSize: bold ? 15 : 13,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('Rs. ${value.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }

  // Item table: header row + editable rows, all inside one bordered grid
  // (row/column layout, matching the requested design - no separate boxes).
  Widget _itemsGrid() {
    return Table(
      border: TableBorder.all(color: Colors.black26, width: 0.8),
      columnWidths: const {
        0: FlexColumnWidth(2.3),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1.2),
        4: FlexColumnWidth(1),
        5: FlexColumnWidth(0.5),
      },
      children: [
        const TableRow(
          decoration: BoxDecoration(color: Color(0xFFEDEDED)),
          children: [
            _HeaderCell('Item'),
            _HeaderCell('Unit'),
            _HeaderCell('Qty'),
            _HeaderCell('Price'),
            _HeaderCell('IGST %'),
            _HeaderCell(''),
          ],
        ),
        for (int i = 0; i < _rows.length; i++)
          TableRow(
            children: [
              _cellField(_rows[i].itemNameCtrl, hint: 'e.g. AC Tower 10 Ton'),
              _cellField(_rows[i].unitCtrl, hint: 'Nos'),
              _cellField(_rows[i].qtyCtrl, hint: '1', numeric: true),
              _cellField(_rows[i].priceCtrl, hint: '2000', numeric: true),
              _cellField(_rows[i].igstCtrl, hint: '18', numeric: true),
              Padding(
                padding: const EdgeInsets.all(2),
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: Colors.black54,
                  ),
                  onPressed: _rows.length == 1
                      ? null
                      : () => setState(() {
                          _rows[i].dispose();
                          _rows.removeAt(i);
                        }),
                ),
              ),
            ],
          ),
        // Computed amount / igst amount / total row summary per item, shown below each row's inputs
        for (int i = 0; i < _rows.length; i++)
          TableRow(
            children: [
              _amountLabelCell(
                'Amount: Rs. ${_rows[i].taxable.toStringAsFixed(2)}',
              ),
              const SizedBox.shrink(),
              const SizedBox.shrink(),
              _amountLabelCell(
                'IGST: Rs. ${_rows[i].igstAmount.toStringAsFixed(2)}',
              ),
              _amountLabelCell(
                'Total: Rs. ${_rows[i].total.toStringAsFixed(2)}',
              ),
              const SizedBox.shrink(),
            ],
          ),
      ],
    );
  }

  Widget _cellField(
    TextEditingController ctrl, {
    String hint = '',
    bool numeric = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: TextField(
        controller: ctrl,
        keyboardType: numeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _amountLabelCell(String text) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    child: Text(
      text,
      style: const TextStyle(fontSize: 10, color: Colors.black54),
    ),
  );
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }
}
