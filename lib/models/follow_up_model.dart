import 'package:cloud_firestore/cloud_firestore.dart';

/// Takip görüşmesinin türünü belirtmek için kullanılır.
/// Örneğin, telefon görüşmesi mi, WhatsApp mesajı mı?
enum FollowUpType { phoneCall, whatsappMessage, email, inPerson }

/// Takip görüşmesinin durumunu belirtir.
/// Tamamlandı mı, yoksa aksiyon alınması mı gerekiyor?
enum FollowUpStatus { completed, requiresAction }

/// Müşteri ile yapılan her bir takip etkileşimini temsil eden veri modeli.
class FollowUpModel {
  /// Firestore'daki dokümanın benzersiz kimliği (ID).
  final String id;

  /// Bu takibin hangi müşteriye ait olduğunu belirtir.
  final String customerId;

  /// Bu takibi hangi danışmanın yaptığını belirtir.
  final String consultantId;

  /// Takip görüşmesinin yapıldığı tarih ve saat.
  final Timestamp date;

  /// Görüşmenin türü (Telefon, WhatsApp vb.).
  final FollowUpType type;

  /// Görüşmenin durumu (Tamamlandı, Aksiyon Gerekiyor vb.).
  final FollowUpStatus status;

  /// Görüşme sırasında alınan notlar.
  /// Müşterinin geri bildirimleri, şikayetleri, memnuniyeti vb.
  final String notes;

  /// Bir sonraki takip görüşmesinin planlandığı tarih (opsiyonel).
  /// Müşteriyle bir sonraki temasın ne zaman olacağını belirler.
  final Timestamp? nextFollowUpDate;

  FollowUpModel({
    required this.id,
    required this.customerId,
    required this.consultantId,
    required this.date,
    required this.type,
    required this.status,
    required this.notes,
    this.nextFollowUpDate,
  });

  /// Firestore'dan gelen Map verisini FollowUpModel nesnesine dönüştürür.
  /// Veritabanından veri okurken bu metot kullanılır.
  factory FollowUpModel.fromMap(Map<String, dynamic> map, String documentId) {
    return FollowUpModel(
      id: documentId,
      customerId: map['customerId'] ?? '',
      consultantId: map['consultantId'] ?? '',
      date: map['date'] as Timestamp? ?? Timestamp.now(),
      type: FollowUpType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => FollowUpType.phoneCall, // Varsayılan değer
      ),
      status: FollowUpStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => FollowUpStatus.completed, // Varsayılan değer
      ),
      notes: map['notes'] ?? '',
      nextFollowUpDate: map['nextFollowUpDate'] as Timestamp?,
    );
  }

  /// FollowUpModel nesnesini Firestore'a yazmak için Map'e dönüştürür.
  /// Veritabanına veri yazarken bu metot kullanılır.
  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'consultantId': consultantId,
      'date': date,
      'type': type.toString(),
      'status': status.toString(),
      'notes': notes,
      'nextFollowUpDate': nextFollowUpDate,
    };
  }
}
