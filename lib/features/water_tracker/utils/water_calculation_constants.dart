// Su alımı hesaplamasında kullanılan katsayılar ve sabit değerler.
// Magic number ve string kullanımını önlemek amacıyla tanımlanmıştır.

class WaterCalculationConstants {
  // Baz Su Katsayısı
  static const double baseMlPerKg = 33.0;

  // Cinsiyet Katsayıları ve Düzeltmeleri
  static const double femaleMultiplier = 0.90; // Kadınlarda -%10
  static const double maleMultiplier = 1.00;   // Erkeklerde standart
  static const int pregnancyAdditionMl = 300;  // Hamilelik +300ml
  static const int breastfeedingAdditionMl = 700; // Emzirme +700ml

  // Yaş Grubu Katsayıları
  static const double ageUnder30Multiplier = 1.00;
  static const double age31To55Multiplier = 0.95; // 31-55 yaş -%5
  static const double ageOver55Multiplier = 0.90;  // 55+ yaş -%10

  // Egzersiz Seviyeleri ve ml Karşılıkları
  static const String exerciseSedentary = 'sedentary';
  static const String exerciseLight = 'light';
  static const String exerciseModerate = 'moderate';
  static const String exerciseHeavy = 'heavy';

  static const int exerciseSedentaryMl = 0;
  static const int exerciseLightMl = 350;
  static const int exerciseModerateMl = 600;
  static const int exerciseHeavyMl = 1000;

  // Hava Sıcaklığı ve ml Karşılıkları
  static const int tempThresholdCold = 15;
  static const int tempThresholdWarm = 25;
  static const int tempThresholdHot = 30;
  static const int tempThresholdVeryHot = 35;

  static const int tempColdMl = -200;      // 15°C altı
  static const int tempNormalMl = 0;        // 15-25°C arası
  static const int tempWarmMl = 300;       // 25-30°C arası
  static const int tempHotMl = 500;        // 30-35°C arası
  static const int tempVeryHotMl = 700;     // 35°C üstü

  // Nem Oranları ve ml Karşılıkları
  static const double humidityThresholdLow = 60.0;
  static const double humidityThresholdHigh = 75.0;

  static const int humidityLowMl = 200;     // %60 altı (kuru hava)
  static const int humidityNormalMl = 0;    // %60-75 arası
  static const int humidityHighMl = 150;    // %75 üstü (nemli hava)

  // Herbalife Ürünlerinin Su İhtiyacına ml Bazlı Etkisi
  static const int productEffectShake = 200;       // Her shake protein metabolizması için +200ml
  static const int productEffectAloe = 100;        // Aloe konsantre +100ml
  static const int productEffectTea = -100;        // Çay diüretik/sıvı katkısı sebebiyle -100ml
  static const int productEffectFiber = 150;       // Fiber lif tableti +150ml
  static const int productEffectActiveProgram = 300; // Yoğun takviye programı +300ml

  // Sağlık Durumu Düzeltmeleri
  static const int healthEffectDiabetesMl = 200;   // Diyabet hastalarında +200ml

  // Sınırlar
  static const int absoluteMinWaterMl = 1500;      // Alınabilecek en az su hedefi
  static const int absoluteMaxWaterMl = 5000;      // Alınabilecek en fazla su hedefi
}
