import 'package:flutter/foundation.dart';
import '../errors/app_failure.dart';

enum LogLevel { info, warning, error }

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String module;
  final String message;
  final Object? error;

  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.module,
    required this.message,
    this.error,
  });
}

class AppLogger {
  static final List<LogEntry> _recentLogs = [];
  static const int _maxLogs = 200;

  static List<LogEntry> get recentLogs => List.unmodifiable(_recentLogs);

  static void info(String module, String message) {
    _record(LogLevel.info, module, message);
  }

  static void warn(String module, String message, [Object? error]) {
    _record(LogLevel.warning, module, message, error);
  }

  static void error(String module, String message, [Object? error]) {
    _record(LogLevel.error, module, message, error);
  }

  static void _record(LogLevel level, String module, String message, [Object? error]) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      module: module,
      message: message,
      error: error,
    );
    _recentLogs.add(entry);
    if (_recentLogs.length > _maxLogs) {
      _recentLogs.removeAt(0);
    }
    if (kDebugMode) {
      final errSuffix = error != null ? ' | Error: $error' : '';
      debugPrint('[${level.name.toUpperCase()}][$module] $message$errSuffix');
    }
  }

  /// Validates image file extension, data URI, and size (max 5 MB).
  static AppFailure? validateImagePath(String path, {int? byteLength}) {
    final lower = path.toLowerCase();
    final isDataUri = lower.startsWith('data:image/jpeg;base64,') ||
        lower.startsWith('data:image/png;base64,') ||
        lower.startsWith('data:image/webp;base64,');
    const allowedExts = ['.jpg', '.jpeg', '.png', '.webp'];
    final hasValidExt = isDataUri || allowedExts.any((ext) => lower.endsWith(ext));
    if (!hasValidExt) {
      return const AppFailure(
        'Unsupported image format. Only JPEG, PNG, and WebP photos are allowed.',
        code: 'INVALID_IMAGE_TYPE',
      );
    }
    if (byteLength != null && byteLength > 5 * 1024 * 1024) {
      return const AppFailure(
        'Photo exceeds the 5 MB maximum upload limit.',
        code: 'IMAGE_TOO_LARGE',
      );
    }
    return null;
  }

  /// Validates drop note text and tags before creation.
  static AppFailure? validateDropInput({required String note, required List<String> tags}) {
    final trimmed = note.trim();
    if (trimmed.isEmpty) {
      return const AppFailure('Please write a short recommendation note (1–500 characters).', code: 'EMPTY_NOTE');
    }
    if (trimmed.length > 500) {
      return const AppFailure('Drop note cannot exceed 500 characters.', code: 'NOTE_TOO_LONG');
    }
    if (tags.length > 10) {
      return const AppFailure('Maximum 10 descriptive tags allowed per drop.', code: 'TOO_MANY_TAGS');
    }
    return null;
  }
}
