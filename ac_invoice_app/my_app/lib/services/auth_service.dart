import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

/// Handles register/login/logout against our own backend (see
/// server/README.md).
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _tokenKey = 'ac_invoice_auth_token';
  static const _userIdKey = 'ac_invoice_user_id';
  static const _emailKey = 'ac_invoice_user_email';
  static const _nameKey = 'ac_invoice_user_name';
  static const _phoneKey = 'ac_invoice_user_phone';
  static const _roleKey = 'ac_invoice_user_role';

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  /// Returns null on success, or a human-readable error message on failure.
  Future<String?> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    try {
      final res = await http.post(
        _uri('/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'phone': phone, 'email': email, 'password': password}),
      );
      if (res.statusCode == 200 || res.statusCode == 201) return null;
      return _errorMessage(res);
    } catch (e) {
      return 'Could not reach the server. Check ApiConfig.baseUrl and that '
          'the server is running.';
    }
  }

  /// Returns null on success (and saves the session), or an error message.
  Future<String?> login(String email, String password) async {
    try {
      final res = await http.post(
        _uri('/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, data['token'] as String? ?? '');
        await prefs.setString(_userIdKey, data['userId'] as String? ?? '');
        await prefs.setString(_emailKey, data['email'] as String? ?? email);
        await prefs.setString(_nameKey, data['name'] as String? ?? '');
        await prefs.setString(_phoneKey, data['phone'] as String? ?? '');
        await prefs.setString(_roleKey, data['role'] as String? ?? 'user');
        return null;
      }
      return _errorMessage(res);
    } catch (e) {
      return 'Could not reach the server. Check ApiConfig.baseUrl and that '
          'the server is running.';
    }
  }

  String _errorMessage(http.Response res) {
    try {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['error'] as String? ?? 'Something went wrong (${res.statusCode})';
    } catch (_) {
      return 'Something went wrong (${res.statusCode})';
    }
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<bool> isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey) == 'admin';
  }

  Future<String?> currentToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> currentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  Future<String?> currentEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  Future<String?> currentName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_phoneKey);
    await prefs.remove(_roleKey);
  }
}
