import 'dart:async';

import 'package:flutter/material.dart';
import 'package:m_reground/config/app_config.dart';
import 'package:m_reground/core/services/auth_service.dart';
import 'package:m_reground/core/services/local_storage_service.dart';
import 'package:m_reground/core/models/app_state.dart';
import 'package:m_reground/core/models/task_model.dart';

import 'analytics_service.dart';
import 'logger_service.dart';
import 'task_engine_service.dart';

class ForegroundTimerService extends ChangeNotifier {
  ForegroundTimerService._();

  static final ForegroundTimerService instance = ForegroundTimerService._();

  Timer? _ticker;
  AppStateModel _state = AppStateModel.initial();
  String _simulatedForegroundApp = 'other';
  bool _isLifecyclePaused = false;
  bool _taskGateOpen = false;

  bool _isLevel4Locked = false;
  int level4CooldownSeconds = 45;

  bool get isLevel4Locked {
    try {
      final bool demoIgnore = LocalStorageService.instance.userBox().get('demo_ignore_locks') == true;
      final bool isDemoUser = AuthService.instance.currentUser?.isDemo == true;
      if (demoIgnore && isDemoUser) {
        return false;
      }
    } catch (_) {}
    return _isLevel4Locked;
  }

  AppStateModel get state => _state;
  bool get hasActiveQuota => _state.remainingSeconds > 0;
  bool get needsBreakTask => _taskGateOpen;
  String get simulatedForegroundApp => _simulatedForegroundApp;

  TaskLevel get currentLevel => TaskEngineService.instance.resolveLevel(
        totalUsageMinutesToday: _state.dailyUsageMinutes,
        installDate: _state.installDate,
      );

  Future<void> initialize() async {
    _state = LocalStorageService.instance.readAppState();
    _rollBypassCounterIfNeeded();
    _ticker = Timer.periodic(const Duration(seconds: 1), _onTick);
    await LoggerService.instance.log('foreground_timer_initialized');
    notifyListeners();
  }

  /// Reload state from local storage (useful for demo/test flows that write
  /// app state directly to storage and want the running service to reflect it).
  Future<void> reloadStateFromStorage() async {
    _state = LocalStorageService.instance.readAppState();
    _rollBypassCounterIfNeeded();
    notifyListeners();
  }

  Future<void> disposeService() async {
    _ticker?.cancel();
    await _persist();
  }

  void setLifecyclePaused(bool value) {
    _isLifecyclePaused = value;
    notifyListeners();
  }

  void setForegroundApp(String appId) {
    _simulatedForegroundApp = appId.toLowerCase();
    notifyListeners();
  }

  Future<void> startAllowance({required String targetApp, required int minutes}) async {
    final int safeMinutes = minutes.clamp(1, AppConfig.maxContinuousLimitMinutes);
    _state = _state.copyWith(
      activeTargetApp: targetApp.toLowerCase(),
      remainingSeconds: safeMinutes * 60,
    );
    _taskGateOpen = false;
    await _persist();
    await LoggerService.instance.log('allowance_started app=$targetApp minutes=$safeMinutes');
    notifyListeners();
  }

  Future<bool> useEmergencyBypass() async {
    _rollBypassCounterIfNeeded();
    if (_state.emergencyBypassCount >= AppConfig.emergencyBypassLimitPerDay) {
      return false;
    }

    _state = _state.copyWith(
      remainingSeconds: AppConfig.emergencyBypassDurationMinutes * 60,
      emergencyBypassCount: _state.emergencyBypassCount + 1,
      lastBypassDate: DateTime.now(),
    );
    await _persist();
    await AnalyticsService.instance.logEvent('emergency_bypass_used', <String, Object>{
      'count_today': _state.emergencyBypassCount,
    });
    notifyListeners();
    return true;
  }

  Future<void> completeTaskAndResetToLevel1() async {
    if (isLevel4Locked) {
      return;
    }
    _taskGateOpen = false;
    _state = _state.copyWith(remainingSeconds: 0);
    // Reset usage so the user falls back to Level 1 after completing a task.
    _state = _state.copyWith(dailyUsageMinutes: 0);
    // If there was a level-4 lock, clear it now.
    _isLevel4Locked = false;
    await _persist();
    notifyListeners();
  }

  Future<void> setOverlayPosition(Offset offset) async {
    _state = _state.copyWith(overlayPosition: offset);
    await _persist();
    notifyListeners();
  }

  bool get shouldCount {
    final String? target = _state.activeTargetApp;
    if (target == null || target.isEmpty) {
      return false;
    }
    if (_isLifecyclePaused) {
      return false;
    }
    if (_taskGateOpen) {
      return false;
    }
    return _simulatedForegroundApp == target;
  }

  Future<void> _onTick(Timer timer) async {
    try {
      if (_isLevel4Locked) {
        level4CooldownSeconds -= 1;
        if (level4CooldownSeconds <= 0) {
          _isLevel4Locked = false;
          level4CooldownSeconds = 45;
        }
        notifyListeners();
      }

      if (!shouldCount) {
        return;
      }
      if (_state.remainingSeconds <= 0) {
        return;
      }

      final int nextRemaining = _state.remainingSeconds - 1;
      final int usageIncrement = nextRemaining % 60 == 0 ? 1 : 0;
      _state = _state.copyWith(
        remainingSeconds: nextRemaining,
        dailyUsageMinutes: _state.dailyUsageMinutes + usageIncrement,
      );

      if (nextRemaining <= 0) {
        _taskGateOpen = true;
        await AnalyticsService.instance.logFailureEvent(
          'app_failure_event',
          reason: 'quota_hit_zero',
        );

        if (currentLevel == TaskLevel.level4) {
          _isLevel4Locked = true;
          level4CooldownSeconds = 45;
          await AnalyticsService.instance.logEvent('high_usage_alert_triggered');
        }
      }

      await _persist();
      notifyListeners();
    } catch (e, st) {
      await AnalyticsService.instance.recordError(e, st, context: 'foreground_timer_tick');
    }
  }

  /// Public helper to evaluate the current stored state and open the task gate
  /// if the remaining seconds are zero or less. Useful for tests and for
  /// code paths that mutate storage externally and want the service to react.
  Future<void> evaluateGateFromState() async {
    try {
      if (_state.remainingSeconds <= 0) {
        _taskGateOpen = true;

        if (currentLevel == TaskLevel.level4) {
          _isLevel4Locked = true;
          level4CooldownSeconds = 45;
          await AnalyticsService.instance.logEvent('high_usage_alert_triggered');
        }
        await _persist();
        notifyListeners();
      }
    } catch (e, st) {
      await AnalyticsService.instance.recordError(e, st, context: 'evaluate_gate');
    }
  }

  void _rollBypassCounterIfNeeded() {
    final DateTime now = DateTime.now();
    final DateTime? last = _state.lastBypassDate;
    if (last == null || !_isSameDay(last, now)) {
      _state = _state.copyWith(
        emergencyBypassCount: 0,
        lastBypassDate: now,
      );
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _persist() async {
    await LocalStorageService.instance.saveAppState(_state);
  }

  String formatRemaining() {
    final int total = _state.remainingSeconds.clamp(0, 999999);
    final int min = total ~/ 60;
    final int sec = total % 60;
    return '${min.toString().padLeft(2, '0')}m ${sec.toString().padLeft(2, '0')}s';
  }
}
