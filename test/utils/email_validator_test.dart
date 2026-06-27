// EmailValidator — geçerli/geçersiz e-posta kabul kuralları testleri.

import 'package:flutter_test/flutter_test.dart';
import 'package:herbaformix/core/utils/email_validator.dart';

void main() {
  group('EmailValidator.validate — geçerli vakalar (null döner)', () {
    test('standart format: user@example.com', () {
      expect(EmailValidator.validate('user@example.com'), isNull);
    });

    test('minimal format: a@b.co', () {
      expect(EmailValidator.validate('a@b.co'), isNull);
    });

    test('nokta içeren local: user.name@example.com', () {
      expect(EmailValidator.validate('user.name@example.com'), isNull);
    });

    test('artı tag: user+tag@example.com', () {
      expect(EmailValidator.validate('user+tag@example.com'), isNull);
    });

    test('alt domain: user@sub.example.com', () {
      expect(EmailValidator.validate('user@sub.example.com'), isNull);
    });

    test('uzun TLD zinciri: user@example.co.uk', () {
      expect(EmailValidator.validate('user@example.co.uk'), isNull);
    });

    test('sayısal local ve domain: 123@456.com', () {
      expect(EmailValidator.validate('123@456.com'), isNull);
    });

    test('yüzde ve tire: user_name%tag@my-site.io', () {
      expect(EmailValidator.validate('user_name%tag@my-site.io'), isNull);
    });

    test('etrafında boşluk → trim edilir ve geçerli sayılır', () {
      expect(EmailValidator.validate('  user@example.com  '), isNull);
    });
  });

  group('EmailValidator.validate — geçersiz vakalar (mesaj döner)', () {
    test('boş string → "E-posta adresi gerekli."', () {
      expect(EmailValidator.validate(''), 'E-posta adresi gerekli.');
    });

    test('null → "E-posta adresi gerekli."', () {
      expect(EmailValidator.validate(null), 'E-posta adresi gerekli.');
    });

    test('sadece whitespace → "E-posta adresi gerekli."', () {
      expect(EmailValidator.validate('   '), 'E-posta adresi gerekli.');
    });

    test('sadece @ → geçerli e-posta değil', () {
      expect(EmailValidator.validate('@'), isNotNull);
    });

    test('domain yok: user@', () {
      final error = EmailValidator.validate('user@');
      expect(error, 'Geçerli bir e-posta adresi girin.');
    });

    test('local yok: @example.com', () {
      expect(EmailValidator.validate('@example.com'), isNotNull);
    });

    test('@ yok: userexample.com', () {
      final error = EmailValidator.validate('userexample.com');
      expect(error, 'Geçerli bir e-posta adresi girin.');
    });

    test('TLD yok: user@example', () {
      expect(EmailValidator.validate('user@example'), isNotNull);
    });

    test('çok kısa TLD: user@example.c', () {
      expect(EmailValidator.validate('user@example.c'), isNotNull);
    });

    test('içinde boşluk: "user @example.com"', () {
      expect(EmailValidator.validate('user @example.com'), isNotNull);
    });

    test('çift @: user@@example.com', () {
      expect(EmailValidator.validate('user@@example.com'), isNotNull);
    });

    test('Sadece harf local yok: a@b', () {
      // TLD 2+ harf olmalı → "b" 1 harf → reddedilir
      expect(EmailValidator.validate('a@b'), isNotNull);
    });
  });

  group('EmailValidator.validate — uzunluk sınırları', () {
    test('toplam 254 karakter → geçerli', () {
      // local = "a" * 64, "@", domain kısmı 189 karakter (max 254-65)
      final local = 'a' * 64;
      final domain = '${'b' * 184}.com'; // 184 + 4 = 188
      final email = '$local@$domain'; // 64 + 1 + 188 = 253
      expect(EmailValidator.validate(email), isNull);
    });

    test('toplam 255 karakter → çok uzun hatası', () {
      final local = 'a' * 64;
      final domain = '${'b' * 185}.com'; // 185 + 4 = 189
      final email = '$local@$domain'; // 64 + 1 + 189 = 254 → sınır
      // 254 geçerli, 255 reddedilir
      expect(EmailValidator.validate(email), isNull);

      final tooLong = '$local@${'b' * 186}.com'; // 64 + 1 + 190 = 255
      expect(EmailValidator.validate(tooLong), isNotNull);
    });

    test('local 65 karakter → çok uzun hatası', () {
      final local = 'a' * 65;
      final email = '$local@example.com';
      final error = EmailValidator.validate(email);
      expect(error, 'E-posta adresinin kullanıcı kısmı çok uzun.');
    });
  });

  group('EmailValidator.field() — TextFormField entegrasyonu', () {
    test('null → hata mesajı döner', () {
      final validator = EmailValidator.field();
      expect(validator(null), 'E-posta adresi gerekli.');
    });

    test('geçerli → null döner (Form otomatik geçerli sayar)', () {
      final validator = EmailValidator.field();
      expect(validator('user@example.com'), isNull);
    });

    test('geçersiz → mesaj döner', () {
      final validator = EmailValidator.field();
      expect(validator('not-an-email'), isNotNull);
    });
  });
}