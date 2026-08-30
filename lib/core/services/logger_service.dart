import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:m_reground/config/app_config.dart';
import 'package:path_provider/path_provider.dart';

class LoggerService {
  LoggerService._();

  static final LoggerService instance = LoggerService._();

  static const String _logFileName = 'sample_logs.txt';
  static const String _logBox = 'runtime_logs_box';

  bool _initialized = false;
  String? _logsDir;

  /// Initialize the logger. When [logsDir] is provided (tests), file logs
  /// will be written under that directory instead of using
  /// `getApplicationDocumentsDirectory()` which requires platform plugins.
  Future<void> initialize({String? logsDir}) async {
    if (_initialized) {
      return;
    }
    _logsDir = logsDir;
    if (kIsWeb) {
      await Hive.openBox<String>(_logBox);
    }
    await _pruneOldLogs();
    _initialized = true;
  }

  Future<void> log(String message, {Object? error, StackTrace? stackTrace}) async {
    final String timestamp = DateTime.now().toIso8601String();
    final String errorPart = error == null ? '' : ' | error=$error';
    final String stackPart = stackTrace == null ? '' : ' | stack=$stackTrace';
    final String line = '[$timestamp] $message$errorPart$stackPart\n';

    try {
      if (kIsWeb) {
        final Box<String> box = Hive.box<String>(_logBox);
        final String existing = box.get(_logFileName, defaultValue: '') ?? '';
        final String pruned = _pruneRawLogContent('$existing$line');
        await box.put(_logFileName, pruned);
        return;
      }

      if (_logsDir != null) {
        final File file = File('${_logsDir!}/$_logFileName');
        await file.writeAsString(line, mode: FileMode.append, encoding: utf8);
        await _pruneOldLogs();
        return;
      }

      final Directory dir = await getApplicationDocumentsDirectory();
      final File file = File('${dir.path}/$_logFileName');
      await file.writeAsString(line, mode: FileMode.append, encoding: utf8);
      await _pruneOldLogs();
    } catch (e, st) {
      debugPrint('Logger write failed: $e\n$st');
    }
  }

  Future<String> readLogs() async {
    try {
      if (kIsWeb) {
        final Box<String> box = Hive.box<String>(_logBox);
        return box.get(_logFileName, defaultValue: '') ?? '';
      }

      final Directory dir = await getApplicationDocumentsDirectory();
      final File file = File('${dir.path}/$_logFileName');
      if (!await file.exists()) {
        return '';
      }
      return file.readAsString();
    } catch (e, st) {
      debugPrint('Logger read failed: $e\n$st');
      return '';
    }
  }

  Future<void> clearLogs() async {
    try {
      if (kIsWeb) {
        final Box<String> box = Hive.box<String>(_logBox);
        await box.put(_logFileName, '');
        return;
      }

      final Directory dir = await getApplicationDocumentsDirectory();
      final File file = File('${dir.path}/$_logFileName');
      if (await file.exists()) {
        await file.writeAsString('');
      }
    } catch (e, st) {
      debugPrint('Logger clear failed: $e\n$st');
    }
  }

  Future<void> _pruneOldLogs() async {
    try {
      if (kIsWeb) {
        final Box<String> box = Hive.box<String>(_logBox);
        final String existing = box.get(_logFileName, defaultValue: '') ?? '';
        await box.put(_logFileName, _pruneRawLogContent(existing));
        return;
      }

      if (_logsDir != null) {
        final File file = File('${_logsDir!}/$_logFileName');
        if (!await file.exists()) {
          return;
        }
        final String existing = await file.readAsString();
        final String pruned = _pruneRawLogContent(existing);
        if (pruned != existing) {
          await file.writeAsString(pruned, mode: FileMode.write, encoding: utf8);
        }
        return;
      }

      final Directory dir = await getApplicationDocumentsDirectory();
      final File file = File('${dir.path}/$_logFileName');
      if (!await file.exists()) {
        return;
      }
      final String existing = await file.readAsString();
      final String pruned = _pruneRawLogContent(existing);
      if (pruned != existing) {
        await file.writeAsString(pruned, mode: FileMode.write, encoding: utf8);
      }
    } catch (e, st) {
      debugPrint('Logger prune failed: $e\n$st');
    }
  }

  String _pruneRawLogContent(String content) {
    if (content.isEmpty) {
      return content;
    }

    final DateTime cutoff = DateTime.now().subtract(
      Duration(days: AppConfig.logRetentionDays),
    );
    final Iterable<String> lines = const LineSplitter().convert(content);
    final List<String> kept = <String>[];

    for (final String line in lines) {
      if (_shouldKeepLine(line, cutoff)) {
        kept.add(line);
      }
    }

    if (kept.isEmpty) {
      return '';
    }
    return '${kept.join('\n')}\n';
  }

  bool _shouldKeepLine(String line, DateTime cutoff) {
    if (!line.startsWith('[')) {
      return true;
    }
    final int endIndex = line.indexOf(']');
    if (endIndex <= 1) {
      return true;
    }

    final String stamp = line.substring(1, endIndex);
    final DateTime? parsed = DateTime.tryParse(stamp);
    if (parsed == null) {
      return true;
    }
    return parsed.isAfter(cutoff);
  }
}
