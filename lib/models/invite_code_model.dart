// Bu dosya, davet kodu verilerini temsil eden model sınıfını içerir.
// Distribütörler tarafından oluşturulan ve müşteri kaydında kullanılan
// davet kodlarını Firestore ile senkronize eder.
import 'package:cloud_firestore/cloud_firestore.dart';

import 'invite_status.dart';

/// Davet kodunun varsayılan geçerlilik süresi.
const Duration kInviteCodeDefaultValidity = Duration(days: 7);

class InviteCodeModel {
  final String id; // Firestore doküman ID'si
  final String code; // 8 karakterlik büyük harf + rakam (örn. "A3BX9K2M")
  final String distributorId; // Kodu oluşturan distribütörün UID'si
  final DateTime createdAt; // Oluşturulma zamanı
  final DateTime expiresAt; // Geçerlilik bitiş zamanı (createdAt + 7 gün)
  final InviteStatus status; // pending / used / expired
  final bool isUsed; // Geriye uyumluluk: status == used ile aynı bilgiyi tutar
  final String? usedByUserId; // Kodu kullanan müşterinin UID'si

  // Müşteri-spesifik alanlar (distribütör müşteri eklerken doldurur).
  final String? customerRecordId; // users/{distId}/customers/{customerId} doc ID'si
  final String? customerName; // Distribütörün girdiği ad (UI ve WhatsApp metni için)
  final String? customerPhone; // WhatsApp gönderimi için telefon
  final String? customerEmail; // Opsiyonel; ileride e-posta gönderimi için

  const InviteCodeModel({
    required this.id,
    required this.code,
    required this.distributorId,
    required this.createdAt,
    required this.expiresAt,
    required this.status,
    required this.isUsed,
    this.usedByUserId,
    this.customerRecordId,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
  });

  /// Şu an süresi dolmuş mu? (status'tan bağımsız, sadece zamana bakar.)
  bool get isExpiredByTime => DateTime.now().isAfter(expiresAt);

  /// Hem status'a hem de süreye göre etkin durumu hesaplar.
  ///
  /// Eski belgelerde `status` `pending` olsa bile `expiresAt` geçmişse
  /// effective olarak `expired` döner.
  InviteStatus get effectiveStatus {
    if (status == InviteStatus.used) return InviteStatus.used;
    if (status == InviteStatus.expired) return InviteStatus.expired;
    if (isExpiredByTime) return InviteStatus.expired;
    return InviteStatus.pending;
  }

  /// Firestore dokümanından [InviteCodeModel] oluşturur.
  ///
  /// Geriye dönük uyumluluk:
  /// - `status` yoksa `isUsed ? used : pending` fallback'i kullanılır.
  /// - `expiresAt` yoksa `createdAt + 7 gün` fallback'i kullanılır.
  /// - Yeni müşteri-spesifik alanlar yoksa `null` kalır.
  factory InviteCodeModel.fromMap(Map<String, dynamic> map, String id) {
    final createdAt = _parseDate(map['createdAt']) ?? DateTime.now();
    final isUsed = map['isUsed'] as bool? ?? false;

    final expiresAt = _parseDate(map['expiresAt']) ??
        createdAt.add(kInviteCodeDefaultValidity);

    final statusFromMap = inviteStatusFromString(map['status'] as String?);
    final status = statusFromMap ??
        (isUsed ? InviteStatus.used : InviteStatus.pending);

    return InviteCodeModel(
      id: id,
      code: map['code'] as String? ?? '',
      distributorId: map['distributorId'] as String? ?? '',
      createdAt: createdAt,
      expiresAt: expiresAt,
      status: status,
      isUsed: isUsed,
      usedByUserId: map['usedByUserId'] as String?,
      customerRecordId: map['customerRecordId'] as String?,
      customerName: map['customerName'] as String?,
      customerPhone: map['customerPhone'] as String?,
      customerEmail: map['customerEmail'] as String?,
    );
  }

  /// [InviteCodeModel]'i Firestore'a yazmak için [Map]'e dönüştürür.
  ///
  /// Yeni alanlar her zaman map'e dahil edilir; null olan opsiyonel alanlar
  /// map'e eklenmez.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'code': code,
      'distributorId': distributorId,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'status': status.toFirestore(),
      'isUsed': isUsed,
    };
    if (usedByUserId != null) map['usedByUserId'] = usedByUserId;
    if (customerRecordId != null) map['customerRecordId'] = customerRecordId;
    if (customerName != null) map['customerName'] = customerName;
    if (customerPhone != null) map['customerPhone'] = customerPhone;
    if (customerEmail != null) map['customerEmail'] = customerEmail;
    return map;
  }

  /// Mevcut modeli belirtilen alanlarla kopyalar.
  InviteCodeModel copyWith({
    String? id,
    String? code,
    String? distributorId,
    DateTime? createdAt,
    DateTime? expiresAt,
    InviteStatus? status,
    bool? isUsed,
    String? usedByUserId,
    String? customerRecordId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
  }) {
    return InviteCodeModel(
      id: id ?? this.id,
      code: code ?? this.code,
      distributorId: distributorId ?? this.distributorId,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      isUsed: isUsed ?? this.isUsed,
      usedByUserId: usedByUserId ?? this.usedByUserId,
      customerRecordId: customerRecordId ?? this.customerRecordId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
    );
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is DateTime) return raw;
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InviteCodeModel &&
        other.id == id &&
        other.code == code &&
        other.distributorId == distributorId &&
        other.createdAt == createdAt &&
        other.expiresAt == expiresAt &&
        other.status == status &&
        other.isUsed == isUsed &&
        other.usedByUserId == usedByUserId &&
        other.customerRecordId == customerRecordId &&
        other.customerName == customerName &&
        other.customerPhone == customerPhone &&
        other.customerEmail == customerEmail;
  }

  @override
  int get hashCode => Object.hash(
        id,
        code,
        distributorId,
        createdAt,
        expiresAt,
        status,
        isUsed,
        usedByUserId,
        customerRecordId,
        customerName,
        customerPhone,
        customerEmail,
      );

  @override
  String toString() {
    return 'InviteCodeModel('
        'id: $id, '
        'code: $code, '
        'distributorId: $distributorId, '
        'createdAt: $createdAt, '
        'expiresAt: $expiresAt, '
        'status: $status, '
        'isUsed: $isUsed, '
        'usedByUserId: $usedByUserId, '
        'customerRecordId: $customerRecordId, '
        'customerName: $customerName, '
        'customerPhone: $customerPhone'
        ')';
  }
}
