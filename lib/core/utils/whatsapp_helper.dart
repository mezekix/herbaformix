// WhatsApp üzerinden davet kodu gönderme yardımcısı.
//
// `wa.me` deep link'i ile WhatsApp veya WhatsApp Business uygulamasını açar.
// Telefon numarası normalize edilir; başında 0 varsa Türkiye için +90 olarak
// genişletilir, +90 / 0090 yoksa varsayılan ülke kodu eklenir.
//
// Android 11+ için `android/app/src/main/AndroidManifest.xml` içine
// `<queries>` bloğunda `com.whatsapp` ve `com.whatsapp.w4b` paket adları
// eklenmelidir; aksi halde `canLaunchUrl` false döner.

import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:herbaformix/core/logger.dart';

/// Türkiye için varsayılan ülke kodu (başında + olmadan).
const String kDefaultCountryCode = '90';

/// Davet kodunu WhatsApp üzerinden müşteriye gönderir.
///
/// - [phone] kullanıcının girdiği ham telefon numarası (boşluk, parantez,
///   tire vb. içerebilir).
/// - [code] 8 karakterlik davet kodu.
/// - [expiresAt] kodun son geçerlilik zamanı; mesajda tarih olarak gösterilir.
///
/// Başarılıysa `true`, link açılamadıysa `false` döner.
Future<bool> sendInviteViaWhatsApp({
  required String phone,
  required String code,
  required DateTime expiresAt,
  String? customerName,
}) async {
  final normalized = normalizePhoneForWhatsApp(phone);
  if (normalized == null) {
    AppLogger.error('WhatsApp gönderim hatası: telefon normalize edilemedi -> $phone', tag: 'WhatsappHelper');
    return false;
  }

  final dateStr = DateFormat('dd.MM.yyyy').format(expiresAt);
  final greeting = (customerName != null && customerName.trim().isNotEmpty)
      ? 'Merhaba ${customerName.trim()}!'
      : 'Merhaba!';

  final message = '$greeting\n'
      'Herbaformix uygulamasına kaydolmak için davet kodunuz: $code\n'
      'Uygulamayı indirip kayıt olurken bu kodu girin.\n'
      'Kod $dateStr tarihine kadar geçerlidir.';

  final uri = Uri.parse(
    'https://wa.me/$normalized?text=${Uri.encodeComponent(message)}',
  );

  try {
    final canLaunch = await canLaunchUrl(uri);
    if (!canLaunch) {
      AppLogger.error('WhatsApp gönderim hatası: canLaunchUrl false -> $uri', tag: 'WhatsappHelper');
      return false;
    }
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    AppLogger.error('WhatsApp gönderim hatası: $e', tag: 'WhatsappHelper', error: e);
    return false;
  }
}

/// Verilen ham telefon numarasını WhatsApp `wa.me/` formatına uygun
/// rakam-yalnız bir string'e çevirir.
///
/// Kurallar:
/// - Boşluk, tire, parantez, nokta gibi tüm rakam-dışı karakterler atılır.
/// - `+` karakteri atılır.
/// - `00` ile başlıyorsa kaldırılır (Avrupa açma kodu).
/// - `0` ile başlıyorsa baştaki sıfır kaldırılır ve [kDefaultCountryCode]
///   (90) öne eklenir.
/// - 10-15 hane arası bir sonuç vermiyorsa `null` döner (defansif).
String? normalizePhoneForWhatsApp(String raw) {
  if (raw.trim().isEmpty) return null;

  // Sadece rakamları al.
  var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return null;

  // 00 ile başlıyorsa (Avrupa uluslararası prefix) kaldır.
  if (digits.startsWith('00')) {
    digits = digits.substring(2);
  } else if (digits.startsWith('0')) {
    // Türkiye için baştaki 0 kaldır, ülke kodu ekle.
    digits = '$kDefaultCountryCode${digits.substring(1)}';
  }

  // Eğer 10 haneli ise (mesela kullanıcı doğrudan 5xxxxxxxxx yazdıysa)
  // başına ülke kodu ekle.
  if (digits.length == 10) {
    digits = '$kDefaultCountryCode$digits';
  }

  if (digits.length < 10 || digits.length > 15) {
    return null;
  }

  return digits;
}
