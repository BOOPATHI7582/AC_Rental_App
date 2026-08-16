import 'package:flutter/material.dart';

import 'screens/clients_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'widgets/app_theme.dart';

void main() {
  runApp(const ACInvoiceApp());
}

class ACInvoiceApp extends StatelessWidget {
  const ACInvoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AC Rental Invoice',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashScreen(next: AuthGate()),
    );
  }
}

/// Shows Login until the user either logs in / registers, or chooses to
/// continue without an account (the app works fully offline either way -
/// MongoDB is only used for optional cloud backup/sync).
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool? _loggedIn;
  bool _skipped = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final loggedIn = await AuthService.instance.isLoggedIn();
    if (mounted) setState(() => _loggedIn = loggedIn);
  }

  @override
  Widget build(BuildContext context) {
    if (_loggedIn == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.black)));
    }
    if (_loggedIn == false && !_skipped) {
      return LoginScreen(onLoggedIn: () => setState(() {
            _loggedIn = true;
            _skipped = true;
          }));
    }
    return const RootNav();
  }
}

class RootNav extends StatefulWidget {
  const RootNav({super.key});

  @override
  State<RootNav> createState() => _RootNavState();
}

class _RootNavState extends State<RootNav> {
  int _index = 0;

  final _screens = const [
    HomeScreen(),
    ClientsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Clients'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}
