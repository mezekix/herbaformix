import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:herbaformix/core/logger.dart';

/// Gemini ile bir metindeki birden fazla yemeği ayrı kalori kayıtlarına ayırır.
class FoodEstimationService {
  static const String _apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
  static const String _modelName = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-2.5-flash',
  );

  GenerativeModel? _model;

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
            'items': Schema.array(
              description: 'Tarifteki ayrı yemekler, en fazla sekiz öğe',
              items: Schema.object(
                properties: {
                  'name': Schema.string(description: 'Yemeğin Türkçe adı'),
                  'servingDesc': Schema.string(
                    description: '1 porsiyon, 100 g, 1 bardak gibi porsiyon',
                  ),
                  'calories': Schema.integer(
                    description: 'Bu porsiyonun kcal değeri',
                  ),
                  'confidence': Schema.string(
                    description: 'high, medium veya low',
                  ),
                },
                requiredProperties: ['name', 'servingDesc', 'calories'],
              ),
            ),
          },
          requiredProperties: ['items'],
        ),
      ),
      systemInstruction: Content.system(
        'Sen Türk mutfağı konusunda uzman bir beslenme asistanısın. '
        'Kullanıcının tarifindeki her ayrı yemeği items listesine tek tek koy; '
        'ana yemek, pilav veya makarna, çorba, salata, tatlı ve içecekleri '
        'birbirine birleştirme. Porsiyon belirtilmemişse Türkiye’de yaygın ev '
        'porsiyonunu kullan. Mantı, dolma, kısır, menemen, kuru fasulye-pilav, '
        'gözleme ve benzeri yerel yemekleri Türkçe adlandır. Belirsizlikte '
        'confidence="low" dön. Yanıt yalnızca şemaya uygun Türkçe JSON olmalı. '
        'Tanımsız veya yiyecek olmayan bir ifade için tek item olarak '
        'name="bilinmiyor", calories=0 ve confidence="low" döndür.',
      ),
    );
  }

  Future<FoodEstimate> estimate(String foodDescription) async {
    final query = foodDescription.trim();
    if (query.isEmpty) {
      throw const FoodEstimationException('Lütfen bir yemek tanımı yaz.');
    }

    final model = _ensureModel();
    for (var attempt = 1; attempt <= 3; attempt++) {
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

        final estimate = FoodEstimate.fromJson(
          jsonDecode(text) as Map<String, dynamic>,
        );
        if (estimate.items.isEmpty || estimate.totalCalories <= 0) {
          throw const FoodEstimationException(
            'Bu yemek tanınamadı. Yemeği farklı ifade et veya elle ekle.',
          );
        }
        return estimate;
      } on FoodEstimationException {
        rethrow;
      } catch (error) {
        if (attempt == 3) {
          AppLogger.error(
            '[FoodEstimationService] retry failed: $error',
            tag: 'FoodEstimationService',
            error: error,
          );
          throw const FoodEstimationException(
            'Tahmin başarısız oldu. Bağlantını kontrol edip tekrar dene.',
          );
        }
        AppLogger.warning(
          '[FoodEstimationService] retry $attempt/3: $error',
          tag: 'FoodEstimationService',
        );
        await Future<void>.delayed(Duration(seconds: 2 * attempt));
      }
    }
    throw const FoodEstimationException('Beklenmeyen hata oluştu.');
  }
}

class FoodEstimate {
  final List<FoodEstimateItem> items;

  const FoodEstimate({required this.items});

  factory FoodEstimate.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    if (rawItems is List) {
      return FoodEstimate(
        items: rawItems
            .whereType<Map>()
            .map(
              (item) => FoodEstimateItem.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .where((item) => item.name.isNotEmpty && item.calories > 0)
            .take(8)
            .toList(growable: false),
      );
    }

    // Eski tek-yemek yanıtlarıyla geriye uyumluluk.
    return FoodEstimate(items: [FoodEstimateItem.fromJson(json)]);
  }

  int get totalCalories =>
      items.fold(0, (total, item) => total + item.calories);
}

class FoodEstimateItem {
  final String name;
  final String servingDesc;
  final int calories;
  final String confidence;

  const FoodEstimateItem({
    required this.name,
    required this.servingDesc,
    required this.calories,
    required this.confidence,
  });

  factory FoodEstimateItem.fromJson(Map<String, dynamic> json) {
    return FoodEstimateItem(
      name: (json['name'] as String? ?? '').trim(),
      servingDesc: (json['servingDesc'] as String? ?? '1 porsiyon').trim(),
      calories: (json['calories'] as num?)?.round() ?? 0,
      confidence: (json['confidence'] as String? ?? 'medium').toLowerCase(),
    );
  }

  String get displayName => '$name ($servingDesc)';
}

class FoodEstimationException implements Exception {
  final String message;
  const FoodEstimationException(this.message);

  @override
  String toString() => message;
}
