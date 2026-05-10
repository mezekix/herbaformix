// Bu dosya, davet kodu verilerini temsil eden model sınıfını içerir.
// Distribütörler tarafından oluşturulan ve müşteri kaydında kullanılan
// davet kodlarını Firestore ile senkronize eder.
import 'package:cloud_firestore/cloud_firestore.dart';

class InviteCodeModel {
  final String id;             // Firestore doküman ID'si
  final String code;           // 8 karakterlik büyük harf + rakam (örn. "A3BX9K2M")
  final String distributorId;  // Kodu oluşturan distribütörün UID'si
  final DateTime createdAt;    // Oluşturulma zamanı
  final bool isUsed;           // Kod kullanıldı mı?
  final String? usedByUserId;  // Kodu kullanan müşterinin UID'si (opsiyonel)

  const InviteCodeModel({
    required this.id,
    required this.code,
    required this.distributorId,
    required this.createdAt,
    required this.isUsed,
    this.usedByUserId,
  });

  /// Firestore dokümanından [InviteCodeModel] oluşturur.
  ///
  /// [map] Firestore'dan gelen alan-değer çiftleri.
  /// [id] Firestore doküman ID'si.
  ///
  /// `createdAt` alanı için Firestore [Timestamp] → [DateTime] dönüşümü yapılır.
  factory InviteCodeModel.fromMap(Map<String, dynamic> map, String id) {
    // createdAt: Firestore Timestamp → DateTime dönüşümü
    DateTime createdAt;
    final rawCreatedAt = map['createdAt'];
    if (rawCreatedAt is Timestamp) {
      createdAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is int) {
      // Milisaniye cinsinden int olarak saklanmışsa da destekle
      createdAt = DateTime.fromMillisecondsSinceEpoch(rawCreatedAt);
    } else {
      // Beklenmedik tür veya null ise şimdiki zamanı kullan
      createdAt = DateTime.now();
    }

    return InviteCodeModel(
      id: id,
      code: map['code'] as String? ?? '',
      distributorId: map['distributorId'] as String? ?? '',
      createdAt: createdAt,
      isUsed: map['isUsed'] as bool? ?? false,
      usedByUserId: map['usedByUserId'] as String?,
    );
  }

  /// [InviteCodeModel]'i Firestore'a yazmak için [Map]'e dönüştürür.
  ///
  /// `createdAt` alanı Firestore [Timestamp] olarak saklanır.
  /// `usedByUserId` null ise map'e dahil edilmez.
  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'distributorId': distributorId,
      'createdAt': Timestamp.fromDate(createdAt),
      'isUsed': isUsed,
      if (usedByUserId != null) 'usedByUserId': usedByUserId,
    };
  }

  /// Mevcut modeli belirtilen alanlarla kopyalar.
  InviteCodeModel copyWith({
    String? id,
    String? code,
    String? distributorId,
    DateTime? createdAt,
    bool? isUsed,
    String? usedByUserId,
  }) {
    return InviteCodeModel(
      id: id ?? this.id,
      code: code ?? this.code,
      distributorId: distributorId ?? this.distributorId,
      createdAt: createdAt ?? this.createdAt,
      isUsed: isUsed ?? this.isUsed,
      usedByUserId: usedByUserId ?? this.usedByUserId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InviteCodeModel &&
        other.id == id &&
        other.code == code &&
        other.distributorId == distributorId &&
        other.createdAt == createdAt &&
        other.isUsed == isUsed &&
        other.usedByUserId == usedByUserId;
  }

  @override
  int get hashCode => Object.hash(
        id,
        code,
        distributorId,
        createdAt,
        isUsed,
        usedByUserId,
      );

  @override
  String toString() {
    return 'InviteCodeModel('
        'id: $id, '
        'code: $code, '
        'distributorId: $distributorId, '
        'createdAt: $createdAt, '
        'isUsed: $isUsed, '
        'usedByUserId: $usedByUserId'
        ')';
  }
}
