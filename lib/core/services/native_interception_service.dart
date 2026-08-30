import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:m_reground/config/app_config.dart';

import 'analytics_service.dart';

class NativeInterceptionService {
  NativeInterceptionService._();

  static final NativeInterceptionService instance = NativeInterceptionService._();

  final MethodChannel _channel = const MethodChannel(AppConfig.nativeInterceptionChannel);

  Future<void> initialize() async {
    if (kIsWeb) {
      return;
    }

    try {
      await _channel.invokeMethod<void>('initializeInterception');
    } catch (e, st) {
      await AnalyticsService.instance.logFailureEvent('accessibility_service_crashed', reason: '$e');
      await AnalyticsService.instance.recordError(e, st, context: 'native_interception_initialize');
    }
  }

  Future<void> requestOverlayPermission() async {
    if (kIsWeb) {
      return;
    }

    try {
      await _channel.invokeMethod<void>('requestOverlayPermission');
    } catch (e, st) {
      await AnalyticsService.instance.logFailureEvent('overlay_permission_killed', reason: '$e');
      await AnalyticsService.instance.recordError(e, st, context: 'overlay_permission_request');
    }
  }
}
