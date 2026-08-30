import 'dart:ui';

/// Centralized runtime configuration for M-ReGround.
class AppConfig {
  const AppConfig._();

  // Auth & admin identities (prefer build-time defines for production).
  static const String adminEmail =
      String.fromEnvironment('MREGROUND_ADMIN_EMAIL', defaultValue: 'mobin.4488@gmail.com');
  static const String demoCustomerEmail =
      String.fromEnvironment('MREGROUND_DEMO_EMAIL', defaultValue: 'mobin.4499@gmail.com');

  // Version control and timeouts.
  static const int appExpiryDays = 30;
  static const int emergencyBypassLimitPerDay = 3;
  static const int emergencyBypassDurationMinutes = 2;
  // Include short slots globally to support quick testing and short sessions.
  static const List<int> defaultTimeSlotsInMinutes = [1, 2, 3, 5, 10, 15, 30, 60, 120];
  // Short slots useful for demo/testing users only.
  static const List<int> _demoShortTimeSlots = [1, 2, 3];

  /// Returns the effective default time slots for a user.
  /// When `isDemoUser` is true, includes short 1/2/3 minute slots for quick testing.
  static List<int> defaultTimeSlotsForUser({bool isDemoUser = false}) {
    if (isDemoUser) {
      return <int>[..._demoShortTimeSlots, ...defaultTimeSlotsInMinutes];
    }
    return defaultTimeSlotsInMinutes;
  }
  static const int maxContinuousLimitMinutes = 120;

  // Floating overlay settings.
  static const bool enableFloatingTimerOverlay = true;
  static const Offset floatingOverlayInitialPosition = Offset(20.0, 50.0);
  static const double overlayOpacity = 0.85;

  // Adaptive onboarding and task toggles.
  static const int gracePeriodDays = 3;
  static const bool enableCameraTasks = true;
  static const bool enableSensorTasks = true;
  static const double ambientLightThresholdLux = 10.0;

  // Task level thresholds.
  static const int level1MaxUsageMinutes = 30;
  static const int level2MaxUsageMinutes = 60;
  static const int level3MaxUsageMinutes = 90;
  static const int level4TriggerMinutes = 120;

  // Cost and deployment constraints.
  static const bool useLocalOnlyPersistence = bool.fromEnvironment(
    'MREGROUND_USE_LOCAL_ONLY',
    defaultValue: true,
  );
  static const bool enableFirebaseSparkTelemetry = true;
  static const int logRetentionDays = 14;

  // Keep the demo/admin shortcut enabled by default for local QA builds when the
  // external auth backend is not yet configured. It can still be overridden via
  // --dart-define=MREGROUND_ALLOW_BYPASS_IN_RELEASE=false for stricter production builds.
  static const bool allowBypassInRelease = bool.fromEnvironment(
    'MREGROUND_ALLOW_BYPASS_IN_RELEASE',
    defaultValue: true,
  );

  // Email link auth configuration (set these through --dart-define in release).
  static const String emailLinkSignInUrl = String.fromEnvironment(
    'MREGROUND_EMAIL_LINK_URL',
    defaultValue: 'https://m-reground-auth.example/finishSignIn',
  );
  static const String androidPackageName =
      String.fromEnvironment('MREGROUND_ANDROID_PACKAGE', defaultValue: 'com.mreground.munloop');
  static const String iosBundleId =
      String.fromEnvironment('MREGROUND_IOS_BUNDLE_ID', defaultValue: 'com.mreground.munloop');

  static bool get hasPlaceholderEmailLinkConfig =>
      emailLinkSignInUrl.contains('example') ||
      androidPackageName == 'com.mreground.munloop' ||
      iosBundleId == 'com.mreground.munloop';

  // Native platform channels.
  static const String nativeInterceptionChannel = 'm_reground/native_interception';
  static const String nativeOverlayChannel = 'm_reground/native_overlay';

  static const List<String> targetApps = ['instagram', 'youtube'];
}
