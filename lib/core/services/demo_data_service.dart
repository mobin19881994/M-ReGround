import 'package:m_reground/config/app_config.dart';
import 'package:m_reground/core/models/app_state.dart';
import 'package:m_reground/core/services/local_storage_service.dart';
import 'package:m_reground/core/services/logger_service.dart';

class DemoProfile {
  DemoProfile({required this.email, required this.dailyUsageMinutes, required this.remainingSeconds});

  final String email;
  final int dailyUsageMinutes;
  final int remainingSeconds;
}

class DemoDataService {
  DemoDataService._();

  static final DemoDataService instance = DemoDataService._();

  /// Seed default demo profiles when running in local-only mode.
  /// This writes a list of demo account emails to the `user_box` under
  /// the key `demo_accounts` and also writes a per-profile demo state at
  /// key `demo_state:<email>` to allow QA to inspect or switch states.
  static Future<void> seedIfNeeded() async {
    if (!AppConfig.useLocalOnlyPersistence) {
      return;
    }

    final box = LocalStorageService.instance.userBox();

    try {
      // Auto-seed when either the explicit flag is set or no demo accounts exist yet.
      final dynamic auto = box.get('demo_auto_seed');
      final dynamic existing = box.get('demo_accounts');
      final bool shouldSeed = (auto is bool && auto) || !(existing is List && existing.isNotEmpty);
      if (!shouldSeed) {
        return;
      }
    } catch (_) {
      // On any storage error, try to continue with seeding using the service APIs.
    }

    // Ensure at least the primary demo customer is present as active.
    final dynamic active = box.get('active_email');
    if (active is! String || active.isEmpty) {
      await box.put('active_email', AppConfig.demoCustomerEmail);
    }

    // Default demo profiles (can be expanded by tests or QA).
    final List<DemoProfile> defaults = <DemoProfile>[
      DemoProfile(email: AppConfig.demoCustomerEmail, dailyUsageMinutes: 10, remainingSeconds: 10 * 60),
      DemoProfile(email: 'demo.heavy@example.com', dailyUsageMinutes: 180, remainingSeconds: 0),
      DemoProfile(email: 'demo.light@example.com', dailyUsageMinutes: 2, remainingSeconds: 45 * 60),
      DemoProfile(email: AppConfig.adminEmail, dailyUsageMinutes: 5, remainingSeconds: 20 * 60),
    ];

    final List<String> emails = <String>[];
    for (final DemoProfile p in defaults) {
      emails.add(p.email);
      await _writeDemoStateForEmail(p.email, p.dailyUsageMinutes, p.remainingSeconds);
    }

    await box.put('demo_accounts', emails);
    await LoggerService.instance.log('demo_profiles_seeded', error: null, stackTrace: null);
  }

  /// Force-seed demo data now (callable from UI).
  static Future<void> seedNow() async {
    if (!AppConfig.useLocalOnlyPersistence) {
      return;
    }

    // Always perform seeding when explicitly requested.
    final box = LocalStorageService.instance.userBox();

    // Ensure active email points to demo customer if unset.
    final dynamic active = box.get('active_email');
    if (active is! String || active.isEmpty) {
      await box.put('active_email', AppConfig.demoCustomerEmail);
    }

    final List<DemoProfile> defaults = <DemoProfile>[
      DemoProfile(email: AppConfig.demoCustomerEmail, dailyUsageMinutes: 10, remainingSeconds: 10 * 60),
      DemoProfile(email: 'demo.heavy@example.com', dailyUsageMinutes: 180, remainingSeconds: 0),
      DemoProfile(email: 'demo.light@example.com', dailyUsageMinutes: 2, remainingSeconds: 45 * 60),
      DemoProfile(email: AppConfig.adminEmail, dailyUsageMinutes: 5, remainingSeconds: 20 * 60),
    ];

    final List<String> emails = <String>[];
    for (final DemoProfile p in defaults) {
      emails.add(p.email);
      await _writeDemoStateForEmail(p.email, p.dailyUsageMinutes, p.remainingSeconds);
    }

    await box.put('demo_accounts', emails);
    await LoggerService.instance.log('demo_profiles_seeded', error: null, stackTrace: null);
  }

  /// Clear demo accounts and demo states written by the seeder.
  static Future<void> clearDemoData() async {
    try {
      final box = LocalStorageService.instance.userBox();
      final dynamic raw = box.get('demo_accounts');
      if (raw is List) {
        for (final dynamic e in raw) {
          try {
            final String key = 'demo_state:${(e as String).toLowerCase()}';
            await box.delete(key);
          } catch (_) {}
        }
      }
      await box.delete('demo_accounts');
      final dynamic active = box.get('active_email');
      if (active is String && raw is List && raw.contains(active)) {
        await box.delete('active_email');
      }
      await LoggerService.instance.log('demo_profiles_cleared', error: null, stackTrace: null);
    } catch (_) {}
  }

  static List<String> listDemoAccounts() {
    try {
      final dynamic raw = LocalStorageService.instance.userBox().get('demo_accounts');
      if (raw is List) {
        return raw.cast<String>();
      }
    } catch (_) {}
    // Fallback defaults when storage is not available (tests / first-run).
    return <String>[AppConfig.demoCustomerEmail, AppConfig.adminEmail];
  }

  static Future<void> _writeDemoStateForEmail(String email, int dailyUsageMinutes, int remainingSeconds) async {
    final AppStateModel model = AppStateModel(
      installDate: DateTime.now().subtract(const Duration(days: 7)),
      remainingSeconds: remainingSeconds,
      dailyUsageMinutes: dailyUsageMinutes,
      activeTargetApp: AppConfig.targetApps.first,
      overlayPosition: AppConfig.floatingOverlayInitialPosition,
      emergencyBypassCount: 0,
      lastBypassDate: null,
    );
    final String key = 'demo_state:${email.toLowerCase()}';
    final box = LocalStorageService.instance.userBox();
    await box.put(key, model.toMap());
  }

  /// Replace the main app state with a demo profile's state.
  /// This is a helper QA function and does not run automatically.
  static Future<void> applyDemoProfileToAppState(String email) async {
    final box = LocalStorageService.instance.userBox();
    final String key = 'demo_state:${email.toLowerCase()}';
    final dynamic raw = box.get(key);
    if (raw is Map) {
      await LocalStorageService.instance.saveAppState(AppStateModel.fromMap(raw));
    }
  }
}
