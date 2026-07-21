import 'package:cloud_firestore/cloud_firestore.dart';

enum AppNotificationType {
  program,
  water,
  measurement,
  badge,
  followUp,
  order,
  message,
  challenge,
  motivation,
  distributorRequest,
  roleChange;

  String get firestoreValue => switch (this) {
    AppNotificationType.followUp => 'follow_up',
    AppNotificationType.distributorRequest => 'distributor_request',
    AppNotificationType.roleChange => 'role_change',
    _ => name,
  };

  String get label => switch (this) {
    AppNotificationType.program => 'Program',
    AppNotificationType.water => 'Su',
    AppNotificationType.measurement => 'Ölçüm',
    AppNotificationType.badge => 'Rozet',
    AppNotificationType.followUp => 'Takip',
    AppNotificationType.order => 'Sipariş',
    AppNotificationType.message => 'Mesaj',
    AppNotificationType.challenge => 'Meydan Okuma',
    AppNotificationType.motivation => 'Motivasyon',
    AppNotificationType.distributorRequest => 'Distribütörlük Başvurusu',
    AppNotificationType.roleChange => 'Rol Değişikliği',
  };

  String get preferenceKey => switch (this) {
    AppNotificationType.program => 'newProgram',
    AppNotificationType.followUp => 'followUps',
    AppNotificationType.message => 'message',
    AppNotificationType.motivation => 'dailyMessages',
    AppNotificationType.distributorRequest => 'distributorRequests',
    AppNotificationType.roleChange => 'roleChanges',
    _ => firestoreValue,
  };

  static AppNotificationType fromFirestore(String? value) {
    return AppNotificationType.values.firstWhere(
      (type) => type.firestoreValue == value,
      orElse: () => AppNotificationType.message,
    );
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
    this.readAt,
    this.actionPath,
    this.sourceId,
  });

  final String id;
  final AppNotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final DateTime? readAt;
  final String? actionPath;
  final String? sourceId;

  factory AppNotification.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return AppNotification(
      id: snapshot.id,
      type: AppNotificationType.fromFirestore(data['type'] as String?),
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      isRead: data['isRead'] as bool? ?? false,
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
      actionPath: data['actionPath'] as String?,
      sourceId: data['sourceId'] as String?,
    );
  }
}
