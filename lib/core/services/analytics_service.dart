import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'logger_service.dart';

class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  FirebaseAnalytics? _analytics;
  FirebaseCrashlytics? _crashlytics;

  void bind({FirebaseAnalytics? analytics, FirebaseCrashlytics? crashlytics}) {
    _analytics = analytics;
    _crashlytics = crashlytics;
  }

  Future<void> logEvent(String name, [Map<String, Object> params = const {}]) async {
    try {
      await _analytics?.logEvent(name: name, parameters: params);
      await LoggerService.instance.log('analytics_event:$name params=$params');
    } catch (e, st) {
      await LoggerService.instance.log('analytics_event_failed:$name', error: e, stackTrace: st);
    }
  }

  Future<void> logFailureEvent(String name, {String? reason}) async {
    await logEvent(name, <String, Object>{'reason': reason ?? 'unknown'});
  }

  Future<void> recordError(Object error, StackTrace stackTrace, {String context = 'runtime'}) async {
    await LoggerService.instance.log('error_context:$context', error: error, stackTrace: stackTrace);
    try {
      await _crashlytics?.recordError(error, stackTrace, reason: context, fatal: false);
    } catch (e, st) {
      debugPrint('Crashlytics record failed: $e\n$st');
    }
  }
}
