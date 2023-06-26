import 'package:flutter/material.dart';

/// Severity of the logged [Event].
@immutable
class LogLevel {
  const LogLevel._(this.name, this.ordinal);

  static const fatal = LogLevel._('fatal', 5);
  static const error = LogLevel._('error', 4);
  static const warning = LogLevel._('warning', 3);
  static const info = LogLevel._('info', 2);
  static const debug = LogLevel._('debug', 1);

  final String name;
  final int ordinal;

  factory LogLevel.fromName(String name) {
    switch (name) {
      case 'fatal':
        return LogLevel.fatal;
      case 'error':
        return LogLevel.error;
      case 'warning':
        return LogLevel.warning;
      case 'info':
        return LogLevel.info;
    }
    return LogLevel.debug;
  }
}
