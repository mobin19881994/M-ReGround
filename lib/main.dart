import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:m_reground/app.dart';
import 'package:m_reground/core/services/analytics_service.dart';
import 'package:m_reground/core/services/foreground_timer_service.dart';
import 'package:m_reground/core/services/local_storage_service.dart';
import 'package:m_reground/core/services/logger_service.dart';
import 'package:m_reground/core/services/native_interception_service.dart';
import 'package:m_reground/core/services/demo_data_service.dart';
import 'package:m_reground/config/app_config.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalStorageService.instance.initialize();
  await LoggerService.instance.initialize();
  await _initializeFirebaseOptional();
  // Honor a test-only flag to force full-demo behavior in built APKs.
  // Use --dart-define=MREGROUND_FULL_DEMO=true when building to enable.
  const bool fullDemo = bool.fromEnvironment('MREGROUND_FULL_DEMO', defaultValue: false);
  if (fullDemo) {
    try {
      final box = LocalStorageService.instance.userBox();
      await box.put('demo_auto_seed', true);
      await box.put('demo_ignore_locks', true);
      await box.put('active_email', AppConfig.demoCustomerEmail);
      await LoggerService.instance.log('full_demo_mode_enabled');
    } catch (_) {}
  }

  // If Firebase is intentionally disabled (local-only), seed demo data
  // so QA/demo users can exercise full features offline.
  await DemoDataService.seedIfNeeded();
  // Request key runtime permissions to avoid users having to enable them manually.
  // This proactively asks for Camera and Activity Recognition where available
  // and requests overlay permission via the native handler.
  try {
    // Camera
    final PermissionStatus cameraStatus = await Permission.camera.request();
    if (cameraStatus.isPermanentlyDenied) {
      // Prompt user to open app settings so they can enable camera permission.
      await openAppSettings();
    }
    // Activity recognition (Android Q+)
    final PermissionStatus activityStatus = await Permission.activityRecognition.request();
    if (activityStatus.isPermanentlyDenied) {
      await openAppSettings();
    }
    // Request overlay via native bridge (platform-specific handling)
    await NativeInterceptionService.instance.requestOverlayPermission();
    await LoggerService.instance.log('requested_runtime_permissions');
  } catch (e, st) {
    await LoggerService.instance.log('permission_request_failed', error: e, stackTrace: st);
  }
  await NativeInterceptionService.instance.initialize();
  await ForegroundTimerService.instance.initialize();

  FlutterError.onError = (FlutterErrorDetails details) async {
    await AnalyticsService.instance.recordError(
      details.exception,
      details.stack ?? StackTrace.current,
      context: 'flutter_error',
    );
  };

  runApp(const MUnloopApp());
}

Future<void> _initializeFirebaseOptional() async {
  if (AppConfig.useLocalOnlyPersistence) {
    await LoggerService.instance.log('firebase_disabled_by_config');
    return;
  }

  try {
    final FirebaseApp app = await Firebase.initializeApp();
    AnalyticsService.instance.bind(
      analytics: FirebaseAnalytics.instanceFor(app: app),
      crashlytics: FirebaseCrashlytics.instance,
    );
    await LoggerService.instance.log('firebase_initialized');
  } catch (e, st) {
    await LoggerService.instance.log('firebase_init_skipped', error: e, stackTrace: st);
  }
}
