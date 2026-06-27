/// E-posta adresi doğrulama yardımcıları.
///
/// Kullanım:
/// ```dart
/// final error = EmailValidator.validate(text);
/// if (error != null) showError(error);
/// ```
///
/// **Tasarım kararları:**
/// - RFC 5322'nin tam uyumu aşırı karmaşık ve kullanıcıya anlamsız
///   hata mesajları verir ("user..name@example.com" gibi edge case'ler
///   teknik olarak geçerli ama çoğu servis kabul etmez). Burada
///   "pratik kabul" kullanıyoruz: yaygın olarak geçerli sayılan pattern'ler
///   geçer, geri kalan reddedilir.
/// - Sonuç null ise geçerli; değilse kullanıcıya gösterilecek Türkçe mesaj.
/// - Yan etkisi yok — pure function, kolay unit testlenir.
class EmailValidator {
  EmailValidator._();

  /// Yaygın pratik e-posta formatı:
  /// - Local part: `[a-zA-Z0-9._%+-]+` (alfanümerik + yaygın özel karakter)
  /// - `@` zorunlu
  /// - Domain: `[a-zA-Z0-9.-]+`
  /// - TLD: `[a-zA-Z]{2,}` (en az 2 harf — `.io`, `.co.uk` da 2 harf kök TLD)
  ///
  /// Örnekler:
  /// - ✅ user@example.com
  /// - ✅ user.name+tag@sub.example.co.uk
  /// - ❌ user@             (domain yok)
  /// - ❌ @example.com      (local yok)
  /// - ❌ user.example.com  (@ yok)
  /// - ❌ user@example      (TLD yok)
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// RFC 5321 sınırları:
  /// - Toplam uzunluk ≤ 254
  /// - Local part ≤ 64
  static const int maxTotalLength = 254;
  static const int maxLocalLength = 64;

  /// Verilen metni e-posta olarak doğrular.
  ///
  /// **Dönüş:**
  /// - `null` → geçerli
  /// - `String` → kullanıcıya gösterilecek Türkçe hata mesajı
  static String? validate(String? input) {
    if (input == null) return 'E-posta adresi gerekli.';
    final trimmed = input.trim();
    if (trimmed.isEmpty) return 'E-posta adresi gerekli.';

    if (trimmed.length > maxTotalLength) {
      return 'E-posta adresi çok uzun (en fazla $maxTotalLength karakter).';
    }

    final atIndex = trimmed.indexOf('@');
    if (atIndex < 0) return 'Geçerli bir e-posta adresi girin.';

    final local = trimmed.substring(0, atIndex);
    if (local.isEmpty) return 'Geçerli bir e-posta adresi girin.';
    if (local.length > maxLocalLength) {
      return 'E-posta adresinin kullanıcı kısmı çok uzun.';
    }

    if (!_emailRegex.hasMatch(trimmed)) {
      return 'Geçerli bir e-posta adresi girin.';
    }

    return null;
  }

  /// Form validator'ları için kısa yardımcı: hata varsa [String] döner,
  /// yoksa `null`. Flutter'ın TextFormField validator sözleşmesiyle birebir
  /// uyumlu.
  static String? Function(String?) field() => validate;
}