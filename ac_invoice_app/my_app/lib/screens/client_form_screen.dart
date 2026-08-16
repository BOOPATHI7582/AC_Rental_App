import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/client.dart';
import '../services/storage_service.dart';

class ClientFormScreen extends StatefulWidget {
  final Client? existing;
  const ClientFormScreen({super.key, this.existing});

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _phone;
  late final TextEditingController _gstin;
  late final TextEditingController _state;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _address = TextEditingController(text: e?.address ?? '');
    _phone = TextEditingController(text: e?.phone ?? '');
    _gstin = TextEditingController(text: e?.gstin ?? '');
    _state = TextEditingController(text: e?.state ?? 'Tamil Nadu');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final client = Client(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _name.text.trim(),
      address: _address.text.trim(),
      phone: _phone.text.trim(),
      gstin: _gstin.text.trim(),
      state: _state.text.trim(),
    );
    await StorageService.instance.upsertClient(client);
    if (!mounted) return;
    Navigator.pop(context, client);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Client' : 'New Client')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Client / Business Name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _gstin,
              decoration: const InputDecoration(labelText: 'GSTIN Number (optional)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _state,
              decoration: const InputDecoration(labelText: 'State'),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Save Client'),
            ),
          ],
        ),
      ),
    );
  }
}
