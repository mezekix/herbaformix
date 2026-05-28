import 'package:flutter_test/flutter_test.dart';
import 'package:herbaformix/core/utils/water_calculation_engine.dart';
import 'package:herbaformix/features/water_tracker/utils/water_calculation_constants.dart';
import 'package:herbaformix/models/user_profile_model.dart';
import 'package:herbaformix/models/user_role.dart';

void main() {
  group('WaterCalculationEngine Testleri', () {
    late UserProfileModel baseProfile;

    setUp(() {
      baseProfile = UserProfileModel(
        id: 'test_user',
        email: 'test@example.com',
        role: UserRole.customer,
        weight: 75.0,
        gender: 'Erkek',
        age: 25,
        healthNotes: '',
      );
    });

    test('Temel Erkek ve Genç Profili Hesaplaması', () {
      // 75 kg * 33 ml = 2475 ml -> en yakın 50'ye yuvarlama -> 2500 ml
      final result = WaterCalculationEngine.calculateGoal(
        profile: baseProfile,
        program: null,
        exerciseLevel: WaterCalculationConstants.exerciseSedentary,
        temp: null,
        humidity: null,
      );

      expect(result, 2500);
    });

    test('Kadın Profilinde %10 Azalma Etkisi', () {
      final femaleProfile = UserProfileModel(
        id: 'test_user',
        email: 'test@example.com',
        role: UserRole.customer,
        weight: 75.0,
        gender: 'Kadın',
        age: 25,
        healthNotes: '',
      );

      // (75 * 33) * 0.90 = 2475 * 0.9 = 2227.5 ml -> en yakın 50'ye yuvarlama -> 2250 ml
      final result = WaterCalculationEngine.calculateGoal(
        profile: femaleProfile,
        program: null,
        exerciseLevel: WaterCalculationConstants.exerciseSedentary,
        temp: null,
        humidity: null,
      );

      expect(result, 2250);
    });

    test('Emziren Anne Düzeltmesi (Kadın Profiline +700ml)', () {
      final femaleNursingProfile = UserProfileModel(
        id: 'test_user',
        email: 'test@example.com',
        role: UserRole.customer,
        weight: 70.0,
        gender: 'Kadın',
        age: 28,
        healthNotes: 'Bebeğimi emziriyorum.',
      );

      // (70 * 33) * 0.90 = 2310 * 0.9 = 2079 ml
      // Emzirme etkisi: +700ml -> 2079 + 700 = 2779 ml -> yuvarlama -> 2800 ml
      final result = WaterCalculationEngine.calculateGoal(
        profile: femaleNursingProfile,
        program: null,
        exerciseLevel: WaterCalculationConstants.exerciseSedentary,
        temp: null,
        humidity: null,
      );

      expect(result, 2800);
    });

    test('Orta Aktif Egzersiz Etkisi (+600ml)', () {
      // 75 kg Erkek -> 2475 ml + 600 ml = 3075 ml -> yuvarlama -> 3100 ml
      final result = WaterCalculationEngine.calculateGoal(
        profile: baseProfile,
        program: null,
        exerciseLevel: WaterCalculationConstants.exerciseModerate,
        temp: null,
        humidity: null,
      );

      expect(result, 3100);
    });

    test('Sıcak ve Kuru Hava Etkisi (Sıcaklık > 25°C: +300ml, Nem < %60: +200ml)', () {
      // 75 kg Erkek -> 2475 ml
      // Sıcaklık (28°C) -> +300 ml -> 2775 ml
      // Nem (%50) -> +200 ml -> 2975 ml -> yuvarlama -> 3000 ml
      final result = WaterCalculationEngine.calculateGoal(
        profile: baseProfile,
        program: null,
        exerciseLevel: WaterCalculationConstants.exerciseSedentary,
        temp: 28.0,
        humidity: 50.0,
      );

      expect(result, 3000);
    });

    test('Diyabet Tanılı Sağlık Düzeltmesi (+200ml)', () {
      final diabeticProfile = UserProfileModel(
        id: 'test_user',
        email: 'test@example.com',
        role: UserRole.customer,
        weight: 75.0,
        gender: 'Erkek',
        age: 25,
        healthNotes: 'Tip 2 şeker hastasıyım, diyabet tedavisi görüyorum.',
      );

      // 75 * 33 = 2475 ml + 200 ml = 2675 ml -> yuvarlama -> 2700 ml
      final result = WaterCalculationEngine.calculateGoal(
        profile: diabeticProfile,
        program: null,
        exerciseLevel: WaterCalculationConstants.exerciseSedentary,
        temp: null,
        humidity: null,
      );

      expect(result, 2700);
    });

    test('Mutlak Sınırlar Testi (1500 ml Altı ve 5000 ml Üstü Baskılama)', () {
      // Çok hafif zayıf profilde min sınıra baskılama
      final skinnyProfile = UserProfileModel(
        id: 'test_user',
        email: 'test@example.com',
        role: UserRole.customer,
        weight: 40.0, // 40 * 33 * 0.9 = 1188 ml
        gender: 'Kadın',
        age: 60, // 55+ yaş çarpanı * 0.9 -> ~1069 ml
      );

      final skinnyResult = WaterCalculationEngine.calculateGoal(
        profile: skinnyProfile,
        program: null,
        exerciseLevel: WaterCalculationConstants.exerciseSedentary,
        temp: null,
        humidity: null,
      );
      expect(skinnyResult, 1500); // 1500 ml'den aşağı düşemez

      // Çok ağır profilde max sınıra baskılama
      final heavyProfile = UserProfileModel(
        id: 'test_user',
        email: 'test@example.com',
        role: UserRole.customer,
        weight: 150.0, // 150 * 33 = 4950 ml
        gender: 'Erkek',
        age: 25,
      );

      final heavyResult = WaterCalculationEngine.calculateGoal(
        profile: heavyProfile,
        program: null,
        exerciseLevel: WaterCalculationConstants.exerciseHeavy, // +1000ml -> 5950 ml
        temp: 36.0, // +700ml -> 6650 ml
        humidity: null,
      );
      expect(heavyResult, 5000); // 5000 ml'den yukarı çıkamaz
    });

    test('Distribütör Manuel Limit Kısıtlamaları', () {
      final limitedProfile = UserProfileModel(
        id: 'test_user',
        email: 'test@example.com',
        role: UserRole.customer,
        weight: 75.0,
        gender: 'Erkek',
        age: 25,
        waterMinLimit: 2000,
        waterMaxLimit: 3000,
      );

      // Normal hesaplama: 2475 + 1000 (Yoğun egzersiz) + 700 (Aşırı sıcak) = 4175 ml
      // Ancak maxLimit 3000 olduğu için 3000 ml olmalı
      final result = WaterCalculationEngine.calculateGoal(
        profile: limitedProfile,
        program: null,
        exerciseLevel: WaterCalculationConstants.exerciseHeavy,
        temp: 36.0,
        humidity: null,
      );

      expect(result, 3000);
    });
  });
}
