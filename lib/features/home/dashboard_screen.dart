import 'dart:math';

import 'package:flutter/material.dart';
import 'package:m_reground/config/app_config.dart';
import 'package:m_reground/core/models/task_model.dart';
import 'package:m_reground/core/services/analytics_service.dart';
import 'package:m_reground/core/services/auth_service.dart';
import 'package:m_reground/core/services/foreground_timer_service.dart';
import 'package:m_reground/core/services/logger_service.dart';
import 'package:m_reground/core/services/task_engine_service.dart';
import 'package:m_reground/features/tasks/task_selection_overlay.dart';
import 'package:m_reground/widgets/demo_banner.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  final ForegroundTimerService _timer = ForegroundTimerService.instance;
  late int _selectedMinutes;
  String _selectedTargetApp = AppConfig.targetApps.first;

  bool _sensorPermissionDenied = false;
  bool _cameraPermissionDenied = false;
  double _ambientLux = 30;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer.addListener(_onTimerUpdate);
    final bool isDemoUser = AuthService.instance.currentUser?.isDemo ?? false;
    _selectedMinutes = AppConfig.defaultTimeSlotsForUser(isDemoUser: isDemoUser).first;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final bool paused = state == AppLifecycleState.inactive || state == AppLifecycleState.paused;
    _timer.setLifecyclePaused(paused);
  }

  void _onTimerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer.removeListener(_onTimerUpdate);
    super.dispose();
  }

  Future<void> _startAllowance() async {
    await _timer.startAllowance(targetApp: _selectedTargetApp, minutes: _selectedMinutes);
  }

  Future<void> _useBypass() async {
    final bool ok = await _timer.useEmergencyBypass();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Emergency bypass started for ${AppConfig.emergencyBypassDurationMinutes} minutes.'
            : 'Daily bypass limit reached.'),
      ),
    );
  }

  Future<void> _completeTask(BreakTask task) async {
    await LoggerService.instance.log('task_completed:${task.id}');
    await AnalyticsService.instance.logEvent('task_completed', <String, Object>{
      'task_id': task.id,
      'task_type': task.type.name,
      'task_level': task.level.name,
    });
    await _timer.completeTaskAndResetToLevel1();
  }

  @override
  Widget build(BuildContext context) {
    final TaskLevel level = _timer.currentLevel;
    final bool lowLight = _ambientLux < AppConfig.ambientLightThresholdLux;
    final bool isDemoUser = AuthService.instance.currentUser?.isDemo ?? false;

    final List<BreakTask> options = TaskEngineService.instance.choices(
      level: level,
      cameraAvailable: !_cameraPermissionDenied && AppConfig.enableCameraTasks,
      sensorAvailable: !_sensorPermissionDenied && AppConfig.enableSensorTasks,
      lowLight: lowLight,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('M-ReGround Dashboard'),
        actions: <Widget>[
          if (level == TaskLevel.level4)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  'High Usage Alert',
                  style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              DemoBanner(isDemo: isDemoUser),
              if (_timer.isLevel4Locked)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Cooldown active: ${_timer.level4CooldownSeconds}s before next reset task.'),
                ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text('Target App Session', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: AppConfig.targetApps
                            .map((String app) => ButtonSegment<String>(value: app, label: Text(app.toUpperCase())))
                            .toList(),
                        selected: <String>{_selectedTargetApp},
                        onSelectionChanged: (Set<String> selected) {
                          setState(() {
                            _selectedTargetApp = selected.first;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: AppConfig.defaultTimeSlotsForUser(isDemoUser: isDemoUser).map((int min) {
                          final bool selected = _selectedMinutes == min;
                          return ChoiceChip(
                            label: Text('${min}m'),
                            selected: selected,
                            onSelected: (_) => setState(() => _selectedMinutes = min),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                      FilledButton(onPressed: _startAllowance, child: const Text('Start Focus Allowance')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text('Foreground Monitor (Simulation)', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: const <ButtonSegment<String>>[
                          ButtonSegment<String>(value: 'instagram', label: Text('Instagram')),
                          ButtonSegment<String>(value: 'youtube', label: Text('YouTube')),
                          ButtonSegment<String>(value: 'other', label: Text('Other/Call/Lock')),
                        ],
                        selected: <String>{_timer.simulatedForegroundApp},
                        onSelectionChanged: (Set<String> selected) => _timer.setForegroundApp(selected.first),
                      ),
                      const SizedBox(height: 8),
                      Text('Timer status: ${_timer.shouldCount ? 'Running' : 'Paused'}'),
                      Text('Remaining: ${_timer.formatRemaining()}'),
                      Text('Today usage: ${_timer.state.dailyUsageMinutes} minutes'),
                      Text('Current level: ${level.name}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text('Permissions & Light Fail-safe', style: TextStyle(fontWeight: FontWeight.w700)),
                      SwitchListTile(
                        value: _cameraPermissionDenied,
                        onChanged: (bool v) => setState(() => _cameraPermissionDenied = v),
                        title: const Text('Camera permission denied'),
                      ),
                      SwitchListTile(
                        value: _sensorPermissionDenied,
                        onChanged: (bool v) => setState(() => _sensorPermissionDenied = v),
                        title: const Text('Sensor permission denied'),
                      ),
                      Text('Ambient lux: ${_ambientLux.toStringAsFixed(1)}'),
                      Slider(
                        min: 0,
                        max: 100,
                        value: _ambientLux,
                        onChanged: (double v) => setState(() => _ambientLux = v),
                      ),
                      Text(
                        lowLight
                            ? 'Low light detected (< ${AppConfig.ambientLightThresholdLux} lux): non-camera options prioritized.'
                            : 'Light is sufficient for camera tasks.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.tonal(onPressed: _useBypass, child: const Text('Use Emergency Bypass')),
            ],
          ),
          if (AppConfig.enableFloatingTimerOverlay && _timer.hasActiveQuota)
            _FloatingOverlay(
              label: _timer.formatRemaining(),
              initial: _timer.state.overlayPosition,
              opacity: AppConfig.overlayOpacity,
              onMoved: (Offset delta) {
                final double nextX = max(0, _timer.state.overlayPosition.dx + delta.dx);
                final double nextY = max(0, _timer.state.overlayPosition.dy + delta.dy);
                _timer.setOverlayPosition(Offset(nextX, nextY));
              },
            ),
          if (_timer.needsBreakTask)
            TaskSelectionOverlay(
              level: level,
              tasks: options,
              lowLight: lowLight,
              sensorPermissionDenied: _sensorPermissionDenied,
              cameraPermissionDenied: _cameraPermissionDenied,
              onTaskComplete: _completeTask,
            ),
        ],
      ),
    );
  }
}

class _FloatingOverlay extends StatelessWidget {
  const _FloatingOverlay({
    required this.label,
    required this.initial,
    required this.opacity,
    required this.onMoved,
  });

  final String label;
  final Offset initial;
  final double opacity;
  final ValueChanged<Offset> onMoved;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: initial.dy,
      left: initial.dx,
      child: GestureDetector(
        onPanUpdate: (DragUpdateDetails details) => onMoved(details.delta),
        child: Opacity(
          opacity: opacity,
          child: Material(
            borderRadius: BorderRadius.circular(30),
            color: Colors.black,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.timer, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
