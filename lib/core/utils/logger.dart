// Logger sınıfı - Uygulama genelinde log mesajlarını yönetir

import 'package:flutter/foundation.dart';

class Logger {
  final String tag;

  /// Logger örneği oluşturur.
  /// [tag] loglanan mesajların kategorize edilmesi için kullanılır.
  Logger(this.tag);

  /// Bilgi mesajı loglar.
  void i(String message) {
    _log('INFO', message);
  }

  /// Hata mesajı loglar.
  void e(String message) {
    _log('ERROR', message);
  }

  /// Uyarı mesajı loglar.
  void w(String message) {
    _log('WARNING', message);
  }

  /// Debug mesajı loglar.
  void d(String message) {
    _log('DEBUG', message);
  }

  /// Log mesajını formatlar ve yazdırır.
  /// Sadece Debug modunda çalışırken ve sadece hata mesajları için gösterilir.
  void _log(String level, String message) {
    if (kDebugMode && level == 'ERROR') {
      debugPrint('[$level] $tag: $message');
    }
    // Release modunda logları devre dışı bırakıldı
    // Burada ileride Firebase Crashlytics, Sentry vb servislere
    // hata logları gönderilebilir.
  }

  /// Statik yardımcı metotlar

  /// Genel amaçlı logger örneği
  static final Logger _general = Logger('App');

  /// Genel loglar için bir metot
  static void log(String message) {
    // Release modda log yazılmaması için boş bırakıldı
    if (kDebugMode) {
      _general.i(message);
    }
  }

  /// Genel hatalar için bir metot
  /// (Sadece bu metot debug modunda çalışır)
  static void error(String message) {
    if (kDebugMode) {
      _general.e(message);
    }
  }
}
