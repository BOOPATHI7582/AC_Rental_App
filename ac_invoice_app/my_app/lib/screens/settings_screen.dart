import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/company_settings.dart';
import '../main.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../widgets/signature_pad.dart';
import 'admin_screen.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  CompanySettings _settings = CompanySettings();
  bool _loading = true;
  String? _userEmail;
  bool _isAdmin = false;
  bool _syncing = false;

  final _companyNameCtrl = TextEditingController();
  final _taglineCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _gstinCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _bankBranchCtrl = TextEditingController();
  final _accountNoCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _accountHolderCtrl = TextEditingController();
  final _termsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await StorageService.instance.getSettings();
    final email = await AuthService.instance.currentEmail();
    final isAdmin = await AuthService.instance.isAdmin();
    setState(() {
      _settings = s;
      _userEmail = email;
      _isAdmin = isAdmin;
      _companyNameCtrl.text = s.companyName;
      _taglineCtrl.text = s.tagline;
      _addressCtrl.text = s.address;
      _phoneCtrl.text = s.phone;
      _emailCtrl.text = s.email;
      _gstinCtrl.text = s.gstin;
      _stateCtrl.text = s.state;
      _bankNameCtrl.text = s.bankName;
      _bankBranchCtrl.text = s.bankBranch;
      _accountNoCtrl.text = s.accountNumber;
      _ifscCtrl.text = s.ifscCode;
      _accountHolderCtrl.text = s.accountHolderName;
      _termsCtrl.text = s.termsAndConditions;
      _loading = false;
    });
  }

  Future<void> _pickImage({required bool isLogo}) async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    final saved = await StorageService.instance
        .persistImage(File(file.path), isLogo ? 'logo' : 'signature');
    setState(() {
      if (isLogo) {
        _settings.logoPath = saved;
      } else {
        _settings.signaturePath = saved;
      }
    });
  }

  Future<void> _syncNow() async {
    setState(() => _syncing = true);
    final count = await StorageService.instance.syncInvoicesFromCloud();
    if (!mounted) return;
    setState(() => _syncing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(count > 0 ? 'Synced $count invoice(s) from the cloud' : 'Nothing new to sync')),
    );
  }

  Future<void> _logout() async {
    await StorageService.instance.clearLocalInvoices();
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }

  Future<void> _goToLogin() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen(onLoggedIn: () => Navigator.pop(context))),
    );
    _load();
  }

  Future<void> _drawSignature() async {
    final bytes = await Navigator.push<List<int>>(
      context,
      MaterialPageRoute(builder: (_) => const SignaturePadScreen()),
    );
    if (bytes == null) return;
    final saved = await StorageService.instance.persistImageBytes(bytes, 'signature');
    setState(() => _settings.signaturePath = saved);
  }

  Future<void> _chooseSignatureSource() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Add signature', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.draw_outlined),
              title: const Text('Write on White Board'),
              subtitle: const Text('Sign with your finger on this phone'),
              onTap: () => Navigator.pop(ctx, 'draw'),
            ),
            ListTile(
              leading: const Icon(Icons.upload_outlined),
              title: const Text('Upload Image'),
              onTap: () => Navigator.pop(ctx, 'upload'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice == 'draw') {
      await _drawSignature();
    } else if (choice == 'upload') {
      await _pickImage(isLogo: false);
    }
  }

  Future<void> _clearImage({required bool isLogo}) async {
    setState(() {
      if (isLogo) {
        _settings.logoPath = null;
      } else {
        _settings.signaturePath = null;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _settings
      ..companyName = _companyNameCtrl.text.trim()
      ..tagline = _taglineCtrl.text.trim()
      ..address = _addressCtrl.text.trim()
      ..phone = _phoneCtrl.text.trim()
      ..email = _emailCtrl.text.trim()
      ..gstin = _gstinCtrl.text.trim()
      ..state = _stateCtrl.text.trim()
      ..bankName = _bankNameCtrl.text.trim()
      ..bankBranch = _bankBranchCtrl.text.trim()
      ..accountNumber = _accountNoCtrl.text.trim()
      ..ifscCode = _ifscCtrl.text.trim()
      ..accountHolderName = _accountHolderCtrl.text.trim()
      ..termsAndConditions = _termsCtrl.text.trim();

    await StorageService.instance.saveSettings(_settings);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.black)));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle('Account'),
            if (_userEmail != null) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.account_circle_outlined),
                title: Text(_userEmail!),
                subtitle: const Text('Signed in \u2014 invoices back up to the cloud'),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _syncing ? null : _syncNow,
                      icon: _syncing
                          ? const SizedBox(
                              height: 14, width: 14,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.cloud_sync_outlined),
                      label: const Text('Sync Now'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Log Out'),
                    ),
                  ),
                ],
              ),
              if (_isAdmin) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminScreen()),
                    ),
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    label: const Text('Admin Dashboard \u2014 All Users & Invoices'),
                  ),
                ),
              ],
            ] else
              OutlinedButton.icon(
                onPressed: _goToLogin,
                icon: const Icon(Icons.login),
                label: const Text('Log In / Register for Cloud Backup'),
              ),
            const SizedBox(height: 20),
            _sectionTitle('Company Logo'),
            _imagePickerTile(
              path: _settings.logoPath,
              label: 'Tap to upload company logo',
              onTap: () => _pickImage(isLogo: true),
              onDelete: () => _clearImage(isLogo: true),
            ),
            const SizedBox(height: 20),
            _sectionTitle('Company Details'),
            _field(_companyNameCtrl, 'Company Name', required: true),
            _field(_taglineCtrl, 'Tagline (optional)'),
            _field(_addressCtrl, 'Address', maxLines: 2),
            _field(_phoneCtrl, 'Phone', keyboardType: TextInputType.phone),
            _field(_emailCtrl, 'Email', keyboardType: TextInputType.emailAddress),
            _field(_gstinCtrl, 'GSTIN Number'),
            _field(_stateCtrl, 'State'),
            const SizedBox(height: 20),
            _sectionTitle('Bank Details'),
            _field(_bankNameCtrl, 'Bank Name'),
            _field(_bankBranchCtrl, 'Branch'),
            _field(_accountNoCtrl, 'Account Number'),
            _field(_ifscCtrl, 'IFSC Code'),
            _field(_accountHolderCtrl, 'Account Holder Name'),
            const SizedBox(height: 20),
            _sectionTitle('Terms and Conditions'),
            _field(_termsCtrl, 'Terms and conditions shown on every invoice', maxLines: 5),
            const SizedBox(height: 20),
            _sectionTitle('Authorised Signature'),
            _imagePickerTile(
              path: _settings.signaturePath,
              label: 'Tap to draw or upload your signature',
              onTap: _chooseSignatureSource,
              onDelete: () => _clearImage(isLogo: false),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Save Settings'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      );

  Widget _field(TextEditingController ctrl, String label,
      {bool required = false, int maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
            : null,
      ),
    );
  }

  Widget _imagePickerTile({
    required String? path,
    required String label,
    required VoidCallback onTap,
    required VoidCallback onDelete,
  }) {
    final hasImage = path != null && File(path).existsSync();
    return Stack(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            height: 110,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black38),
              borderRadius: BorderRadius.circular(4),
            ),
            child: hasImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.file(File(path), fit: BoxFit.contain),
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_photo_alternate_outlined, color: Colors.black54, size: 28),
                        const SizedBox(height: 6),
                        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                      ],
                    ),
                  ),
          ),
        ),
        if (hasImage)
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
      ],
    );
  }
}
