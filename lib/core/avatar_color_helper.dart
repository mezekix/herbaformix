import 'package:flutter/material.dart';

/// Kullanıcı ID'sine göre deterministik, tutarlı avatar arka plan rengi üretir.
/// Aynı ID her zaman aynı rengi verir.
class AvatarColorHelper {
  AvatarColorHelper._();

  // Pastel ama ayırt edici renkler — beyaz metin üzerinde okunabilir
  static const List<Color> _palette = [
    Color(0xFF4CAF50), // yeşil
    Color(0xFF2196F3), // mavi
    Color(0xFF9C27B0), // mor
    Color(0xFFFF5722), // turuncu-kırmızı
    Color(0xFF009688), // teal
    Color(0xFFE91E63), // pembe
    Color(0xFF3F51B5), // indigo
    Color(0xFFFF9800), // turuncu
    Color(0xFF795548), // kahve
    Color(0xFF607D8B), // mavi-gri
    Color(0xFF00BCD4), // cyan
    Color(0xFF8BC34A), // açık yeşil
  ];

  /// [userId] için deterministik renk döner.
  /// [userId] boşsa varsayılan primary renk döner.
  static Color forUser(String? userId) {
    if (userId == null || userId.isEmpty) {
      return const Color(0xFF4CAF50);
    }
    // Basit hash: karakterlerin code unit toplamı
    int hash = 0;
    for (final char in userId.codeUnits) {
      hash = (hash * 31 + char) & 0x7FFFFFFF;
    }
    return _palette[hash % _palette.length];
  }

  /// Avatar için metin rengi — arka plan rengine göre beyaz veya siyah
  static Color textColorFor(Color bg) {
    // Luminance hesabı
    final luminance = bg.computeLuminance();
    return luminance > 0.4 ? Colors.black87 : Colors.white;
  }
}
