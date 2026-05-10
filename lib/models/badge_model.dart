import 'package:flutter/material.dart';

/// Rozet tanımı — statik liste olarak tutulur, kazanılan ID'ler Firestore'da saklanır.
class BadgeDefinition {
  final String id;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const BadgeDefinition({
    required this.id,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });
}

/// Tüm rozet tanımları — uygulama genelinde sabit liste.
class AppBadges {
  static const List<BadgeDefinition> all = [
    BadgeDefinition(
      id: 'first_entry',
      label: 'İlk Adım',
      icon: Icons.flag,
      iconColor: Color(0xFF7AC144),
      bgColor: Color(0xFFACF772),
    ),
    BadgeDefinition(
      id: 'streak_7',
      label: '7 Gün Seri',
      icon: Icons.military_tech,
      iconColor: Color(0xFF7AC144),
      bgColor: Color(0xFFACF772),
    ),
    BadgeDefinition(
      id: 'streak_30',
      label: '30 Gün Seri',
      icon: Icons.emoji_events,
      iconColor: Color(0xFFEFAC29),
      bgColor: Color(0xFFFFF9C4),
    ),
    BadgeDefinition(
      id: 'lost_1kg',
      label: '1 KG Kayıp',
      icon: Icons.trending_down,
      iconColor: Color(0xFF3B9187),
      bgColor: Color(0xFFDDFCFF),
    ),
    BadgeDefinition(
      id: 'lost_5kg',
      label: '5 KG Kayıp',
      icon: Icons.star,
      iconColor: Color(0xFFEFAC29),
      bgColor: Color(0xFFFFF9C4),
    ),
    BadgeDefinition(
      id: 'goal_reached',
      label: 'Hedefe Ulaştı',
      icon: Icons.check_circle,
      iconColor: Color(0xFF7AC144),
      bgColor: Color(0xFFACF772),
    ),
    BadgeDefinition(
      id: 'measurement_added',
      label: 'Ölçüm Ustası',
      icon: Icons.straighten,
      iconColor: Color(0xFF9E3774),
      bgColor: Color(0xFFFFD8E8),
    ),
    BadgeDefinition(
      id: 'photo_added',
      label: 'Dönüşüm Fotoğrafı',
      icon: Icons.add_a_photo,
      iconColor: Color(0xFF3A70C2),
      bgColor: Color(0xFFDDFCFF),
    ),
  ];

  static BadgeDefinition? findById(String id) {
    try {
      return all.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }
}
