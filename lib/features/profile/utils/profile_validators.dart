/// Profil formu validasyon fonksiyonları.
///
/// Tüm fonksiyonlar Flutter form validator uyumlu `String? Function(String?)`
/// imzasına sahiptir: geçerli girişte `null`, geçersiz girişte hata mesajı döner.
library;

/// Ad-soyad alanı validasyonu.
///
/// Boş veya yalnızca whitespace karakterlerinden oluşan değerleri reddeder.
/// Gereksinimler: 2.5
String? validateName(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Ad-soyad alanı boş bırakılamaz.';
  }
  return null;
}

/// Telefon numarası alanı validasyonu.
///
/// Alan boş bırakılabilir (opsiyonel). Dolu ise en az 7 rakam içermelidir.
/// Gereksinimler: 2.6
String? validatePhone(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null; // Opsiyonel alan
  }
  // Sadece rakam sayısını kontrol et (en az 7)
  final digitsOnly = value.trim().replaceAll(RegExp(r'[^\d]'), '');
  if (digitsOnly.length < 7) {
    return 'Geçerli bir telefon numarası girin.';
  }
  return null;
}

/// Boy alanı validasyonu (cm).
///
/// Alan boş bırakılabilir (opsiyonel). Dolu ise sayısal ve [50, 300] aralığında
/// olmalıdır. Ondalıklı değerlere izin verilir.
/// Gereksinimler: 3.2, 3.5
String? validateHeight(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null; // Opsiyonel alan
  }
  final parsed = double.tryParse(value.trim());
  if (parsed == null) {
    return 'Boy için geçerli bir sayı girin.';
  }
  if (parsed < 50 || parsed > 300) {
    return 'Boy 50 ile 300 cm arasında olmalıdır.';
  }
  return null;
}

/// Kilo alanı validasyonu (kg).
///
/// Alan boş bırakılabilir (opsiyonel). Dolu ise sayısal ve [10, 500] aralığında
/// olmalıdır. Ondalıklı değerlere izin verilir.
/// Hem mevcut kilo hem de hedef kilo alanları için kullanılır.
/// Gereksinimler: 3.3, 3.5
String? validateWeight(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null; // Opsiyonel alan
  }
  final parsed = double.tryParse(value.trim());
  if (parsed == null) {
    return 'Kilo için geçerli bir sayı girin.';
  }
  if (parsed < 10 || parsed > 500) {
    return 'Kilo 10 ile 500 kg arasında olmalıdır.';
  }
  return null;
}

/// Sağlık bilgisi alanı validasyonu (sağlık notları, alerjiler, ilaçlar).
///
/// Alan boş bırakılabilir (opsiyonel). Dolu ise 1000 karakter sınırını kontrol eder.
/// Gereksinimler: 3.4, 3.7
String? validateHealthField(String? value) {
  if (value == null || value.isEmpty) {
    return null; // Opsiyonel alan
  }
  if (value.length > 1000) {
    return 'Bu alan en fazla 1000 karakter içerebilir.';
  }
  return null;
}
