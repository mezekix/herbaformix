import '../../features/program/models/program_model.dart';
import '../../features/water_tracker/utils/water_calculation_constants.dart';
import '../../models/user_profile_model.dart';

class WaterCalculationEngine {
  /// Tüm parametreleri değerlendirerek dinamik su hedefini (ml) hesaplar.
  static int calculateGoal({
    required UserProfileModel profile,
    required ProgramModel? program,
    required String exerciseLevel,
    required double? temp,
    required double? humidity,
  }) {
    // 1. Baz Değer Hesaplama (Kilo * 33 ml)
    final double weight = profile.weight ?? 70.0; // Kilo yoksa varsayılan 70 kg
    double calculatedWater = weight * WaterCalculationConstants.baseMlPerKg;

    // 2. Cinsiyet Düzeltmesi
    final String gender = (profile.gender ?? 'Erkek').toLowerCase();
    if (gender == 'kadın') {
      calculatedWater *= WaterCalculationConstants.femaleMultiplier;
    }

    // Özel Gebelik/Emzirme kontrolü (Sağlık notlarından aranır)
    final String healthNotesLower = (profile.healthNotes ?? '').toLowerCase();
    if (healthNotesLower.contains('hamil') || healthNotesLower.contains('gebe')) {
      calculatedWater += WaterCalculationConstants.pregnancyAdditionMl;
    } else if (healthNotesLower.contains('emzir')) {
      calculatedWater += WaterCalculationConstants.breastfeedingAdditionMl;
    }

    // 3. Yaş Düzeltmesi
    final int age = profile.age ?? _calculateAge(profile.birthDate) ?? 25; // Yaş yoksa varsayılan 25
    if (age <= 30) {
      calculatedWater *= WaterCalculationConstants.ageUnder30Multiplier;
    } else if (age <= 55) {
      calculatedWater *= WaterCalculationConstants.age31To55Multiplier;
    } else {
      calculatedWater *= WaterCalculationConstants.ageOver55Multiplier;
    }

    // 4. Egzersiz Durumu Düzeltmesi
    switch (exerciseLevel) {
      case WaterCalculationConstants.exerciseLight:
        calculatedWater += WaterCalculationConstants.exerciseLightMl;
        break;
      case WaterCalculationConstants.exerciseModerate:
        calculatedWater += WaterCalculationConstants.exerciseModerateMl;
        break;
      case WaterCalculationConstants.exerciseHeavy:
        calculatedWater += WaterCalculationConstants.exerciseHeavyMl;
        break;
      case WaterCalculationConstants.exerciseSedentary:
      default:
        calculatedWater += WaterCalculationConstants.exerciseSedentaryMl;
        break;
    }

    // 5. Hava Durumu Düzeltmesi
    if (temp != null) {
      if (temp < WaterCalculationConstants.tempThresholdCold) {
        calculatedWater += WaterCalculationConstants.tempColdMl;
      } else if (temp >= WaterCalculationConstants.tempThresholdCold &&
          temp <= WaterCalculationConstants.tempThresholdWarm) {
        calculatedWater += WaterCalculationConstants.tempNormalMl;
      } else if (temp > WaterCalculationConstants.tempThresholdWarm &&
          temp <= WaterCalculationConstants.tempThresholdHot) {
        calculatedWater += WaterCalculationConstants.tempWarmMl;
      } else if (temp > WaterCalculationConstants.tempThresholdHot &&
          temp <= WaterCalculationConstants.tempThresholdVeryHot) {
        calculatedWater += WaterCalculationConstants.tempHotMl;
      } else {
        calculatedWater += WaterCalculationConstants.tempVeryHotMl;
      }
    }

    // 6. Nem Oranı Düzeltmesi
    if (humidity != null) {
      if (humidity < WaterCalculationConstants.humidityThresholdLow) {
        calculatedWater += WaterCalculationConstants.humidityLowMl;
      } else if (humidity >= WaterCalculationConstants.humidityThresholdLow &&
          humidity <= WaterCalculationConstants.humidityThresholdHigh) {
        calculatedWater += WaterCalculationConstants.humidityNormalMl;
      } else {
        calculatedWater += WaterCalculationConstants.humidityHighMl;
      }
    }

    // 7. Herbalife Ürün Kullanımı Düzeltmesi
    if (program != null && program.isActive) {
      int shakeCount = 0;
      bool hasAloe = false;
      bool hasTea = false;
      bool hasFiber = false;
      int totalHerbalifeProducts = 0;

      for (final slot in program.slots) {
        if (slot.isNormalMeal) continue;
        for (final product in slot.products) {
          final name = product.productName.toLowerCase();
          totalHerbalifeProducts++;

          if (name.contains('shake') || name.contains('formul 1') || name.contains('formül 1')) {
            shakeCount++;
          } else if (name.contains('aloe')) {
            hasAloe = true;
          } else if (name.contains('çay') || name.contains('cay') || name.contains('bitkisel konsantre')) {
            hasTea = true;
          } else if (name.contains('fiber') || name.contains('lif') || name.contains('aktif tablet')) {
            hasFiber = true;
          }
        }
      }

      calculatedWater += shakeCount * WaterCalculationConstants.productEffectShake;
      if (hasAloe) {
        calculatedWater += WaterCalculationConstants.productEffectAloe;
      }
      if (hasTea) {
        calculatedWater += WaterCalculationConstants.productEffectTea;
      }
      if (hasFiber) {
        calculatedWater += WaterCalculationConstants.productEffectFiber;
      }
      
      // Yoğun takviye programı etkisi (programda en az 4 ürün varsa)
      if (totalHerbalifeProducts >= 4) {
        calculatedWater += WaterCalculationConstants.productEffectActiveProgram;
      }
    }

    // 8. Diyabet Düzeltmesi
    if (healthNotesLower.contains('diyabet') || healthNotesLower.contains('seker') || healthNotesLower.contains('şeker')) {
      calculatedWater += WaterCalculationConstants.healthEffectDiabetesMl;
    }

    // Nihai Yuvarlama (En yakın 50 ml veya 100 ml)
    int finalGoal = (calculatedWater / 50).round() * 50;

    // 9. Distribütör / Mutlak Sınırlar
    final int minLimit = profile.waterMinLimit ?? WaterCalculationConstants.absoluteMinWaterMl;
    final int maxLimit = profile.waterMaxLimit ?? WaterCalculationConstants.absoluteMaxWaterMl;

    if (finalGoal < minLimit) {
      finalGoal = minLimit;
    } else if (finalGoal > maxLimit) {
      finalGoal = maxLimit;
    }

    return finalGoal;
  }

  static int? _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}
