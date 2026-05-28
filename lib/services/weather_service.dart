import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class WeatherService {
  // Önemli değerler string olarak tanımlanmalı
  static const String defaultCity = 'Istanbul';
  // OpenWeatherMap API anahtarı. Canlı ortamda güvenli bir yerde tutulmalıdır.
  static const String apiKey = 'YOUR_OPENWEATHERMAP_API_KEY'; 

  Future<({double temp, double humidity, String status})?> fetchWeather(String? city) async {
    final queryCity = (city == null || city.trim().isEmpty) ? defaultCity : city.trim();
    
    // API anahtarı girilmemişse veya yer tutucuysa API isteği atmadan hata dön
    if (apiKey == 'YOUR_OPENWEATHERMAP_API_KEY' || apiKey.isEmpty) {
      debugPrint('WeatherService: API anahtarı tanımlanmamış.');
      return null;
    }

    try {
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=$queryCity&appid=$apiKey&units=metric&lang=tr',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final main = data['main'] as Map<String, dynamic>;
        final weatherList = data['weather'] as List<dynamic>;
        
        final double temp = (main['temp'] as num).toDouble();
        final double humidity = (main['humidity'] as num).toDouble();
        final String status = weatherList.isNotEmpty 
            ? (weatherList[0]['main'] as String? ?? 'clouds').toLowerCase() 
            : 'clouds';

        return (temp: temp, humidity: humidity, status: status);
      } else {
        debugPrint('WeatherService API Hatası: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('WeatherService Exception: $e');
      return null;
    }
  }
}
