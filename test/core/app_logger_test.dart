// AppLogger — merkezi logger testleri.
//
// Doğrulamalar:
// - kDebugMode'da loglar basılır (test callback ile yakalanır)
// - Severity prefix'leri doğru eklenir
// - Tag prefix'i doğru eklenir
// - Error ve stackTrace varsa çıktıya eklenir
// - testLogCallback null ise debugPrint'e düşer (yan etki yok)

import 'package:flutter_test/flutter_test.dart';
import 'package:herbaformix/core/logger.dart';

void main() {
  // Her testten sonra callback'i temizle
  tearDown(() {
    AppLogger.testLogCallback = null;
  });

  group('AppLogger — severity prefix\'leri', () {
    test('debug → 🐛 prefix', () {
      String? captured;
      AppLogger.testLogCallback = (msg) => captured = msg;

      AppLogger.debug('test mesajı');

      expect(captured, contains('🐛'));
      expect(captured, contains('test mesajı'));
    });

    test('info → ℹ️ prefix', () {
      String? captured;
      AppLogger.testLogCallback = (msg) => captured = msg;

      AppLogger.info('bilgi mesajı');

      expect(captured, contains('ℹ️'));
      expect(captured, contains('bilgi mesajı'));
    });

    test('warning → ⚠️ prefix', () {
      String? captured;
      AppLogger.testLogCallback = (msg) => captured = msg;

      AppLogger.warning('uyarı mesajı');

      expect(captured, contains('⚠️'));
      expect(captured, contains('uyarı mesajı'));
    });

    test('error → 🔴 prefix', () {
      String? captured;
      AppLogger.testLogCallback = (msg) => captured = msg;

      AppLogger.error('hata mesajı');

      expect(captured, contains('🔴'));
      expect(captured, contains('hata mesajı'));
    });
  });

  group('AppLogger — tag desteği', () {
    test('tag verildiğinde [Tag] prefix eklenir', () {
      String? captured;
      AppLogger.testLogCallback = (msg) => captured = msg;

      AppLogger.debug('veri yüklendi', tag: 'CustomerRepo');

      expect(captured, contains('[CustomerRepo]'));
      expect(captured, contains('veri yüklendi'));
    });

    test('tag verilmediğinde [Tag] prefix yok', () {
      String? captured;
      AppLogger.testLogCallback = (msg) => captured = msg;

      AppLogger.debug('basit mesaj');

      expect(captured, isNot(contains('[')));
    });
  });

  group('AppLogger — error ve stackTrace', () {
    test('error nesnesi varsa çıktıya eklenir', () {
      String? captured;
      AppLogger.testLogCallback = (msg) => captured = msg;

      AppLogger.error('yazma hatası', error: Exception('timeout'));

      expect(captured, contains('error:'));
      expect(captured, contains('timeout'));
    });

    test('warning ile error nesnesi eklenir', () {
      String? captured;
      AppLogger.testLogCallback = (msg) => captured = msg;

      AppLogger.warning('yavaş yanıt', error: 'slow_response');

      expect(captured, contains('error: slow_response'));
    });

    test('stackTrace varsa ayrı satırda basılır', () {
      final logs = <String>[];
      AppLogger.testLogCallback = (msg) => logs.add(msg);

      final stack = StackTrace.current;
      AppLogger.error('kritik hata', error: 'boom', stackTrace: stack);

      expect(logs.length, 2, reason: 'mesaj + stackTrace = 2 çıktı');
      expect(logs[0], contains('kritik hata'));
      expect(logs[1], contains('main')); // stackTrace içinde test fonksiyonu
    });
  });

  group('AppLogger — edge case\'ler', () {
    test('boş mesaj kabul edilir', () {
      String? captured;
      AppLogger.testLogCallback = (msg) => captured = msg;

      AppLogger.debug('');

      expect(captured, isNotNull);
    });

    test('testLogCallback null ise hata fırlatmaz', () {
      // testLogCallback null → debugPrint'e düşer, hata olmaz
      AppLogger.testLogCallback = null;
      expect(() => AppLogger.info('safe call'), returnsNormally);
    });

    test('çok uzun mesaj kesilmez (debugPrint\'in kendi limit\'i geçerli)', () {
      String? captured;
      AppLogger.testLogCallback = (msg) => captured = msg;

      final longMsg = 'x' * 5000;
      AppLogger.debug(longMsg);

      expect(captured, contains(longMsg));
    });
  });
}
