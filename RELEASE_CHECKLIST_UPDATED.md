# M-ReGround Release Checklist

## Pre-Release Requirements (All Verified ✅)

### Code Quality
- [x] Flutter analyze: 0 issues
- [x] All unit tests pass
- [x] All widget tests pass
- [x] Integration tests created and passing
- [x] Null safety enforced
- [x] No deprecated APIs (except intentional color API compatibility)

### Build Artifacts Ready
- [x] Web build: `build/web` (production-optimized)
- [x] Android APK: `build/app/outputs/flutter-apk/app-release.apk` (51.5 MB)
- [x] Android AAB: `build/app/outputs/bundle/release/app-release.aab` (52.1 MB)
- [x] All built with demo flags for QA

### Core Features Verified
- [x] Timer system (foreground tracking, pause on lifecycle change)
- [x] Task selection overlay (3 choices, Start/Complete flow)
- [x] Level resolution (1→4 based on usage)
- [x] Level 4 cooldown (45s lockout)
- [x] Demo data seeding
- [x] Local-only Hive persistence
- [x] Firebase optional (controlled by dart-define)
- [x] Floating overlay (draggable, position persisted)
- [x] Permission requests (camera, activity, overlay)
- [x] System logs (viewer + clear)
- [x] Emergency bypass tracker

---

## Release Steps (To Do)

### Phase 1: Android Play Store Release

#### Step 1: Keystore Setup
- [ ] Generate keystore (if not already created):
  ```bash
  keytool -genkey -v -keystore ~/upload-keystore.jks \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -alias upload
  ```
- [ ] Securely store keystore + password
- [ ] Create `android/key.properties` with credentials:
  ```properties
  storePassword=<password>
  keyPassword=<password>
  keyAlias=upload
  storeFile=<path-to-jks>
  ```

#### Step 2: App Metadata Preparation
- [ ] Create app description (short & long form)
- [ ] Write release notes for v1.0.0
- [ ] Prepare screenshots (3 minimum, 8 maximum per locale):
  - Dashboard with timer
  - Task selection overlay
  - Profile screen
- [ ] High-res app icon (512×512 PNG)
- [ ] Feature graphic (1024×500 PNG)
- [ ] Content rating questionnaire completed
- [ ] Privacy policy URL (required)
- [ ] Privacy form: Data safety disclosure

#### Step 3: Production Build
- [ ] Update `pubspec.yaml` version (e.g., `1.1.0+2`)
- [ ] Build signed AAB:
  ```bash
  flutter build appbundle --release \
    --dart-define=MREGROUND_USE_LOCAL_ONLY=false \
    --dart-define=MREGROUND_FULL_DEMO=false \
    --dart-define=MREGROUND_ALLOW_BYPASS_IN_RELEASE=false
  ```
- [ ] Output: `build/app/outputs/bundle/release/app-release.aab`

#### Step 4: Google Play Console
- [ ] Create app entry (or use existing)
- [ ] Upload AAB to Internal Testing track
- [ ] Add testers (internal team)
- [ ] Run internal tests for 7+ days
- [ ] Fix any reported issues
- [ ] Move to Closed Testing (beta) if desired
- [ ] Then Staged Rollout (5% → 25% → 100%)
- [ ] Monitor crashes + analytics
- [ ] Full rollout after validation

### Phase 2: iOS App Store Release (macOS Required)

#### Step 1: Apple Developer Setup
- [ ] Create App ID in Apple Developer Portal
- [ ] Configure Capabilities (Camera, Health Kit if needed)
- [ ] Create Provisioning Profile (App Store distribution)
- [ ] Create Distribution Certificate
- [ ] Download provisioning profile to Xcode

#### Step 2: Project Configuration
- [ ] Update bundle ID in `AppConfig.iosBundleId`
- [ ] Update version in `pubspec.yaml`
- [ ] Update build number (CFBundleVersion)
- [ ] Create `ios/ExportOptions.plist` for app signing

#### Step 3: Production Build & Archive
- [ ] Build IPA:
  ```bash
  flutter build ipa --release \
    --dart-define=MREGROUND_USE_LOCAL_ONLY=false \
    --dart-define=MREGROUND_FULL_DEMO=false \
    --dart-define=MREGROUND_ALLOW_BYPASS_IN_RELEASE=false
  ```
- [ ] Validate with Xcode (optional: `xcodebuild -validateOnly`)

#### Step 4: App Store Connect
- [ ] Upload IPA via Transporter or Xcode Organizer
- [ ] Fill out app details (same metadata as Android)
- [ ] Add release notes
- [ ] Submit for Review
- [ ] Apple review process (typically 1–3 days)
- [ ] Release after approval

### Phase 3: Web Release

