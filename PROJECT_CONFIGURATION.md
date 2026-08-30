# Project Configuration & Release Settings

This file documents required project configuration for building and releasing the M-ReGround Android app. Place any machine-specific secrets outside source control and follow the steps below.

## 1) Required files (create locally, do NOT commit)
- `android/key.properties` — release signing credentials (example at `android/key.properties.example`)
  - Contents:
    ```text
    storePassword=YOUR_STORE_PASSWORD
    keyPassword=YOUR_KEY_PASSWORD
    keyAlias=YOUR_KEY_ALIAS
    storeFile=keystore.jks
    ```
- `android/keystore.jks` — Java keystore file used to sign the release APK.
- `android/app/google-services.json` — Firebase Android config (if using Firebase analytics/auth). Place under `android/app/`.

## 2) Important `--dart-define` keys
Pass these at build time with `--dart-define=KEY=VALUE` (or set CI secrets accordingly):

- `MREGROUND_USE_LOCAL_ONLY` — true/false (default true). Set to `false` for production builds that use Firebase.
- `MREGROUND_ADMIN_EMAIL` — admin email address used by the app for admin bypass, e.g. `admin@example.com`.
- `MREGROUND_DEMO_EMAIL` — demo user email used for bypass in local runs.
- `MREGROUND_ALLOW_BYPASS_IN_RELEASE` — true/false to allow bypass behavior in release builds.
- `MREGROUND_EMAIL_LINK_URL` — URL used for email-link sign-in ending url (set for release).
- `MREGROUND_ANDROID_PACKAGE` — Android package name (should match `applicationId` in Gradle).
- `MREGROUND_IOS_BUNDLE_ID` — iOS bundle id (if building iOS release).

Example build command disabling local-only mode:
```bash
flutter build apk --release --dart-define=MREGROUND_USE_LOCAL_ONLY=false \
  --dart-define=MREGROUND_EMAIL_LINK_URL=https://your-auth.example/finishSignIn \
  --dart-define=MREGROUND_ANDROID_PACKAGE=com.yourorg.yourapp
```

## 3) Files to verify before release
- `pubspec.yaml` — update `version: x.y.z+buildNumber` so Android `versionName`/`versionCode` are correct.
- `android/app/build.gradle.kts` — ensure `applicationId`, `compileSdk`, `targetSdk`, and signing config are correct.
- `android/app/src/main/AndroidManifest.xml` — verify permissions and package name.
- `lib/config/app_config.dart` — review default values and confirm `useLocalOnlyPersistence` is set by `--dart-define` correctly.

## 4) Security notes
- Never commit `android/key.properties` or `keystore.jks`. Add them to `.gitignore` (examples below).
- For CI, provide the keystore and `key.properties` through secure secrets, and write them to `android/` at build time.

## 5) Recommended `.gitignore` entries
Add these lines to `.gitignore` (they are already added by this repo in many cases):

```
android/key.properties
android/keystore.jks
android/app/google-services.json
```

## 6) Quick checklist to produce a release APK
1. Generate a keystore if you don't have one:
   ```bash
   keytool -genkey -v -keystore android/keystore.jks -alias <your_alias> -keyalg RSA -keysize 2048 -validity 10000
   ```
2. Create `android/key.properties` with your passwords and `storeFile` path.
3. Place `google-services.json` at `android/app/` (if using Firebase) and provide any `--dart-define` values.
4. Build the APK:
   ```bash
   flutter build apk --release --dart-define=MREGROUND_USE_LOCAL_ONLY=false
   ```

## 7) CI snippet example (GitHub Actions)
Store `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS` as secrets. In the runner, decode and write files to `android/`, write `key.properties` and run `flutter build`.

If you want, I can add a ready-to-use GitHub Actions workflow that demonstrates secure keystore handling.
