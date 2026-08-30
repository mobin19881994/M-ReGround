import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_reground/core/services/foreground_timer_service.dart';
import 'package:m_reground/core/services/local_storage_service.dart';
import 'package:m_reground/core/services/logger_service.dart';
import 'package:m_reground/core/models/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final dir = await Directory.systemTemp.createTemp('m_reground_test');
    await LocalStorageService.instance.initialize(dir: dir.path);
    await LoggerService.instance.initialize(logsDir: dir.path);
  });

  test('quota hit opens task gate and level resolves', () async {
    final ForegroundTimerService timer = ForegroundTimerService.instance;

    // Seed a state where remainingSeconds is 0 and usage high enough for level 4
    final AppStateModel state = AppStateModel(
      installDate: DateTime.now().subtract(const Duration(days: 10)),
      remainingSeconds: 0,
      dailyUsageMinutes: 130,
      activeTargetApp: 'instagram',
      overlayPosition: const Offset(20, 50),
      emergencyBypassCount: 0,
      lastBypassDate: null,
    );

    await LocalStorageService.instance.saveAppState(state);

    // Reload service state and evaluate gate
    await timer.reloadStateFromStorage();
    await timer.evaluateGateFromState();

    expect(timer.needsBreakTask, true);
    expect(timer.currentLevel.name, 'level4');
  }, timeout: const Timeout(Duration(seconds: 10)));
}