#### Option A: GitHub Pages (Free)
- [ ] Enable GitHub Pages in repo settings
- [ ] Push `build/web` to gh-pages branch or /docs folder
- [ ] Access via `https://<username>.github.io/<repo>`

#### Option B: Firebase Hosting (Free tier available)
- [ ] Install Firebase CLI: `npm install -g firebase-tools`
- [ ] Initialize Firebase: `firebase init hosting`
- [ ] Configure public directory: `build/web`
- [ ] Deploy: `firebase deploy`

#### Option C: Netlify (Free tier available)
- [ ] Connect GitHub repo
- [ ] Set build command: `flutter build web --release`
- [ ] Set publish directory: `build/web`
- [ ] Deploy automatically on push

### Phase 4: Compliance & Legal

#### Privacy & Terms
- [ ] Privacy Policy:
  - Explain data collection (local storage only, optional Firebase)
  - Permission usage (camera, activity, overlay)
  - Third-party services (Firebase Crashlytics, Analytics)
  - GDPR/CCPA compliance statements
- [ ] Terms of Service (if applicable)
- [ ] Add privacy policy link to app + store listings

#### Content Rating
- [ ] Google Play: Complete IARC questionnaire
- [ ] App Store: Age rating (PEGI/ESRB equivalent)

#### Health & Wellness Claim (If Marketing As Such)
- [ ] Disclaimer: App is tool, not medical advice
- [ ] No claims to diagnose/treat/cure addiction
- [ ] Recommend consulting healthcare provider

### Phase 5: Monitoring & Analytics

#### Setup Dashboards
- [ ] Firebase Crashlytics: Enable crash notifications to admin email
- [ ] Firebase Analytics: Create custom events dashboard
- [ ] Google Play Console: Set up alerts for crash rate, ANR
- [ ] App Store Connect: Set up TestFlight feedback alerts

#### Post-Launch Monitoring
- [ ] Daily check: crash rate < 0.1%
- [ ] Weekly check: user retention metrics
- [ ] Monitor App Store / Play Store reviews
- [ ] Create feedback loop for top issues

### Phase 6: CI/CD Pipeline (Optional but Recommended)

#### GitHub Actions Workflow
- [ ] Create `.github/workflows/release.yml`:
  - Runs on tag push (v*.*.*)
  - Runs analyzer + tests
  - Runs SCA (dependency-check or similar)
  - Builds web, APK, AAB
  - Publishes artifacts to GitHub Releases
- [ ] Set up secrets (keystore, Firebase tokens if needed)
- [ ] Test workflow locally with `act`

#### Example Workflow Structure
```yaml
name: Release CI

on:
  push:
    tags:
      - 'v*.*.*'

jobs:
  test-and-build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - name: Run analyzer
        run: flutter analyze
      - name: Run tests
        run: flutter test --coverage
      - name: Build web
        run: flutter build web --release
      - name: Build APK
        run: flutter build apk --release
      - name: Build AAB
        run: flutter build appbundle --release
      - name: Upload artifacts
        uses: softprops/action-gh-release@v1
        with:
          files: |
            build/app/outputs/flutter-apk/app-release.apk
            build/app/outputs/bundle/release/app-release.aab
```

---

## Rollback & Hotfix Plan

### Android
- Publish new version with fix
- Staged rollout (5% first)
- Play Console allows canceling rollout if needed

### iOS
- App Store doesn't allow rollback
- Submit new version + expedited review
- Or keep previous version available as fallback

### Web
- Revert deploy to previous build (GitHub Pages / Firebase / Netlify all support this)

---

## Success Criteria

- [ ] 0 crashes in first week (Play Store + App Store)
- [ ] Avg session length ≥ 2 minutes
- [ ] Daily active users growing
- [ ] Avg app rating ≥ 4.0 stars
- [ ] No critical permission or privacy issues reported

---

## Launch Day Checklist

- [ ] All builds signed and tested
- [ ] Privacy policy live and linked
- [ ] Analytics dashboards active
- [ ] Crash reporting configured
- [ ] Support email configured
- [ ] Team notified of launch time
- [ ] Monitor first 24 hours for issues
- [ ] Post-launch blog/social media announcement

---

## Post-Launch (First 30 Days)

- [ ] Monitor crash reports daily
- [ ] Respond to user reviews
- [ ] Fix critical bugs (hotfix within 24-48h)
- [ ] Analyze analytics for user behavior
- [ ] Plan v1.1 features based on feedback
- [ ] Evaluate LTV (lifetime value) per install source

---

## Contact & Support

**Admin Email:** mobin.4488@gmail.com (receives crash reports)
**Demo Email:** mobin.4499@gmail.com (for QA)
**Support Email:** [to be configured]

---

**Document Version:** 1.0  
**Last Updated:** 2026-08-30  
**Status:** Ready for Release
