import '../../models/user_profile_model.dart';

/// [UserProfileModel] üzerinde BMI (Vücut Kitle İndeksi) hesaplama uzantısı.
///
/// BMI formülü: `kilo (kg) / boy² (m²)`. Sonuç kg/m² cinsinden 2 ondalık
/// basamağa yuvarlanır (kg/m² cinsinden tipik klinik kesinlik).
///
/// **Davranış sözleşmesi:**
/// - `height` null, 0 veya negatifse → BMI null (bölme hatası yok).
/// - `weight` null ise [bmi] getter'ı null döner; [bmiFor] ise açıkça
///   verilen [weightKg] ile çalışır (örn. henüz profile'a yazılmamış bir
///   yeni ölçüm değeri).
/// - Yuvarlama `.toStringAsFixed(2)` ile yapılır — `0.1 + 0.2` gibi kayan
///   nokta artefaktlarını maskeleyerek tutarlı ondalık üretir.
extension UserProfileBmi on UserProfileModel {
  /// Profilin kayıtlı [weight] değeri için BMI hesaplar.
  /// Profile'ın kendi kilosu veya boyu eksikse null döner.
  double? get bmi {
    final w = weight;
    if (w == null) return null;
    return bmiFor(w);
  }

  /// Verilen [weightKg] için BMI hesaplar.
  ///
  /// Bu genellikle henüz profile'a kaydedilmemiş bir yeni ölçüm değerini
  /// (örn. `ProgressEntryModel.weight`) BMI olarak değerlendirmek için
  /// kullanılır.
  double? bmiFor(double weightKg) {
    final h = height;
    if (h == null || h <= 0) return null;
    final heightInMeters = h / 100.0;
    final result = weightKg / (heightInMeters * heightInMeters);
    return double.parse(result.toStringAsFixed(2));
  }
}