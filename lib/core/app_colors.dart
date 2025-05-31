import 'package:flutter/material.dart';

class AppColors {
  // Ana Renkler (Paletten)
  static const Color garden = Color(0xFF266431); // Ana Yeşil
  static const Color white = Color(0xFFFFFFFF);
  static const Color rosemary = Color(0xFF3A5137); // Koyu Yeşil
  static const Color aqua = Color(0xFF78E3D7); // Açık Mavi/Yeşil

  // Vurgu ve Diğer Renkler (Paletten)
  static const Color mango = Color(0xFFEFAC29); // Sarı/Turuncu
  static const Color blueberry = Color(0xFF4A28A9); // Mor
  static const Color papaya = Color(0xFFD24A39); // Kırmızı/Turuncu
  static const Color bay = Color(0xFF224945); // Çok Koyu Yeşil/Mavi

  static const Color rain = Color(0xFFDDFCFF); // Çok Açık Mavi
  static const Color laguna = Color(0xFF3A70C2); // Mavi
  static const Color sunflower = Color(0xFFFFF176); // Açık Sarı
  static const Color grass = Color(0xFF42A146); // Canlı Yeşil

  static const Color lake = Color(0xFF3B9187); // Turkuaz Yeşil
  static const Color nightSky = Color(0xFF101820); // Çok Koyu Gri/Siyah

  // Uygulama için seçilen birincil ve ikincil renkler
  static const Color primary = garden;
  static const Color secondary = grass; // Veya mango, aqua gibi bir vurgu
  static const Color accent = mango; // Vurgu için başka bir seçenek
  static const Color background = Color(0xFFF5F5F5); // Biraz daha yumuşak bir arka plan
  static const Color surface = white;
  static const Color error = papaya; // Hata rengi için

  static const Color textPrimary = nightSky;
  static const Color textSecondary = Color(0xFF575757); // rosemary'nin açığı gibi
  static const Color textOnPrimary = white;
  static const Color textOnSecondary = white;
}