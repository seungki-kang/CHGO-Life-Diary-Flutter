import 'dart:convert';

import 'package:flutter/foundation.dart';

enum AppLogLevel { debug, info, warn, error, audit }

typedef LogSink = void Function(String message);

class AppLogger {
  AppLogger({
    AppLogLevel? minimumLevel,
    LogSink? sink,
    DateTime Function()? clock,
  })  : minimumLevel = minimumLevel ??
            (kDebugMode ? AppLogLevel.debug : AppLogLevel.info),
        _sink = sink ?? debugPrint,
        _clock = clock ?? DateTime.now;

  final AppLogLevel minimumLevel;
  final LogSink _sink;
  final DateTime Function() _clock;

  void debug(String event, [Map<String, Object?> metadata = const {}]) =>
      log(AppLogLevel.debug, event, metadata);

  void info(String event, [Map<String, Object?> metadata = const {}]) =>
      log(AppLogLevel.info, event, metadata);

  void warn(String event, [Map<String, Object?> metadata = const {}]) =>
      log(AppLogLevel.warn, event, metadata);

  void error(String event, [Map<String, Object?> metadata = const {}]) =>
      log(AppLogLevel.error, event, metadata);

  void audit(String event, [Map<String, Object?> metadata = const {}]) =>
      log(AppLogLevel.audit, event, metadata);

  void log(
    AppLogLevel level,
    String event,
    Map<String, Object?> metadata,
  ) {
    if (!_enabled(level)) return;
    final safeMetadata = <String, Object?>{};
    var droppedFields = 0;
    for (final entry in metadata.entries) {
      if (_allowedMetadataKeys.contains(entry.key) &&
          _isSafeScalar(entry.value)) {
        safeMetadata[entry.key] = entry.value;
      } else {
        droppedFields++;
      }
    }
    if (droppedFields > 0) safeMetadata['dropped_fields'] = droppedFields;
    _sink(jsonEncode({
      'timestamp': _clock().toUtc().toIso8601String(),
      'level': level.name.toUpperCase(),
      'event': _safeEvent(event),
      'metadata': safeMetadata,
    }));
  }

  bool _enabled(AppLogLevel level) {
    if (level == AppLogLevel.audit) return true;
    return level.index >= minimumLevel.index;
  }
}

const _allowedMetadataKeys = <String>{
  'entry_id',
  'question_id',
  'status',
  'operation',
  'source',
  'schema_version',
  'canonical_version',
  'database_version',
  'season_number',
  'session_number',
  'retry_count',
  'duration_ms',
  'error_code',
  'result_count',
};

bool _isSafeScalar(Object? value) =>
    value == null || value is String || value is num || value is bool;

String _safeEvent(String event) =>
    RegExp(r'^[a-z0-9_.-]{1,80}$').hasMatch(event) ? event : 'invalid_event';
