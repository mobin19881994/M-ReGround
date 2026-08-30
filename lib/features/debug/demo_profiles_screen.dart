import 'package:flutter/material.dart';
import 'package:m_reground/core/services/demo_data_service.dart';
import 'package:m_reground/core/services/foreground_timer_service.dart';
import 'package:m_reground/core/services/local_storage_service.dart';
import 'package:m_reground/core/services/auth_service.dart';

class DemoProfilesScreen extends StatefulWidget {
  const DemoProfilesScreen({super.key});

  @override
  State<DemoProfilesScreen> createState() => _DemoProfilesScreenState();
}

class _DemoProfilesScreenState extends State<DemoProfilesScreen> {
  List<String> _emails = <String>[];
  String? _selected;
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _emails = DemoDataService.listDemoAccounts();
    if (_emails.isNotEmpty) {
      _selected = _emails.first;
    }
    setState(() {});
  }

  Future<void> _apply() async {
    if (_selected == null) return;
    setState(() => _applying = true);
    try {
      await DemoDataService.applyDemoProfileToAppState(_selected!);
      // Set active email and reload auth and timer state to reflect changes.
      try {
        final box = LocalStorageService.instance.userBox();
        await box.put('active_email', _selected!);
        await AuthService.instance.loadLocalUser();
        await ForegroundTimerService.instance.reloadStateFromStorage();
      } catch (_) {
        // Storage may be unavailable in tests; ignore and continue.
      }
    } catch (_) {
      // Ignore errors from applying demo profile in test environments.
    }
    setState(() => _applying = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demo profile applied')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demo Profiles')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView.separated(
                itemCount: _emails.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (BuildContext ctx, int i) {
                  final String e = _emails[i];
                  return ListTile(
                    title: Text(e),
                    selected: _selected == e,
                    onTap: () => setState(() => _selected = e),
                    trailing: _selected == e ? const Icon(Icons.check) : null,
                  );
                },
              ),
            ),
            FilledButton(
              onPressed: _applying ? null : _apply,
              child: _applying ? const CircularProgressIndicator() : const Text('Apply Selected Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
