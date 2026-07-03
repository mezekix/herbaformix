import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/customer_model.dart';
import '../../models/follow_up_model.dart';
import '../../models/scheduled_follow_up_model.dart';
import '../../models/user_profile_model.dart';
import 'package:herbaformix/core/logger.dart';

/// Distribütörün müşteri CRM'i:
/// - `/users/{distributorId}/customers/{customerId}` (ana müşteri kayıtları)
/// - `/users/.../customers/{cid}/follow_ups/{fid}` (geçmiş takip görüşmeleri)
/// - `/scheduled_follow_ups/{id}` (planlanmış takip hatırlatıcıları)
class CustomerRepository {
  CustomerRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // ── customers ──────────────────────────────────────────────────────────

  CollectionReference<CustomerModel> customersRef(String userId) => _db
      .collection('users')
      .doc(userId)
      .collection('customers')
      .withConverter<CustomerModel>(
        fromFirestore: (s, _) => CustomerModel.fromMap(s.data()!, s.id),
        toFirestore: (m, _) => m.toMap(),
      );

  Future<DocumentReference<CustomerModel>> addCustomer(
    String userId,
    CustomerModel customer,
  ) =>
      customersRef(userId).add(customer);

  Stream<List<CustomerModel>> getCustomers(String userId) {
    return customersRef(userId)
        .orderBy('firstName')
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  Future<List<CustomerModel>> fetchAllCustomers(String userId) async {
    final s = await customersRef(userId).orderBy('firstName').get();
    return s.docs.map((d) => d.data()).toList();
  }

  Future<CustomerModel?> getCustomer(String userId, String customerId) async {
    try {
      final d = await customersRef(userId).doc(customerId).get();
      return d.exists ? d.data() : null;
    } catch (e) {
      AppLogger.error("CustomerRepository.getCustomer hatası: $e", tag: 'CustomerRepository', error: e);
      rethrow;
    }
  }

  Future<CustomerModel?> getCustomerByLinkedUserId(
    String distributorId,
    String linkedUserId,
  ) async {
    try {
      final s = await customersRef(distributorId)
          .where('linkedUserId', isEqualTo: linkedUserId)
          .limit(1)
          .get();
      if (s.docs.isEmpty) return null;
      return s.docs.first.data();
    } catch (e) {
      AppLogger.error("CustomerRepository.getCustomerByLinkedUserId hatası: $e", tag: 'CustomerRepository', error: e);
      return null;
    }
  }

  Future<CustomerModel> createCustomerRecordFromUserProfile({
    required String distributorId,
    required UserProfileModel profile,
  }) async {
    final existing = await getCustomerByLinkedUserId(distributorId, profile.id);
    if (existing != null) return existing;

    final nameParts = (profile.name ?? '').trim().split(RegExp(r'\s+'));
    final firstName = nameParts.isNotEmpty && nameParts.first.isNotEmpty
        ? nameParts.first
        : 'Müşteri';
    final lastName =
        nameParts.length > 1 ? nameParts.sublist(1).join(' ').trim() : '';

    final customerDocRef = customersRef(distributorId).doc();
    final customer = CustomerModel(
      id: customerDocRef.id,
      firstName: firstName,
      lastName: lastName,
      phoneNumber: profile.phoneNumber ?? '',
      email: profile.email,
      address: null,
      firstContactDate: Timestamp.now(),
      consultantId: distributorId,
      isActive: true,
      notes: 'Otomatik oluşturuldu',
      linkedUserId: profile.id,
      activatedAt: Timestamp.now(),
    );

    await customerDocRef.set(customer);
    return customer;
  }

  Future<void> updateCustomer(String userId, CustomerModel customer) async {
    final batch = _db.batch();

    final customerRef = customersRef(userId).doc(customer.id);
    batch.update(customerRef, customer.toMap());

    // Bağlı kullanıcı varsa profilindeki bilgileri de senkronize et
    if (customer.linkedUserId != null && customer.linkedUserId!.isNotEmpty) {
      final profileRef =
          _db.collection('userProfiles').doc(customer.linkedUserId);
      final profileUpdates = <String, dynamic>{
        'name': '${customer.firstName} ${customer.lastName}'.trim(),
        'phoneNumber': customer.phoneNumber,
      };
      if (customer.email != null) {
        profileUpdates['email'] = customer.email;
      }
      batch.update(profileRef, profileUpdates);
    }

    await batch.commit();
  }

  Future<void> deleteCustomer(String userId, String customerId) async {
    final customerDoc = await customersRef(userId).doc(customerId).get();
    final linkedUserId = customerDoc.data()?.linkedUserId;

    final batch = _db.batch();

    // 1) Müşteri dokümanı
    batch.delete(customersRef(userId).doc(customerId));

    // 2) Planlanmış takipler
    try {
      final scheduled = await scheduledFollowUpsRef()
          .where('customerId', isEqualTo: customerId)
          .where('consultantId', isEqualTo: userId)
          .get();
      for (final doc in scheduled.docs) {
        batch.delete(doc.reference);
      }
    } catch (e) {
      AppLogger.error('deleteCustomer: scheduled_follow_ups temizlenirken hata: $e', tag: 'CustomerRepository', error: e);
    }

    // 3) Geçmiş takipler
    try {
      final followUps = await followUpsRef(userId, customerId).get();
      for (final doc in followUps.docs) {
        batch.delete(doc.reference);
      }
    } catch (e) {
      AppLogger.error('deleteCustomer: follow_ups temizlenirken hata: $e', tag: 'CustomerRepository', error: e);
    }

    // 4) Bağlı kullanıcı varsa assignedDistributorId'sini temizle
    if (linkedUserId != null && linkedUserId.isNotEmpty) {
      final profileRef = _db.collection('userProfiles').doc(linkedUserId);
      batch.update(profileRef, {'assignedDistributorId': FieldValue.delete()});
    }

    await batch.commit();
  }

  // ── follow_ups (alt koleksiyon) ────────────────────────────────────────

  CollectionReference<FollowUpModel> followUpsRef(
    String userId,
    String customerId,
  ) =>
      customersRef(userId)
          .doc(customerId)
          .collection('follow_ups')
          .withConverter<FollowUpModel>(
            fromFirestore: (s, _) => FollowUpModel.fromMap(s.data()!, s.id),
            toFirestore: (m, _) => m.toMap(),
          );

  Stream<List<FollowUpModel>> getFollowUps(String userId, String customerId) {
    return followUpsRef(userId, customerId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList())
        .handleError((error) {
      AppLogger.error("getFollowUps hatası (müşteri: $customerId): $error", tag: 'CustomerRepository');
      return <FollowUpModel>[];
    });
  }

  Future<void> addFollowUp(
    String userId,
    String customerId,
    FollowUpModel followUp,
  ) async {
    try {
      await followUpsRef(userId, customerId).add(followUp);
    } catch (e) {
      AppLogger.error("addFollowUp hatası: $e", tag: 'CustomerRepository', error: e);
      throw Exception("Takip görüşmesi eklenemedi: $e");
    }
  }

  Future<void> updateFollowUp(
    String userId,
    String customerId,
    FollowUpModel followUp,
  ) async {
    try {
      await followUpsRef(userId, customerId)
          .doc(followUp.id)
          .update(followUp.toMap());
    } catch (e) {
      AppLogger.error("updateFollowUp hatası: $e", tag: 'CustomerRepository', error: e);
      throw Exception("Takip görüşmesi güncellenemedi: $e");
    }
  }

  Future<void> deleteFollowUp(
    String userId,
    String customerId,
    String followUpId,
  ) async {
    try {
      await followUpsRef(userId, customerId).doc(followUpId).delete();
    } catch (e) {
      AppLogger.error("deleteFollowUp hatası: $e", tag: 'CustomerRepository', error: e);
      throw Exception("Takip görüşmesi silinemedi: $e");
    }
  }

  // ── scheduled_follow_ups (kök koleksiyon) ──────────────────────────────

  CollectionReference<ScheduledFollowUpModel> scheduledFollowUpsRef() => _db
      .collection('scheduled_follow_ups')
      .withConverter<ScheduledFollowUpModel>(
        fromFirestore: (s, _) =>
            ScheduledFollowUpModel.fromMap(s.data()!, s.id),
        toFirestore: (m, _) => m.toMap(),
      );

  Stream<List<ScheduledFollowUpModel>> getUpcomingFollowUpsForConsultant(
    String consultantId,
    DateTime inTheNext,
  ) {
    return scheduledFollowUpsRef()
        .where('consultantId', isEqualTo: consultantId)
        .where('isCompleted', isEqualTo: false)
        .where('dueDate', isLessThanOrEqualTo: Timestamp.fromDate(inTheNext))
        .orderBy('dueDate')
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  Stream<List<ScheduledFollowUpModel>> getScheduledFollowUpsForCustomer(
    String userId,
    String customerId, {
    String? linkedUserId,
  }) {
    final base = scheduledFollowUpsRef()
        .where('consultantId', isEqualTo: userId);
    final query = linkedUserId != null && linkedUserId.isNotEmpty
        ? base.where('customerId', whereIn: [customerId, linkedUserId])
        : scheduledFollowUpsRef()
            .where('customerId', isEqualTo: customerId)
            .where('consultantId', isEqualTo: userId);

    return query.snapshots().map((s) {
      final list = s.docs.map((d) => d.data()).toList();
      list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      return list;
    });
  }

  Future<void> addScheduledFollowUpBatch(
    List<ScheduledFollowUpModel> followUps,
  ) async {
    try {
      final batch = _db.batch();
      for (final f in followUps) {
        batch.set(scheduledFollowUpsRef().doc(), f);
      }
      await batch.commit();
    } catch (e) {
      AppLogger.error("addScheduledFollowUpBatch hatası: $e", tag: 'CustomerRepository', error: e);
      throw Exception("Planlanmış takipler oluşturulamadı: $e");
    }
  }

  Future<void> markScheduledFollowUpAsCompleted(String id) async {
    try {
      await scheduledFollowUpsRef().doc(id).update({'isCompleted': true});
    } catch (e) {
      AppLogger.error("markScheduledFollowUpAsCompleted hatası: $e", tag: 'CustomerRepository', error: e);
      throw Exception("Takip tamamlandı olarak işaretlenemedi: $e");
    }
  }

  /// Takibi yeni bir tarihe erteler. Dashboard'daki "Yarına ertele"
  /// hızlı aksiyonu için kullanılır.
  Future<void> snoozeScheduledFollowUp(String id, DateTime newDueDate) async {
    try {
      await scheduledFollowUpsRef().doc(id).update({
        'dueDate': Timestamp.fromDate(newDueDate),
      });
    } catch (e) {
      AppLogger.error("snoozeScheduledFollowUp hatası: $e", tag: 'CustomerRepository', error: e);
      throw Exception("Takip ertelenemedi: $e");
    }
  }

  Future<void> deleteScheduledFollowUp(String id) async {
    try {
      await scheduledFollowUpsRef().doc(id).delete();
    } catch (e) {
      AppLogger.error("deleteScheduledFollowUp hatası: $e", tag: 'CustomerRepository', error: e);
      throw Exception("Planlanmış takip silinemedi: $e");
    }
  }

  /// Tekil bir planlanmış takip ekler (manuel oluşturma için).
  Future<void> addSingleScheduledFollowUp(ScheduledFollowUpModel followUp) async {
    try {
      await scheduledFollowUpsRef().add(followUp);
    } catch (e) {
      AppLogger.error('addSingleScheduledFollowUp hatası: $e', tag: 'CustomerRepository', error: e);
      throw Exception('Planlanmış takip eklenemedi: $e');
    }
  }

  /// Planlanmış bir takibin tüm alanlarını günceller.
  Future<void> updateScheduledFollowUp(ScheduledFollowUpModel followUp) async {
    try {
      await scheduledFollowUpsRef().doc(followUp.id).update(followUp.toMap());
    } catch (e) {
      AppLogger.error('updateScheduledFollowUp hatası: $e', tag: 'CustomerRepository', error: e);
      throw Exception('Planlanmış takip güncellenemedi: $e');
    }
  }

  Stream<List<ScheduledFollowUpModel>> getAllScheduledFollowUpsForConsultant(
    String consultantId,
  ) {
    return scheduledFollowUpsRef()
        .where('consultantId', isEqualTo: consultantId)
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => d.data()).toList();
          list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
          return list;
        });
  }
}
