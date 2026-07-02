import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:herbaformix/core/logger.dart';

/// Gemini Flash modeline yemek adı verip tahmini kalori bilgisini alır.
///
/// Yerel `food_database.json` listesinde bulunmayan yemekler için kullanıcının
/// "AI ile tahmin et" akışında çağrılır.
///
/// **API anahtarı yönetimi** — `--dart-define=GEMINI_API_KEY=...` ile compile
/// zamanı inject edilir:
/// ```
/// flutter run --dart-define=GEMINI_API_KEY=AIza...
/// ```
/// Google Cloud Console'da bu anahtara Android package name + SHA-1
/// kısıtlaması mutlaka koyulmalıdır — APK decompile edilse bile farklı bir
/// uygulamadan kullanılamasın.
///
/// **Free tier**: Gemini Flash dakikada 15, günde 1500 ücretsiz istek.
/// Üzeri Google'ın faturalandırma kurallarına tabidir.
class FoodEstimationService {
  static const String _apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// Gemini Flash — hızlı, ucuz, kalori tahmini için fazlasıyla yeterli.
  /// `gemini-2.5-flash` Eylül 2025 sonrası kullanılabilen en yeni stabil
  /// model; daha eski `1.5-flash` ve `1.0` aileleri deprecate edildi.
  ///
  /// Build sırasında değiştirmek için:
  /// `--dart-define=GEMINI_MODEL=gemini-2.0-flash`
  ///
  /// Free tier kota hatası alırsan:
  /// - 5 sn bekleyip tekrar dene (RPM aşımı normal)
  /// - veya Google Cloud Console'da billing'i aktive et (paid tier limit yok denecek kadar geniş)
  static const String _modelName = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-2.5-flash',
  );

  GenerativeModel? _model;

  /// API anahtarı set edilmiş mi? UI butonu disable etmek için kontrol eder.
  static bool get isConfigured => _apiKey.isNotEmpty;

  GenerativeModel _ensureModel() {
    if (!isConfigured) {
      throw const FoodEstimationException(
        'Gemini API anahtarı yapılandırılmamış. '
        '`flutter run --dart-define=GEMINI_API_KEY=...` ile başlat.',
      );
    }
    return _model ??= GenerativeModel(
      model: _modelName,
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.2,
        responseMimeType: 'application/json',
        responseSchema: Schema.object(
          properties: {
            'name': Schema.string(description: 'Yemeğin temiz, düzgün adı'),
            'servingDesc': Schema.string(
              description: '1 porsiyon, 100g, 1 bardak gibi tipik porsiyon',
            ),
            'calories': Schema.integer(
              description: 'Belirtilen porsiyon için tahmini kalori (kcal)',
            ),
            'confidence': Schema.string(
              description: '"high", "medium" veya "low"',
            ),
          },
          requiredProperties: ['name', 'servingDesc', 'calories'],
        ),
      ),
      systemInstruction: Content.system(
        'Sen bir Türk mutfağı beslenme uzmanısın. Kullanıcı bir yemek adı '
        'verdiğinde, tipik bir porsiyon için ortalama kalori tahmini '
        'yaparsın. Yanıt KESİNLİKLE JSON şemasına uymalı. Türkçe yanıtla. '
        'Yemek tanınmıyorsa veya yiyecek olarak anlamsızsa, name="bilinmiyor" '
        've calories=0 dön. Tahminin sapma payı ±%25 civarında olmalı; çok '
        'genel veya çok abartılı sayılar verme. servingDesc kısa olsun '
        '(örn: "1 porsiyon", "100 gram", "1 bardak", "1 dilim").',
      ),
    );
  }

  /// Verilen yemek tanımını Gemini'ye gönderip tahmini kalori sonucunu döner.
  ///
  /// Throws [FoodEstimationException] eğer:
  /// - API anahtarı yapılandırılmamışsa
  /// - Gemini erişilemez/timeout
  /// - Yanıt parse edilemezse
  /// - Yemek "bilinmiyor" döner (UI bunu farklı handle eder)
  Future<FoodEstimate> estimate(String foodDescription) async {
    final query = foodDescription.trim();
    if (query.isEmpty) {
      throw const FoodEstimationException('Lütfen bir yemek adı yaz.');
    }

    int attempt = 0;
    const maxRetries = 3;
    final model = _ensureModel();

    while (attempt < maxRetries) {
      try {
        final response = await model
            .generateContent([Content.text(query)])
            .timeout(const Duration(seconds: 20));

        final text = response.text;
        if (text == null || text.trim().isEmpty) {
          throw const FoodEstimationException(
            'Yapay zekadan boş yanıt geldi. Tekrar dene.',
          );
        }

        final json = jsonDecode(text) as Map<String, dynamic>;
        final estimate = FoodEstimate.fromJson(json);

        if (estimate.calories <= 0 ||
            estimate.name.toLowerCase().contains('bilinmiyor')) {
          throw const FoodEstimationException(
            'Bu yemek tanınamadı. Yemeği farklı ifade etmeyi dene veya elle ekle.',
          );
        }

        return estimate;
      } on FoodEstimationException {
        // Beklenen/iş mantığı hatalarını (Yemek tanınmadı vb.) tekrar denemeye gerek yok.
        rethrow;
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) {
          AppLogger.error('[FoodEstimationService] hata (retry failed): $e', tag: 'FoodEstimationService', error: e);
          throw FoodEstimationException(
            'Tahmin başarısız (Ağ veya sunucu hatası olabilir). Lütfen tekrar deneyin.',
          );
        }
        AppLogger.warning('[FoodEstimationService] hata: $e, retry $attempt/$maxRetries', tag: 'FoodEstimationService');
        await Future.delayed(Duration(seconds: 2 * attempt)); // Exponential-ish backoff
      }
    }
    
    throw const FoodEstimationException('Beklenmeyen hata oluştu.');
  }
}

/// Gemini'den dönen kalori tahmin sonucu.
class FoodEstimate {
  final String name;
  final String servingDesc;
  final int calories;

  /// "high" / "medium" / "low" — kullanıcıya güven aralığı bilgisi.
  /// Gemini her zaman dönmeyebilir; eksikse "medium" varsayılır.
  final String confidence;

  const FoodEstimate({
    required this.name,
    required this.servingDesc,
    required this.calories,
    required this.confidence,
  });

  factory FoodEstimate.fromJson(Map<String, dynamic> json) {
    return FoodEstimate(
      name: (json['name'] as String? ?? '').trim(),
      servingDesc: (json['servingDesc'] as String? ?? '1 porsiyon').trim(),
      calories: (json['calories'] as num?)?.round() ?? 0,
      confidence: (json['confidence'] as String? ?? 'medium').toLowerCase(),
    );
  }

  /// Kullanıcıya gösterilen "Tavuklu Pilav (1 porsiyon)" formatı.
  String get displayName => '$name ($servingDesc)';
}

class FoodEstimationException implements Exception {
  final String message;
  const FoodEstimationException(this.message);

  @override
  String toString() => message;
}
