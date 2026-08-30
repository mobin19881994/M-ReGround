import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:m_reground/config/app_config.dart';

import 'analytics_service.dart';
import 'local_storage_service.dart';
import 'logger_service.dart';

class AuthUser {
  AuthUser({required this.email, required this.isAdmin, required this.isDemo});

  final String email;
  final bool isAdmin;
  final bool isDemo;
}

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  static const String _emailKey = 'active_email';
  static const String _pendingEmailKey = 'pending_email_for_otp';

  AuthUser? _current;
  bool _googleInitialized = false;

  AuthUser? get currentUser => _current;

  Future<void> loadLocalUser() async {
    final dynamic emailRaw = LocalStorageService.instance.userBox().get(_emailKey);
    if (emailRaw is String && emailRaw.isNotEmpty) {
      _current = _fromEmail(emailRaw);
    }
  }

  Future<void> signOut() async {
    _current = null;
    await LocalStorageService.instance.userBox().delete(_emailKey);
    try {
      await FirebaseAuth.instance.signOut();
      if (_googleInitialized) {
        await GoogleSignIn.instance.signOut();
      }
    } catch (_) {}
  }

  Future<AuthUser?> requestEmailOtpOrBypass(String email) async {
    final String normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) {
      throw ArgumentError('Email is required');
    }

    final bool bypassAccount =
        normalized == AppConfig.adminEmail || normalized == AppConfig.demoCustomerEmail;
    final bool releaseBypassAllowed = AppConfig.allowBypassInRelease || !kReleaseMode;
    final bool isBypass = bypassAccount && releaseBypassAllowed;

    if (isBypass) {
      final AuthUser user = _fromEmail(normalized);
      _current = user;
      await LocalStorageService.instance.userBox().put(_emailKey, user.email);
      await AnalyticsService.instance.logEvent('auth_sign_in', <String, Object>{
        'method': 'email_bypass',
        'is_admin': user.isAdmin,
      });
      return user;
    }

    if (AppConfig.useLocalOnlyPersistence) {
      // Simulate sending an email sign-in link when Firebase is disabled.
      await LocalStorageService.instance.userBox().put(_pendingEmailKey, normalized);
      await LoggerService.instance.log('otp_link_simulated_local_only');
      await AnalyticsService.instance.logEvent('auth_otp_link_simulated', <String, Object>{
        'method': 'email_link_local',
      });
      return null;
    }

    if (kReleaseMode && AppConfig.hasPlaceholderEmailLinkConfig) {
      throw StateError(
        'Release auth is not configured. Provide MREGROUND_EMAIL_LINK_URL, '
        'MREGROUND_ANDROID_PACKAGE, and MREGROUND_IOS_BUNDLE_ID via --dart-define.',
      );
    }

    await FirebaseAuth.instance.sendSignInLinkToEmail(
      email: normalized,
      actionCodeSettings: ActionCodeSettings(
        url: AppConfig.emailLinkSignInUrl,
        handleCodeInApp: true,
        androidPackageName: AppConfig.androidPackageName,
        androidInstallApp: true,
        iOSBundleId: AppConfig.iosBundleId,
      ),
    );
    await LocalStorageService.instance.userBox().put(_pendingEmailKey, normalized);
    await LoggerService.instance.log('otp_link_sent');
    await AnalyticsService.instance.logEvent('auth_otp_link_sent', <String, Object>{
      'method': 'email_link',
    });
    return null;
  }

  Future<AuthUser> completeEmailOtpSignIn({required String emailLink}) async {
    final dynamic pending = LocalStorageService.instance.userBox().get(_pendingEmailKey);
    if (pending is! String || pending.isEmpty) {
      throw StateError('No pending email found. Send OTP link first.');
    }
    final String normalized = pending.toLowerCase();
    // When running local-only (no Firebase), accept the pending email as
    // verified so demo flows can continue without an external backend.
    if (AppConfig.useLocalOnlyPersistence) {
      final String resolvedEmail = normalized;
      final AuthUser user = _fromEmail(resolvedEmail);
      _current = user;
      await LocalStorageService.instance.userBox().put(_emailKey, user.email);
      await LocalStorageService.instance.userBox().delete(_pendingEmailKey);
      await AnalyticsService.instance.logEvent('auth_sign_in', <String, Object>{
        'method': 'email_otp_local',
        'is_admin': user.isAdmin,
      });
      return user;
    }

    if (!FirebaseAuth.instance.isSignInWithEmailLink(emailLink)) {
      throw ArgumentError('Invalid or expired sign-in link.');
    }

    final UserCredential credential = await FirebaseAuth.instance.signInWithEmailLink(
      email: normalized,
      emailLink: emailLink,
    );

    final String resolvedEmail = credential.user?.email?.toLowerCase() ?? normalized;
    final AuthUser user = _fromEmail(resolvedEmail);
    _current = user;
    await LocalStorageService.instance.userBox().put(_emailKey, user.email);
    await LocalStorageService.instance.userBox().delete(_pendingEmailKey);
    await AnalyticsService.instance.logEvent('auth_sign_in', <String, Object>{
      'method': 'email_otp_link',
      'is_admin': user.isAdmin,
    });
    return user;
  }

  Future<AuthUser> signInWithGoogle() async {
    if (AppConfig.useLocalOnlyPersistence) {
      final AuthUser user = _fromEmail(AppConfig.demoCustomerEmail);
      _current = user;
      await LocalStorageService.instance.userBox().put(_emailKey, user.email);
      return user;
    }

    if (kIsWeb) {
      final UserCredential cred = await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
      final String email = cred.user?.email ?? 'unknown@google.com';
      final AuthUser user = _fromEmail(email);
      _current = user;
      await LocalStorageService.instance.userBox().put(_emailKey, user.email);
      return user;
    }

    if (!_googleInitialized) {
      await GoogleSignIn.instance.initialize();
      _googleInitialized = true;
    }

    final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    final String email = userCredential.user?.email ?? googleUser.email;
    final AuthUser user = _fromEmail(email);
    _current = user;
    await LocalStorageService.instance.userBox().put(_emailKey, user.email);
    return user;
  }

  AuthUser _fromEmail(String email) {
    final String normalized = email.trim().toLowerCase();
    return AuthUser(
      email: normalized,
      isAdmin: normalized == AppConfig.adminEmail,
      isDemo: normalized == AppConfig.demoCustomerEmail,
    );
  }
}
