// UserProfileBmi extension — BMI hesaplama sözleşmesinin unit testleri.
//
// Davranış sözleşmesi:
//   - height null, 0 veya negatifse → null (bölme hatası yok)
//   - bmi getter → profilin kendi weight'i ile hesaplar; weight null ise null
//   - bmiFor(w) → verilen kilo ile hesaplar
//   - Sonuç 2 ondalık basamağa yuvarlanır (kg/m² tipik klinik kesinlik)

// ignore_for_file: dead_null_aware_expression, dead_code
import 'package:flutter_test/flutter_test.dart';
import 'package:herbaformix/core/extensions/user_profile_bmi.dart';
import 'package:herbaformix/models/user_profile_model.dart';
import 'package:herbaformix/models/user_role.dart';

UserProfileModel _profile({
  double? weight,
  double? height,
}) {
  return UserProfileModel(
    id: 'test_user',
    email: 'test@example.com',
    role: UserRole.customer,
    weight: weight,
    height: height,
  );
}

void main() {
  group('UserProfileBmi.bmiFor — boy koruması', () {
    test('height null → null (bölme hatası yok)', () {
      final p = _profile(height: null);
      expect(p.bmiFor(80), isNull);
    });

    test('height 0 → null (sıfıra bölmeye karşı guard)', () {
      final p = _profile(height: 0);
      expect(p.bmiFor(80), isNull);
    });

    test('height negatif → null (negatif boy fiziksel olarak imkansız)', () {
      final p = _profile(height: -180);
      expect(p.bmiFor(80), isNull);
    });
  });

  group('UserProfileBmi.bmiFor — hesaplama doğruluğu', () {
    test('180 cm / 80 kg → 24.69', () {
      // 80 / (1.8²) = 80 / 3.24 = 24.6913... → 24.69
      final p = _profile(height: 180);
      expect(p.bmiFor(80), 24.69);
    });

    test('170 cm / 70 kg → 24.22', () {
      // 70 / (1.7²) = 70 / 2.89 = 24.2214... → 24.22
      final p = _profile(height: 170);
      expect(p.bmiFor(70), 24.22);
    });

    test('160 cm / 50 kg → 19.53', () {
      // 50 / (1.6²) = 50 / 2.56 = 19.5312... → 19.53
      final p = _profile(height: 160);
      expect(p.bmiFor(50), 19.53);
    });

    test('200 kg / 180 cm → 61.73 (obezite aralığı)', () {
      // 200 / 3.24 = 61.7283... → 61.73
      final p = _profile(height: 180);
      expect(p.bmiFor(200), 61.73);
    });

    test('45 kg / 150 cm → 20.0 (zayıf ama BMI 18.5 üstü)', () {
      // 45 / 2.25 = 20.0 (tam sayı)
      final p = _profile(height: 150);
      expect(p.bmiFor(45), 20.0);
    });

    test('kilo 0 → BMI 0 (sıfır kiloda sıfır döner)', () {
      final p = _profile(height: 170);
      expect(p.bmiFor(0), 0.0);
    });
  });

  group('UserProfileBmi.bmiFor — yuvarlama davranışı', () {
    test('sonuç 2 ondalık basamağa yuvarlanır (üçüncü basamak atılır)', () {
      // 75 kg / 175 cm → 75 / 3.0625 = 24.4897... → 24.49
      final p = _profile(height: 175);
      expect(p.bmiFor(75), 24.49);
    });

    test('uzun ondalık zinciri olan sonuç temiz yazılır', () {
      // 67 kg / 168 cm → 67 / 2.8224 = 23.7386... → 23.74
      final p = _profile(height: 168);
      final result = p.bmiFor(67);
      expect(result, 23.74);
      // Virgülden sonra 2 basamak
      expect(result!.toString().split('.').last.length, 2);
    });
  });

  group('UserProfileBmi.bmi (profilin kendi kilosuyla)', () {
    test('weight null → null (bmi getter null-safe)', () {
      final p = _profile(weight: null, height: 180);
      expect(p.bmi, isNull);
    });

    test('height null → null (boy koruması bmi getter\'da da geçerli)', () {
      final p = _profile(weight: 80, height: null);
      expect(p.bmi, isNull);
    });

    test('weight ve height set ise profile.weight ile hesaplar', () {
      // 90 / (1.75²) = 90 / 3.0625 = 29.3877... → 29.39
      final p = _profile(weight: 90, height: 175);
      expect(p.bmi, 29.39);
    });

    test('hem weight hem height null → null', () {
      final p = _profile();
      expect(p.bmi, isNull);
    });
  });

  group('UserProfileBmi — ProgressProvider entegrasyonu simülasyonu', () {
    test(
        'progress_provider.addEntry davranışı: entry.bmi null + profile var '
        '→ profilin boyu ile hesaplanır', () {
      // Provider kodu:
      //   final bmi = entry.bmi ?? userProfile?.bmiFor(entry.weight);
      final profile = _profile(height: 170);
      const double entryWeight = 70;
      const double? entryBmi = null; // kullanıcı manuel girmedi

      final result = entryBmi ?? profile.bmiFor(entryWeight);
      expect(result, 24.22);
    });

    test(
        'progress_provider.addEntry davranışı: entry.bmi açıkça set edilmişse '
        'profile.bmiFor() çağrılmaz (kullanıcı girdisi öncelikli)', () {
      final profile = _profile(height: 170);
      const double entryWeight = 70;
      double? entryBmi = [99.99].first;
      final result = entryBmi ?? profile.bmiFor(entryWeight);
      expect(result, 99.99); // hesaplanan 24.22 degil, kullanicinin dedigi
    });

    test('userProfile null ise bmi null kalir (profil yokken patlamaz)', () {
      UserProfileModel? profile = [null].cast<UserProfileModel?>().first;
      const double entryWeight = 80;

      final result = profile?.bmiFor(entryWeight);
      expect(result, isNull);
    });
  });
}
