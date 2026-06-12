import '../../features/water_tracker/utils/water_calculation_constants.dart';
import '../../models/user_profile_model.dart';

/// Günlük kalori hedefini cinsiyet, kilo, boy, yaş, kullanıcının kilo hedefi
/// (zayıflama/korunma/kilo alma) ve aktivite seviyesinden hesaplar.
///
/// Formül: **Mifflin-St Jeor** (BMR) × aktivite çarpanı (TDEE) + hedef offset.
///
/// Mifflin-St Jeor klinik olarak doğrulanmış endüstri standardıdır;
/// Harris-Benedict'e göre %5'e kadar daha doğru sonuç verir.
class CalorieCalculationEngine {
  /// Aktivite çarpanları — su tracker'la aynı seviye anahtarlarını kullanır.
  static const double _multSedentary = 1.2;
  static const double _multLight = 1.375;
  static const double _multModerate = 1.55;
  static const double _multHeavy = 1.725;

  /// userGoal başına günlük kalori offset'i (kcal).
  /// Zayıflama: ~0.5 kg/hafta hedefi için günlük 500 kcal açık.
  /// Kilo alma: ~0.5 kg/hafta için 500 kcal fazlalık.
  static const int _offsetWeightLoss = -500;
  static const int _offsetWeightGain = 500;
  static const int _offsetMaintenance = 0;

  /// Mutlak güvenlik sınırları — herhangi bir hesap sonucu bu aralığa clamp'lenir.
  /// WHO/USDA kadın için minimum güvenli alım 1200 kcal, erkek için 1500 kcal.
  static const int _absoluteMinKcal = 1200;
  static const int _absoluteMaxKcal = 4000;

  /// Mifflin-St Jeor BMR (kcal/gün).
  ///
  /// - Erkek: `10×kg + 6.25×cm − 5×yaş + 5`
  /// - Kadın: `10×kg + 6.25×cm − 5×yaş − 161`
  static double calculateBmr({
    required double weightKg,
    required double heightCm,
    required int ageYears,
    required String gender,
  }) {
    final base = 10 * weightKg + 6.25 * heightCm - 5 * ageYears;
    final isFemale = gender.toLowerCase() == 'kadın';
    return base + (isFemale ? -161 : 5);
  }

  /// Aktivite seviyesi için TDEE çarpanı.
  /// Bilinmeyen seviyede orta varsayılan.
  static double activityMultiplier(String exerciseLevel) {
    switch (exerciseLevel) {
      case WaterCalculationConstants.exerciseSedentary:
        return _multSedentary;
      case WaterCalculationConstants.exerciseLight:
        return _multLight;
      case WaterCalculationConstants.exerciseModerate:
        return _multModerate;
      case WaterCalculationConstants.exerciseHeavy:
        return _multHeavy;
      default:
        return _multModerate;
    }
  }

  /// Kullanıcının kilo hedefine göre günlük kcal offset.
  static int goalOffset(String? userGoal) {
    switch (userGoal) {
      case 'weight_loss':
        return _offsetWeightLoss;
      case 'weight_gain':
        return _offsetWeightGain;
      case 'healthy_living':
      case 'skin_care':
      default:
        return _offsetMaintenance;
    }
  }

  /// Günlük toplam kalori hedefini hesaplar.
  /// Profil bilgileri eksikse [CalorieGoalResult.isComplete] `false` döner ve
  /// 2000 kcal varsayılanı kullanılır — UI bunu yakalayıp kullanıcıyı eksik
  /// bilgilerini doldurmaya yönlendirebilir.
  static CalorieGoalResult calculateGoal({
    required UserProfileModel profile,
    required String exerciseLevel,
  }) {
    final weight = profile.weight;
    final height = profile.height;
    final age = profile.age ?? _calculateAge(profile.birthDate);
    final gender = profile.gender;

    if (weight == null ||
        height == null ||
        age == null ||
        gender == null ||
        gender.isEmpty) {
      return const CalorieGoalResult(
        totalKcal: 2000,
        bmrKcal: 0,
        tdeeKcal: 2000,
        activityMultiplier: 1.0,
        goalOffsetKcal: 0,
        exerciseLevel: '',
        isComplete: false,
      );
    }

    final bmr = calculateBmr(
      weightKg: weight,
      heightCm: height,
      ageYears: age,
      gender: gender,
    );
    final mult = activityMultiplier(exerciseLevel);
    final tdee = bmr * mult;
    final offset = goalOffset(profile.userGoal);

    // 10 kcal'a yuvarla (kullanıcı için okunabilir bir sayı)
    final raw = ((tdee + offset) / 10).round() * 10;
    final clamped = raw.clamp(_absoluteMinKcal, _absoluteMaxKcal);

    return CalorieGoalResult(
      totalKcal: clamped,
      bmrKcal: bmr.round(),
      tdeeKcal: tdee.round(),
      activityMultiplier: mult,
      goalOffsetKcal: offset,
      exerciseLevel: exerciseLevel,
      isComplete: true,
    );
  }

  static int? _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// Otomatik hesaplama için eksik olan profil alanlarının kullanıcıya
  /// gösterilecek Türkçe isimlerini döner. Profil tamsa boş liste.
  /// UI bunu "şu bilgilerini gir" listesi olarak kullanır.
  static List<String> missingFieldsFor(UserProfileModel? profile) {
    if (profile == null) return const ['Boy', 'Kilo', 'Yaş', 'Cinsiyet'];
    final missing = <String>[];
    if (profile.height == null) missing.add('Boy');
    if (profile.weight == null) missing.add('Kilo');
    if (profile.age == null && profile.birthDate == null) {
      missing.add('Yaş');
    }
    if (profile.gender == null || profile.gender!.isEmpty) {
      missing.add('Cinsiyet');
    }
    return missing;
  }
}

/// Hesaplama sonucu — UI'da hem nihai hedefi göstermek hem de gerekirse
/// detayları (BMR, TDEE, aktivite çarpanı) açıklamak için kullanılır.
class CalorieGoalResult {
  /// Kullanıcıya gösterilecek nihai günlük kalori hedefi (kcal).
  final int totalKcal;

  /// Bazal metabolizma hızı (kcal/gün). Profil eksikse 0.
  final int bmrKcal;

  /// Toplam günlük enerji harcaması (kcal/gün). Profil eksikse [totalKcal]'a eşit.
  final int tdeeKcal;

  /// Aktivite seviyesinden gelen çarpan (1.2 / 1.375 / 1.55 / 1.725).
  final double activityMultiplier;

  /// userGoal'dan gelen offset (kcal). Pozitif = ekleme, negatif = açık.
  final int goalOffsetKcal;

  /// Hesaplamada kullanılan aktivite seviyesi anahtarı (su tracker'ın sabitleri).
  final String exerciseLevel;

  /// Profil bilgileri tamamlanmışsa `true`; eksikse `false` — UI uyarı gösterebilir.
  final bool isComplete;

  const CalorieGoalResult({
    required this.totalKcal,
    required this.bmrKcal,
    required this.tdeeKcal,
    required this.activityMultiplier,
    required this.goalOffsetKcal,
    required this.exerciseLevel,
    required this.isComplete,
  });
}
