import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../features/calorie_tracker/models/food_item.dart';

/// `assets/food_database.json`'dan yemek listesini lazy yükler ve Türkçe
/// karakter normalize edilmiş arama sağlar.
///
/// - **Lazy load**: ilk [search] / [getAll] çağrısında yüklenir, sonra
///   bellekte tutulur.
/// - **Türkçe normalize**: arama kelimesi de yemek isimleri de aynı
///   normalize fonksiyonundan geçer; "tavuklu pilav" yazınca "Tavuklu Pilav"ı,
///   "tavuk pilav" yazınca da aynı sonucu bulur (alias eşleşmesiyle).
///
/// Singleton — paylaşımlı asset olduğundan tüm provider'lar tek bir instance
/// üzerinden çalışır.
class FoodRepository {
  FoodRepository._();
  static final FoodRepository instance = FoodRepository._();

  List<FoodItem>? _cache;
  Future<void>? _loadFuture;

  /// JSON'u yükler (asset'ten okur, parse eder). İdempotent —
  /// concurrent çağrılarda bile tek seferde yüklenir.
  Future<void> _ensureLoaded() {
    if (_cache != null) return Future.value();
    return _loadFuture ??= _load();
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString('assets/food_database.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final items = (json['items'] as List<dynamic>)
          .map((e) => FoodItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      _cache = items;
      debugPrint('[FoodRepository] ${items.length} yemek yüklendi.');
    } catch (e) {
      debugPrint('[FoodRepository] yükleme hatası: $e');
      _cache = const [];
    } finally {
      _loadFuture = null;
    }
  }

  /// Tüm yemek listesini döner.
  Future<List<FoodItem>> getAll() async {
    await _ensureLoaded();
    return _cache ?? const [];
  }

  /// [query]'ye göre eşleşen yemekleri döner. Boş query ise ilk 20 yemek
  /// dönülür (genel keşif için).
  ///
  /// Eşleşme önceliği:
  /// 1. İsmi `query` ile **başlayan** yemekler
  /// 2. İsmi `query` **içeren** yemekler
  /// 3. Alias'larından biri eşleşen yemekler
  Future<List<FoodItem>> search(String query, {int limit = 50}) async {
    await _ensureLoaded();
    final items = _cache ?? const <FoodItem>[];
    final normalized = _normalize(query.trim());

    if (normalized.isEmpty) {
      // Boş query — popüler/genel bir karışım göster (ilk 20)
      return items.take(20).toList();
    }

    final startsWith = <FoodItem>[];
    final contains = <FoodItem>[];
    final aliasMatch = <FoodItem>[];

    for (final item in items) {
      final name = _normalize(item.name);
      if (name.startsWith(normalized)) {
        startsWith.add(item);
        continue;
      }
      if (name.contains(normalized)) {
        contains.add(item);
        continue;
      }
      final hitAlias = item.aliases.any(
        (a) => _normalize(a).contains(normalized),
      );
      if (hitAlias) {
        aliasMatch.add(item);
      }
    }

    final merged = [...startsWith, ...contains, ...aliasMatch];
    if (merged.length <= limit) return merged;
    return merged.take(limit).toList();
  }

  /// Türkçe karakterleri ASCII'ye çevirir, küçük harfe alır, fazla boşlukları
  /// temizler. Arama ve veri her ikisi de bundan geçer — kullanıcı "şeftali"
  /// yazsa "seftali" yazsa da bulunur.
  static String _normalize(String input) {
    final lower = input.toLowerCase();
    final buffer = StringBuffer();
    for (final code in lower.runes) {
      final ch = String.fromCharCode(code);
      switch (ch) {
        case 'ı':
          buffer.write('i');
          break;
        case 'ş':
          buffer.write('s');
          break;
        case 'ç':
          buffer.write('c');
          break;
        case 'ğ':
          buffer.write('g');
          break;
        case 'ü':
          buffer.write('u');
          break;
        case 'ö':
          buffer.write('o');
          break;
        case 'â':
        case 'à':
        case 'á':
          buffer.write('a');
          break;
        case 'î':
        case 'ï':
        case 'í':
          buffer.write('i');
          break;
        case 'û':
        case 'ù':
        case 'ú':
          buffer.write('u');
          break;
        default:
          buffer.write(ch);
      }
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
