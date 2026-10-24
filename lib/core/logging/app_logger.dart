import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Severity levels for [AppLogger], mapped to `dart:developer` log levels.
enum LogLevel {
  debug(500),
  info(800),
  warning(900),
  error(1000)
  ;

  const LogLevel(this.value);

  /// The numeric level understood by `dart:developer`'s `log`.
  final int value;
}

/// Lightweight logging facade used across the app.
///
/// Wraps `dart:developer`'s `log` so the codebase never calls `print` or
/// `debugPrint` directly. Debug and info messages are dropped in release
/// builds; warnings and errors are always emitted. Messages are plain text
/// (no emoji) so logs stay grep-friendly.
abstract final class AppLogger {
  const AppLogger._();

  /// Verbose diagnostic detail. Dropped in release builds.
  static void debug(String message, {String? name}) =>
      _log(LogLevel.debug, message, name: name);

  /// Routine informational message. Dropped in release builds.
  static void info(String message, {String? name}) =>
      _log(LogLevel.info, message, name: name);

  /// A recoverable problem worth surfacing. Emitted in all build modes.
  static void warning(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? name,
  }) => _log(
    LogLevel.warning,
    message,
    error: error,
    stackTrace: stackTrace,
    name: name,
  );

  /// A failure. Emitted in all build modes.
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? name,
  }) => _log(
    LogLevel.error,
    message,
    error: error,
    stackTrace: stackTrace,
    name: name,
  );

  static void _log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? name,
  }) {
    // Keep release logs quiet: only warnings and errors survive.
    if (kReleaseMode && level.value < LogLevel.warning.value) return;
    developer.log(
      message,
      level: level.value,
      name: name ?? 'strivo',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
