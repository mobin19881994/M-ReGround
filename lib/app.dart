import 'package:flutter/material.dart';
import 'package:m_reground/core/services/auth_service.dart';
import 'package:m_reground/core/services/version_guard_service.dart';
import 'package:m_reground/features/auth/auth_gate.dart';
import 'package:m_reground/features/home/dashboard_screen.dart';
import 'package:m_reground/features/profile/profile_screen.dart';

class MUnloopApp extends StatefulWidget {
  const MUnloopApp({super.key});

  @override
  State<MUnloopApp> createState() => _MUnloopAppState();
}

class _MUnloopAppState extends State<MUnloopApp> {
  int _tabIndex = 0;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await AuthService.instance.loadLocalUser();
    setState(() {
      _ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'M-ReGround',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF0B6E4F),
        useMaterial3: true,
      ),
      home: !_ready
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _buildHome(),
    );
  }

  Widget _buildHome() {
    if (VersionGuardService.instance.isExpired()) {
      return const _ExpiredScreen();
    }

    if (AuthService.instance.currentUser == null) {
      return AuthGate(
        onAuthenticated: (_) {
          setState(() {});
        },
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _tabIndex,
        children: const <Widget>[
          DashboardScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.home), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onDestinationSelected: (int i) => setState(() => _tabIndex = i),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await AuthService.instance.signOut();
          setState(() {
            _tabIndex = 0;
          });
        },
        icon: const Icon(Icons.logout),
        label: const Text('Sign Out'),
      ),
    );
  }
}

class _ExpiredScreen extends StatelessWidget {
  const _ExpiredScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const <Widget>[
              Icon(Icons.lock_clock, size: 66),
              SizedBox(height: 10),
              Text(
                'App trial expired',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'This build has reached its 30-day limit. Contact admin for renewal.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
