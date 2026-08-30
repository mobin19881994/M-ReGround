import 'package:flutter/material.dart';
import 'package:m_reground/core/services/auth_service.dart';
import 'package:m_reground/core/services/foreground_timer_service.dart';
import 'package:m_reground/core/services/logger_service.dart';
import 'package:m_reground/core/services/local_storage_service.dart';
import 'package:m_reground/config/app_config.dart';
import 'package:m_reground/features/debug/demo_profiles_screen.dart';
import 'package:m_reground/core/services/demo_data_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _logs = '';
  bool _loading = false;

  Future<void> _viewLogs() async {
    final bool isAdmin = AuthService.instance.currentUser?.isAdmin ?? false;
    if (!isAdmin) {
      setState(() {
        _logs = 'Logs access is restricted to admin users.';
      });
      return;
    }

    setState(() {
      _loading = true;
    });
    final String logs = await LoggerService.instance.readLogs();
    setState(() {
      _logs = logs.isEmpty ? 'No logs yet.' : logs;
      _loading = false;
    });
  }

  Future<void> _clearLogs() async {
    final bool isAdmin = AuthService.instance.currentUser?.isAdmin ?? false;
    if (!isAdmin) {
      setState(() {
        _logs = 'Clear logs is restricted to admin users.';
      });
      return;
    }

    await LoggerService.instance.clearLogs();
    setState(() {
      _logs = 'Logs cleared.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final AuthUser? user = AuthService.instance.currentUser;
    final ForegroundTimerService timer = ForegroundTimerService.instance;
    final bool isAdmin = user?.isAdmin == true;

    final int instagramUsage = timer.state.activeTargetApp == 'instagram' ? timer.state.dailyUsageMinutes : 0;
    final int youtubeUsage = timer.state.activeTargetApp == 'youtube' ? timer.state.dailyUsageMinutes : 0;
    final int focusScore = (100 - timer.state.dailyUsageMinutes).clamp(10, 100);
    final int recoveryPoints = (timer.state.dailyUsageMinutes < 60) ? 30 : 10;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Diagnostics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          ListTile(
            title: Text(user?.email ?? 'Guest'),
            subtitle: Text(user?.isAdmin == true ? 'Admin mode' : 'Standard mode'),
            leading: const CircleAvatar(child: Icon(Icons.person)),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Usage Breakdown', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('Instagram: $instagramUsage min'),
                  Text('YouTube: $youtubeUsage min'),
                  Text('Focus Personality Score: $focusScore'),
                  Text('Daily Recovery Points: $recoveryPoints'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Emergency Bypass Tracker', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('Used Today: ${timer.state.emergencyBypassCount}/${AppConfig.emergencyBypassLimitPerDay}'),
                  Text('Duration per bypass: ${AppConfig.emergencyBypassDurationMinutes} minutes'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('System & Activity Logs', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: <Widget>[
                      FilledButton(
                        onPressed: _loading ? null : _viewLogs,
                        child: Text(isAdmin ? 'View Logs' : 'View Logs (Admin Only)'),
                      ),
                          if (AppConfig.useLocalOnlyPersistence)
                            OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DemoProfilesScreen()));
                              },
                              child: const Text('Demo Profiles'),
                            ),
                      OutlinedButton(
                        onPressed: isAdmin ? _clearLogs : null,
                        child: const Text('Clear Logs'),
                      ),
                          if (AppConfig.useLocalOnlyPersistence) ...<Widget>[
                            FilledButton.tonal(
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                await DemoDataService.seedNow();
                                if (!mounted) return;
                                messenger.showSnackBar(const SnackBar(content: Text('Demo data seeded')));
                              },
                              child: const Text('Seed Demo Data'),
                            ),
                            OutlinedButton(
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                await DemoDataService.clearDemoData();
                                if (!mounted) return;
                                messenger.showSnackBar(const SnackBar(content: Text('Demo data cleared')));
                              },
                              child: const Text('Clear Demo Data'),
                            ),
                          ],
                          if (AppConfig.useLocalOnlyPersistence)
                            FutureBuilder<bool>(
                              future: _readAutoSeedFlag(),
                              builder: (BuildContext ctx, AsyncSnapshot<bool> snap) {
                                final bool value = snap.data ?? false;
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    const Text('Auto-seed demo on startup'),
                                    Switch(
                                      value: value,
                                      onChanged: (bool v) async {
                                        await _setAutoSeedFlag(v);
                                        setState(() {});
                                      },
                                    ),
                                  ],
                                );
                              },
                            ),
                          if (AppConfig.useLocalOnlyPersistence)
                            FutureBuilder<bool>(
                              future: _readDemoIgnoreFlag(),
                              builder: (BuildContext ctx, AsyncSnapshot<bool> snap) {
                                final bool value = snap.data ?? false;
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    const Text('Ignore locks for demo user'),
                                    Switch(
                                      value: value,
                                      onChanged: (bool v) async {
                                        await _setDemoIgnoreFlag(v);
                                        setState(() {});
                                      },
                                    ),
                                  ],
                                );
                              },
                            ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(0, 0, 0, 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _loading ? 'Loading...' : _logs,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _readAutoSeedFlag() async {
    try {
      final dynamic v = LocalStorageService.instance.userBox().get('demo_auto_seed');
      if (v is bool) return v;
    } catch (_) {}
    return true;
  }

  Future<void> _setAutoSeedFlag(bool v) async {
    try {
      await LocalStorageService.instance.userBox().put('demo_auto_seed', v);
    } catch (_) {}
  }

  Future<bool> _readDemoIgnoreFlag() async {
    try {
      final dynamic v = LocalStorageService.instance.userBox().get('demo_ignore_locks');
      if (v is bool) return v;
    } catch (_) {}
    return false;
  }

  Future<void> _setDemoIgnoreFlag(bool v) async {
    try {
      await LocalStorageService.instance.userBox().put('demo_ignore_locks', v);
    } catch (_) {}
  }
}
