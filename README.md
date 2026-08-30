# M-ReGround

M-ReGround is a cross-platform Flutter app (Android, iOS, Android TV, Web) designed to reduce social media overuse through:

- Active foreground usage allowance tracking (Instagram/YouTube target logic).
- Floating countdown mini-overlay with drag + persistence.
- Dual-choice break task interception with level-based adaptive friction.
- 100% local persistence (Hive) for app state and recovery continuity.
- 30-day app expiry guard.
- Runtime logging to sample_logs.txt (and web-safe storage fallback).
- Firebase Analytics + Crashlytics hooks (optional, fails gracefully if not configured).

## Key Requirement Files Implemented

- Central dynamic config: lib/config/app_config.dart
- Foreground timer + pause/resume + allowance persistence: lib/core/services/foreground_timer_service.dart
- Task engine and level matrix: lib/core/services/task_engine_service.dart
- Local logger and log viewer backend: lib/core/services/logger_service.dart
- Task selection overlay UI: lib/features/tasks/task_selection_overlay.dart
- Profile screen with logs + bypass tracker: lib/features/profile/profile_screen.dart
- Native interception bridge stubs: lib/core/services/native_interception_service.dart

## Platform Coverage

- Android: configured permissions, accessibility service declaration, overlay permission method channel stub.
- Android TV: leanback feature + launcher category included in AndroidManifest.
- iOS: method channel stub for Screen Time framework integration points, camera/motion usage descriptions added.
- Web: supported UI flow and local state persistence via Hive web backend.

## Important Notes

- Firebase is optional at runtime in this build. If Firebase configs are missing, app runs and logs the fallback.
- Email OTP now uses Firebase Email Link authentication flow.
- Admin and demo identities are configurable at build time via dart defines:
	- MREGROUND_ADMIN_EMAIL
	- MREGROUND_DEMO_EMAIL
- Foreground app detection is represented through an in-app simulation control. Native foreground app interception hooks are scaffolded and ready for full native implementation.

### Secure Build Defines Example

Use these during run/build so privileged identities are not hardcoded in source defaults:

	flutter run -d chrome --dart-define=MREGROUND_ADMIN_EMAIL=admin@yourdomain.com --dart-define=MREGROUND_DEMO_EMAIL=demo@yourdomain.com
	flutter build apk --dart-define=MREGROUND_ADMIN_EMAIL=admin@yourdomain.com --dart-define=MREGROUND_DEMO_EMAIL=demo@yourdomain.com

### Release Auth Defines (Required)

	--dart-define=MREGROUND_EMAIL_LINK_URL=https://auth.yourdomain.com/finishSignIn
	--dart-define=MREGROUND_ANDROID_PACKAGE=com.yourcompany.mreground
	--dart-define=MREGROUND_IOS_BUNDLE_ID=com.yourcompany.mreground

See full release steps in RELEASE_CHECKLIST.txt.

## Run Locally

1. Install Flutter SDK 3.44+.
2. In project root, run:

	flutter pub get

3. Run on device/emulator/browser:

	flutter run -d android
	flutter run -d ios
	flutter run -d chrome

4. Build release artifacts:

	flutter build apk
	flutter build appbundle
	flutter build ios
	flutter build web

## Production Hardening Next Steps

- Connect Firebase with platform config files (google-services.json, GoogleService-Info.plist, web options).
- Replace simulated foreground monitor with real Android UsageStats/Accessibility streams.
- Implement iOS Screen Time policy handlers via FamilyControls/DeviceActivity/ManagedSettings entitlements.
- Add real ML Kit camera task validators and sensor task verifiers.
