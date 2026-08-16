import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onRegistered;

  const RegisterScreen({super.key, required this.onRegistered});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final regError = await AuthService.instance.register(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );

      if (!mounted) return;

      if (regError != null) {
        setState(() {
          _loading = false;
          _error = regError;
        });
        return;
      }

      // Automatically login after successful registration.
      final loginError = await AuthService.instance.login(
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
      );

      if (!mounted) return;

      if (loginError != null) {
        setState(() {
          _loading = false;
          _error = loginError;
        });
        return;
      }

      setState(() {
        _loading = false;
      });

      // Tell the parent that registration/login is complete.
      widget.onRegistered();
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
                  vertical: 34,
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
                      // Logo
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
                            Icons.person_add_alt_1_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      const Text(
                        'Create Account',
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
                        'Create your account to get started',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Full Name
                      TextFormField(
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: _inputDecoration(
                          label: 'Full Name',
                          icon: Icons.person_outline_rounded,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Phone
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration(
                          label: 'Phone Number',
                          icon: Icons.phone_outlined,
                        ),
                        validator: (value) {
                          if (value != null &&
                              value.trim().isNotEmpty &&
                              value.trim().length < 10) {
                            return 'Enter a valid phone number';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Email
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

                      // Password
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        decoration: _inputDecoration(
                          label: 'Password',
                          icon: Icons.lock_outline_rounded,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
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

                      const SizedBox(height: 16),

                      // Confirm Password
                      TextFormField(
                        controller: _confirmCtrl,
                        obscureText: _obscureConfirm,
                        decoration: _inputDecoration(
                          label: 'Confirm Password',
                          icon: Icons.lock_outline_rounded,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscureConfirm = !_obscureConfirm;
                              });
                            },
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value != _passwordCtrl.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),

                      // Error
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

                      // Register Button
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _register,
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
                                      'Create Account',
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

                      Text(
                        'By creating an account, you agree to our terms and privacy policy.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          height: 1.4,
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
