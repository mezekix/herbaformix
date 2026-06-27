/// Merkezi loglama yardımcısı — tüm `debugPrint` çağrılarının yerine geçer.
///
/// **Tasarım kararları:**
/// - Release build'de hiçbir log basılmaz (`kDebugMode` kontrolü).
/// - PII (e-posta, uid, telefon) içeren loglar yanlışlıkla production'a sızamaz.
/// - Severity seviyeleri ile log türleri ayrılır (debug, info, warning, error).
/// - Pure function'lar, yan etkisi yok — test edilebilir.
///
/// **Kullanım:**
/// ```dart
/// import 'package:herbaformix/core/logger.dart';
///
/// AppLogger.debug('Veri yüklendi', tag: 'CustomerRepo');
/// AppLogger.info('Profil güncellendi');
/// AppLogger.warning('Timeout, offline buffer\'a yazıldı');
/// AppLogger.error('Firestore yazma hatası', error: e, stackTrace: s);
/// ```
///
/// **Migrasyon:**
/// Eski: `debugPrint('Bir şey oldu: $value');`
/// Yeni: `AppLogger.debug('Bir şey oldu: $value', tag: 'DosyaAdı');`
library;

import 'package:flutter/foundation.dart';

/// Log seviyesi — filtreleme ve formatlama için.
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Merkezi logger. Release build'de tüm loglar susturulur.
///
/// Her metot statik — instance oluşturmaya gerek yok.
/// Tag parametresi opsiyonel; verilirse `[TAG]` prefix'i eklenir,
/// böylece hangi dosya/sınıftan geldiği hemen anlaşılır.
class AppLogger {
  AppLogger._();

  /// Test'lerde logları yakalamak için override edilebilir callback.
  /// Null ise standart `debugPrint` kullanılır.
  /// Production'da dokunulmaz — yalnızca test amaçlı.
  @visibleForTesting
  static void Function(String message)? testLogCallback;

  // ── Public API ──────────────────────────────────────────────────────────

  /// Geliştirici detayları — sadece debug build'de.
  static void debug(String message, {String? tag}) {
    _log(LogLevel.debug, message, tag: tag);
  }

  /// Bilgilendirme — akış takibi (ör. "Profil yüklendi").
  static void info(String message, {String? tag}) {
    _log(LogLevel.info, message, tag: tag);
  }

  /// Uyarı — beklenmeyen ama kurtarılabilir durum.
  static void warning(String message, {String? tag, Object? error}) {
    _log(LogLevel.warning, message, tag: tag, error: error);
  }

  /// Hata — catch bloklarında kullan.
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.error,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  // ── Internal ────────────────────────────────────────────────────────────

  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    // 🔒 Release build'de hiçbir log basılmaz.
    if (!kDebugMode) return;

    final buffer = StringBuffer();
    buffer.write(_levelPrefix(level));
    if (tag != null) {
      buffer.write('[$tag] ');
    }
    buffer.write(message);

    if (error != null) {
      buffer.write(' | error: $error');
    }

    final formatted = buffer.toString();

    if (testLogCallback != null) {
      testLogCallback!(formatted);
    } else {
      debugPrint(formatted);
    }

    if (stackTrace != null) {
      if (testLogCallback != null) {
        testLogCallback!(stackTrace.toString());
      } else {
        debugPrint(stackTrace.toString());
      }
    }
  }

  static String _levelPrefix(LogLevel level) {
    return switch (level) {
      LogLevel.debug => '🐛 ',
      LogLevel.info => 'ℹ️ ',
      LogLevel.warning => '⚠️ ',
      LogLevel.error => '🔴 ',
    };
  }
}
