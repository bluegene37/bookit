// Gene - Nov 07, 2026: Structured error telemetry logger replacing silent catch blocks across repositories and services
import 'package:flutter/foundation.dart';

class AppErrorEvent {
  final String service;
  final String operation;
  final Object error;
  final StackTrace? stackTrace;
  final DateTime timestamp;

  const AppErrorEvent({
    required this.service,
    required this.operation,
    required this.error,
    this.stackTrace,
    required this.timestamp,
  });

  @override
  String toString() => '[$service.$operation] $error (${timestamp.toIso8601String()})';
}

class AppErrorLogger {
  AppErrorLogger._();

  static final List<AppErrorEvent> _events = [];
  static const int defaultMaxBufferSize = 100;

  static List<AppErrorEvent> get recentEvents => List.unmodifiable(_events);

  static void report({
    required String service,
    required String operation,
    required Object error,
    StackTrace? stackTrace,
    int maxBufferSize = defaultMaxBufferSize,
    bool logToConsole = false,
  }) {
    final event = AppErrorEvent(
      service: service,
      operation: operation,
      error: error,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
    );

    _events.insert(0, event);
    if (_events.length > maxBufferSize) {
      _events.removeRange(maxBufferSize, _events.length);
    }

    if (logToConsole && kDebugMode) {
      debugPrint(event.toString());
    }
  }

  static void clear() {
    _events.clear();
  }
}
