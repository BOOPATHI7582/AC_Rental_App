import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoggedIn;

  const LoginScreen({super.key, required this.onLoggedIn});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final error = await AuthService.instance.login(
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
      );

      if (!mounted) return;

      if (error != null) {
        setState(() {
          _loading = false;
          _error = error;
        });
        return;
      }

      setState(() {
        _loading = false;
      });

      // Login successful
      widget.onLoggedIn();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,

      prefixIcon: Icon(icon, size: 21, color: Colors.grey.shade600),

      suffixIcon: suffixIcon,

      filled: true,
      fillColor: const Color(0xFFF8F9FB),

      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.black, width: 1.4),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
      ),

      floatingLabelStyle: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),

            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),

              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width > 500 ? 40 : 24,
                  vertical: 36,
                ),

                decoration: BoxDecoration(
                  color: Colors.white,

                  borderRadius: BorderRadius.circular(28),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 35,
                      offset: const Offset(0, 15),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),

                child: Form(
                  key: _formKey,

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,

                    children: [
                      // ------------------------------------------------
                      // LOGO
                      // ------------------------------------------------
                      Center(
                        child: Container(
                          width: 76,
                          height: 76,

                          decoration: BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,

                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.18),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),

                          child: const Icon(
                            Icons.ac_unit_rounded,
                            color: Colors.white,
                            size: 38,
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      // ------------------------------------------------
                      // TITLE
                      // ------------------------------------------------
                      const Text(
                        'AC Rental Invoice',
                        textAlign: TextAlign.center,

                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: Color(0xFF111111),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Sign in to manage your invoices',
                        textAlign: TextAlign.center,

                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // ------------------------------------------------
                      // EMAIL
                      // ------------------------------------------------
                      TextFormField(
                        controller: _emailCtrl,

                        keyboardType: TextInputType.emailAddress,

                        decoration: _inputDecoration(
                          label: 'Email Address',
                          icon: Icons.email_outlined,
                        ),

                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required';
                          }

                          if (!RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch(value.trim())) {
                            return 'Enter a valid email address';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // ------------------------------------------------
                      // PASSWORD
                      // ------------------------------------------------
                      TextFormField(
                        controller: _passwordCtrl,

                        obscureText: _obscure,

                        decoration: _inputDecoration(
                          label: 'Password',
                          icon: Icons.lock_outline_rounded,

                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscure = !_obscure;
                              });
                            },

                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),

                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Password must contain at least 6 characters';
                          }

                          return null;
                        },
                      ),

                      // ------------------------------------------------
                      // ERROR
                      // ------------------------------------------------
                      if (_error != null) ...[
                        const SizedBox(height: 18),

                        Container(
                          padding: const EdgeInsets.all(13),

                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.06),

                            borderRadius: BorderRadius.circular(12),

                            border: Border.all(
                              color: Colors.red.withOpacity(0.15),
                            ),
                          ),

                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: Colors.redAccent,
                                size: 20,
                              ),

                              const SizedBox(width: 10),

                              Expanded(
                                child: Text(
                                  _error!,

                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 26),

                      // ------------------------------------------------
                      // LOGIN BUTTON
                      // ------------------------------------------------
                      SizedBox(
                        height: 56,

                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,

                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,

                            disabledBackgroundColor: Colors.grey.shade400,

                            elevation: 8,

                            shadowColor: Colors.black.withOpacity(0.25),

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),

                          child: _loading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,

                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,

                                  children: [
                                    Text(
                                      'Sign In',

                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),

                                    SizedBox(width: 8),

                                    Icon(Icons.arrow_forward_rounded, size: 20),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ------------------------------------------------
                      // REGISTER
                      // ------------------------------------------------
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,

                        children: [
                          Text(
                            "Don't have an account?",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),

                          TextButton(
                            onPressed: _loading
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => RegisterScreen(
                                          onRegistered: widget.onLoggedIn,
                                        ),
                                      ),
                                    );
                                  },

                            style: TextButton.styleFrom(
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                            ),

                            child: const Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // ------------------------------------------------
                      // CONTINUE WITHOUT ACCOUNT
                      // ------------------------------------------------
                      TextButton(
                        onPressed: _loading ? null : widget.onLoggedIn,

                        child: Text(
                          'Continue without an account',

                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ------------------------------------------------
                      // FOOTER
                      // ------------------------------------------------
                      Text(
                        'Secure invoice management for your business',
                        textAlign: TextAlign.center,

                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
