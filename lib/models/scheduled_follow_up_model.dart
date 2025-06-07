import 'package:cloud_firestore/cloud_firestore.dart';

/// Gelecekte yapılması planlanmış bir takip görevini temsil eden veri modeli.
class ScheduledFollowUpModel {
  /// Firestore'daki dokümanın benzersiz kimliği (ID).
  final String id;

  /// Bu görevin hangi danışmana atandığını belirtir.
  /// Ana sayfadaki "ajandam" sorgusu için bu alana ihtiyacımız var.
  final String consultantId;

  /// Bu görevin hangi müşteriye ait olduğunu belirtir.
  final String customerId;

  /// Müşterinin adı. Ana sayfada müşteri bilgilerini tekrar çekmemek için
  /// burada "denormalize" ederek (kopyasını tutarak) saklıyoruz. Bu, performansı artırır.
  final String customerFirstName;

  /// Müşterinin soyadı. Tıpkı adı gibi, performansı artırmak için burada saklanır.
  final String customerLastName;

  /// Bu takip görevinin yapılması gereken son tarih.
  final Timestamp dueDate;

  /// Görevin başlığı. Örneğin: "3. Gün Kontrolü".
  final String title;

  /// Bu görevin tamamlanıp tamamlanmadığını belirten bayrak.
  /// Kullanıcı takip görüşmesi eklediğinde bu `true` olarak güncellenir.
  bool isCompleted;

  ScheduledFollowUpModel({
    required this.id,
    required this.consultantId,
    required this.customerId,
    required this.customerFirstName,
    required this.customerLastName,
    required this.dueDate,
    required this.title,
    this.isCompleted = false,
  });

  /// Firestore'dan gelen Map verisini ScheduledFollowUpModel nesnesine dönüştürür.
  factory ScheduledFollowUpModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return ScheduledFollowUpModel(
      id: documentId,
      consultantId: map['consultantId'] ?? '',
      customerId: map['customerId'] ?? '',
      customerFirstName: map['customerFirstName'] ?? '',
      customerLastName: map['customerLastName'] ?? '',
      dueDate: map['dueDate'] as Timestamp? ?? Timestamp.now(),
      title: map['title'] ?? 'Planlanmış Görev',
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  /// ScheduledFollowUpModel nesnesini Firestore'a yazmak için Map'e dönüştürür.
  Map<String, dynamic> toMap() {
    return {
      'consultantId': consultantId,
      'customerId': customerId,
      'customerFirstName': customerFirstName,
      'customerLastName': customerLastName,
      'dueDate': dueDate,
      'title': title,
      'isCompleted': isCompleted,
    };
  }
}
