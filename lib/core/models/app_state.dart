import 'package:flutter/material.dart';

class AppStateModel {
  AppStateModel({
    required this.installDate,
    required this.remainingSeconds,
    required this.dailyUsageMinutes,
    required this.activeTargetApp,
    required this.overlayPosition,
    required this.emergencyBypassCount,
    required this.lastBypassDate,
  });

  final DateTime installDate;
  final int remainingSeconds;
  final int dailyUsageMinutes;
  final String? activeTargetApp;
  final Offset overlayPosition;
  final int emergencyBypassCount;
  final DateTime? lastBypassDate;

  AppStateModel copyWith({
    DateTime? installDate,
    int? remainingSeconds,
    int? dailyUsageMinutes,
    String? activeTargetApp,
    Offset? overlayPosition,
    int? emergencyBypassCount,
    DateTime? lastBypassDate,
  }) {
    return AppStateModel(
      installDate: installDate ?? this.installDate,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      dailyUsageMinutes: dailyUsageMinutes ?? this.dailyUsageMinutes,
      activeTargetApp: activeTargetApp ?? this.activeTargetApp,
      overlayPosition: overlayPosition ?? this.overlayPosition,
      emergencyBypassCount: emergencyBypassCount ?? this.emergencyBypassCount,
      lastBypassDate: lastBypassDate ?? this.lastBypassDate,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'installDate': installDate.toIso8601String(),
      'remainingSeconds': remainingSeconds,
      'dailyUsageMinutes': dailyUsageMinutes,
      'activeTargetApp': activeTargetApp,
      'overlayX': overlayPosition.dx,
      'overlayY': overlayPosition.dy,
      'emergencyBypassCount': emergencyBypassCount,
      'lastBypassDate': lastBypassDate?.toIso8601String(),
    };
  }

  factory AppStateModel.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) {
      return AppStateModel.initial();
    }
    return AppStateModel(
      installDate: DateTime.tryParse((map['installDate'] as String?) ?? '') ?? DateTime.now(),
      remainingSeconds: (map['remainingSeconds'] as int?) ?? 0,
      dailyUsageMinutes: (map['dailyUsageMinutes'] as int?) ?? 0,
      activeTargetApp: map['activeTargetApp'] as String?,
      overlayPosition: Offset(
        ((map['overlayX'] as num?) ?? 20).toDouble(),
        ((map['overlayY'] as num?) ?? 50).toDouble(),
      ),
      emergencyBypassCount: (map['emergencyBypassCount'] as int?) ?? 0,
      lastBypassDate: DateTime.tryParse((map['lastBypassDate'] as String?) ?? ''),
    );
  }

  factory AppStateModel.initial() {
    return AppStateModel(
      installDate: DateTime.now(),
      remainingSeconds: 0,
      dailyUsageMinutes: 0,
      activeTargetApp: null,
      overlayPosition: const Offset(20, 50),
      emergencyBypassCount: 0,
      lastBypassDate: null,
    );
  }
}
