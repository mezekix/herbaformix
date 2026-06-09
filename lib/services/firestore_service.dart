import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/customer_model.dart';
import '../models/distributor_customer_insights.dart';
import '../models/follow_up_model.dart';
import '../models/invite_code_model.dart';
import '../models/invite_status.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../models/progress_entry_model.dart';
import '../models/scheduled_follow_up_model.dart';
import '../models/user_profile_model.dart';
import '../models/water_log_model.dart';
import '../models/water_summary_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<UserProfileModel> get userProfilesRef => _db
      .collection('userProfiles')
      .withConverter<UserProfileModel>(
        fromFirestore: (s, o) => UserProfileModel.fromMap(s.data()!, s.id),
        toFirestore: (m, o) => m.toMap(),
      );

  Future<void> setUserProfile(UserProfileModel userProfile) async {
    await userProfilesRef
        .doc(userProfile.id)
        .set(userProfile, SetOptions(merge: true));
  }

  Future<UserProfileModel?> getUserProfile(String userId) async {
    final d = await userProfilesRef.doc(userId).get();
    return d.exists ? d.data() : null;
  }

  Stream<UserProfileModel?> watchUserProfile(String userId) {
    return userProfilesRef
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null);
  }

  CollectionReference<ProductModel> get productsRef => _db
      .collection('products')
      .withConverter<ProductModel>(
        fromFirestore: (s, o) => ProductModel.fromMap(s.data()!, s.id),
        toFirestore: (m, o) => m.toMap(),
      );

  Stream<List<ProductModel>> getProducts() {
    return productsRef
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  Future<DocumentReference<ProductModel>> addProduct(
    ProductModel product,
  ) async {
    return await productsRef.add(product);
  }

  Future<void> updateProduct(ProductModel product) async {
    await productsRef.doc(product.id).update(product.toMap());
  }

  Future<void> deleteProduct(String productId) async {
    await productsRef.doc(productId).delete();
  }

  CollectionReference<CustomerModel> customersRef(String userId) => _db
      .collection('users')
      .doc(userId)
      .collection('customers')
      .withConverter<CustomerModel>(
        fromFirestore: (s, o) => CustomerModel.fromMap(s.data()!, s.id),
        toFirestore: (m, o) => m.toMap(),
      );

  Future<DocumentReference<CustomerModel>> addCustomer(
    String userId,
    CustomerModel customer,
  ) async {
    return await customersRef(userId).add(customer);
  }

  Stream<List<CustomerModel>> getCustomers(String userId) {
    return customersRef(userId)
        .orderBy('firstName')
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  Future<List<CustomerModel>> fetchAllCustomers(String userId) async {
    final snapshot = await customersRef(userId).orderBy('firstName').get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<CustomerModel?> getCustomer(String userId, String customerId) async {
    try {
      final docSnapshot = await customersRef(userId).doc(customerId).get();
      if (docSnapshot.exists) {
        return docSnapshot.data();
      }
      return null;
    } catch (e) {
      debugPrint("FirestoreService Hata (getCustomer): $e");
      rethrow;
    }
  }

  Future<CustomerModel?> getCustomerByLinkedUserId(
    String distributorId,
    String linkedUserId,
  ) async {
    try {
      final snapshot = await customersRef(distributorId)
          .where('linkedUserId', isEqualTo: linkedUserId)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      return snapshot.docs.first.data();
    } catch (e) {
      debugPrint("FirestoreService Hata (getCustomerByLinkedUserId): $e");
      return null;
    }
  }

  Future<CustomerModel> createCustomerRecordFromUserProfile({
    required String distributorId,
    required UserProfileModel profile,
  }) async {
    final existing = await getCustomerByLinkedUserId(distributorId, profile.id);
    if (existing != null) {
      return existing;
    }

    final nameParts = (profile.name ?? '').trim().split(RegExp(r'\s+'));
    final firstName = nameParts.isNotEmpty && nameParts.first.isNotEmpty
        ? nameParts.first
        : 'Müşteri';
    final lastName = nameParts.length > 1
        ? nameParts.sublist(1).join(' ').trim()
        : '';

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

    // 1. Müşteri dokümanını güncelle
    final customerRef = customersRef(userId).doc(customer.id);
    batch.update(customerRef, customer.toMap());

    // 2. Eğer bağlı kullanıcı varsa, onun profilindeki bilgileri de güncelle
    if (customer.linkedUserId != null && customer.linkedUserId!.isNotEmpty) {
      final profileRef = userProfilesRef.doc(customer.linkedUserId);
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
    // Önce müşteri dokümanını oku
    final customerDoc = await customersRef(userId).doc(customerId).get();
    final customerData = customerDoc.data();
    final linkedUserId = customerData?.linkedUserId;

    final batch = _db.batch();

    // 1. Müşteri dokümanını sil
    final customerRef = customersRef(userId).doc(customerId);
    batch.delete(customerRef);

    // 2. Müşteriye ait scheduled_follow_ups'ları sil
    try {
      final scheduledSnapshot = await scheduledFollowUpsRef()
          .where('customerId', isEqualTo: customerId)
          .where('consultantId', isEqualTo: userId)
          .get();
      for (final doc in scheduledSnapshot.docs) {
        batch.delete(doc.reference);
      }
    } catch (e) {
      debugPrint('deleteCustomer: scheduled_follow_ups temizlenirken hata: $e');
    }

    // 3. Müşteriye ait follow_ups alt koleksiyonunu sil
    try {
      final followUpsSnapshot = await followUpsRef(userId, customerId).get();
      for (final doc in followUpsSnapshot.docs) {
        batch.delete(doc.reference);
      }
    } catch (e) {
      debugPrint('deleteCustomer: follow_ups temizlenirken hata: $e');
    }

    // 4. Eğer bağlı bir kullanıcı varsa, distribütör ilişkisini kes (assignedDistributorId alanını sil)
    if (linkedUserId != null && linkedUserId.isNotEmpty) {
      final profileRef = userProfilesRef.doc(linkedUserId);
      batch.update(profileRef, {'assignedDistributorId': FieldValue.delete()});
    }

    await batch.commit();
  }

  Future<void> disconnectDistributor(String customerUserId) async {
    try {
      final profileRef = userProfilesRef.doc(customerUserId);
      await profileRef.update({'assignedDistributorId': FieldValue.delete()});
    } catch (e) {
      debugPrint('disconnectDistributor hatası: $e');
      throw Exception('Distribütör bağlantısı kesilemedi: $e');
    }
  }

  CollectionReference<FollowUpModel> followUpsRef(
    String userId,
    String customerId,
  ) => _db
      .collection('users')
      .doc(userId)
      .collection('customers')
      .doc(customerId)
      .collection('follow_ups')
      .withConverter<FollowUpModel>(
        fromFirestore: (snapshot, _) =>
            FollowUpModel.fromMap(snapshot.data()!, snapshot.id),
        toFirestore: (followUp, _) => followUp.toMap(),
      );

  Stream<List<FollowUpModel>> getFollowUps(String userId, String customerId) {
    return followUpsRef(userId, customerId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList())
        .handleError((error) {
          debugPrint(
            "Takip görüşmeleri getirilirken hata oluştu (müşteri: $customerId): $error",
          );
          return [];
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
      debugPrint("Takip görüşmesi eklerken hata: $e");
      throw Exception("Takip görüşmesi eklenemedi: $e");
    }
  }

  Future<void> updateFollowUp(
    String userId,
    String customerId,
    FollowUpModel followUp,
  ) async {
    try {
      await followUpsRef(
        userId,
        customerId,
      ).doc(followUp.id).update(followUp.toMap());
    } catch (e) {
      debugPrint("Takip görüşmesi güncellenirken hata: $e");
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
      debugPrint("Takip görüşmesi silerken hata: $e");
      throw Exception("Takip görüşmesi silinemedi: $e");
    }
  }

  CollectionReference<ScheduledFollowUpModel> scheduledFollowUpsRef() => _db
      .collection('scheduled_follow_ups')
      .withConverter<ScheduledFollowUpModel>(
        fromFirestore: (snapshot, _) =>
            ScheduledFollowUpModel.fromMap(snapshot.data()!, snapshot.id),
        toFirestore: (scheduled, _) => scheduled.toMap(),
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
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<List<ScheduledFollowUpModel>> getScheduledFollowUpsForCustomer(
    String userId,
    String customerId, {
    String? linkedUserId,
  }) {
    if (linkedUserId != null && linkedUserId.isNotEmpty) {
      return scheduledFollowUpsRef()
          .where('consultantId', isEqualTo: userId)
          .where('customerId', whereIn: [customerId, linkedUserId])
          .snapshots()
          .map((snapshot) {
            final list = snapshot.docs.map((doc) => doc.data()).toList();
            list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
            return list;
          });
    } else {
      return scheduledFollowUpsRef()
          .where('customerId', isEqualTo: customerId)
          .where('consultantId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
            final list = snapshot.docs.map((doc) => doc.data()).toList();
            list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
            return list;
          });
    }
  }

  Future<void> addScheduledFollowUpBatch(
    List<ScheduledFollowUpModel> followUps,
  ) async {
    try {
      final batch = _db.batch();

      for (final followUp in followUps) {
        final docRef = scheduledFollowUpsRef().doc();
        batch.set(docRef, followUp);
      }

      await batch.commit();
    } catch (e) {
      debugPrint("Planlanmış takip grubu eklenirken hata: $e");
      throw Exception("Planlanmış takipler oluşturulamadı: $e");
    }
  }

  Future<void> markScheduledFollowUpAsCompleted(
    String scheduledFollowUpId,
  ) async {
    try {
      await scheduledFollowUpsRef().doc(scheduledFollowUpId).update({
        'isCompleted': true,
      });
    } catch (e) {
      debugPrint("Planlanmış takip tamamlandı olarak işaretlenirken hata: $e");
      throw Exception("Takip tamamlandı olarak işaretlenemedi: $e");
    }
  }

  Future<void> deleteScheduledFollowUp(String scheduledFollowUpId) async {
    try {
      await scheduledFollowUpsRef().doc(scheduledFollowUpId).delete();
    } catch (e) {
      debugPrint("Planlanmış takip silinirken hata: $e");
      throw Exception("Planlanmış takip silinemedi: $e");
    }
  }

  CollectionReference<OrderModel> ordersRef(String userId) => _db
      .collection('users')
      .doc(userId)
      .collection('orders')
      .withConverter<OrderModel>(
        fromFirestore: (snapshot, _) =>
            OrderModel.fromMap(snapshot.data()!, snapshot.id),
        toFirestore: (order, _) => order.toMap(),
      );

  Stream<List<OrderModel>> getOrders(String userId) {
    return ordersRef(userId)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<DocumentReference<OrderModel>> addOrder(
    String userId,
    OrderModel order,
  ) async {
    return await ordersRef(userId).add(order);
  }

  Future<void> updateOrder(String userId, OrderModel order) async {
    await ordersRef(userId).doc(order.id).update(order.toMap());
  }

  Future<void> deleteOrder(String userId, String orderId) async {
    await ordersRef(userId).doc(orderId).delete();
  }

  CollectionReference<InviteCodeModel> get inviteCodesRef => _db
      .collection('inviteCodes')
      .withConverter<InviteCodeModel>(
        fromFirestore: (s, _) => InviteCodeModel.fromMap(s.data()!, s.id),
        toFirestore: (m, _) => m.toMap(),
      );

  @visibleForTesting
  String generateCode() {
    const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(
      8,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  Future<InviteCodeModel> createInviteCode(
    String distributorId, {
    String? customerRecordId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
  }) async {
    const maxAttempts = 5;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final code = generateCode();

      final existing = await inviteCodesRef
          .where('code', isEqualTo: code)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        continue;
      }

      final now = DateTime.now();
      final model = InviteCodeModel(
        id: '',
        code: code,
        distributorId: distributorId,
        createdAt: now,
        expiresAt: now.add(kInviteCodeDefaultValidity),
        status: InviteStatus.pending,
        isUsed: false,
        usedByUserId: null,
        customerRecordId: customerRecordId,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
      );

      final docRef = await inviteCodesRef.add(model);
      final snapshot = await docRef.get();
      return snapshot.data()!;
    }

    throw Exception('Benzersiz davet kodu üretilemedi. Lütfen tekrar deneyin.');
  }

  Future<({CustomerModel customer, InviteCodeModel inviteCode})>
  addCustomerWithInviteCode({
    required String distributorId,
    required CustomerModel customer,
  }) async {
    const maxAttempts = 5;

    String? code;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final candidate = generateCode();
      final existing = await inviteCodesRef
          .where('code', isEqualTo: candidate)
          .limit(1)
          .get();
      if (existing.docs.isEmpty) {
        code = candidate;
        break;
      }
    }
    if (code == null) {
      throw Exception('Benzersiz davet kodu üretilemedi. Lütfen tekrar deneyin.');
    }

    final customerDocRef = _db
        .collection('users')
        .doc(distributorId)
        .collection('customers')
        .doc();
    final inviteDocRef = _db.collection('inviteCodes').doc();

    final now = DateTime.now();

    final customerToWrite = CustomerModel(
      id: customerDocRef.id,
      firstName: customer.firstName,
      lastName: customer.lastName,
      phoneNumber: customer.phoneNumber,
      email: customer.email,
      address: customer.address,
      firstContactDate: customer.firstContactDate,
      consultantId: distributorId,
      isActive: customer.isActive,
      notes: customer.notes,
      linkedUserId: null,
      inviteCodeId: inviteDocRef.id,
    );

    final inviteToWrite = InviteCodeModel(
      id: inviteDocRef.id,
      code: code,
      distributorId: distributorId,
      createdAt: now,
      expiresAt: now.add(kInviteCodeDefaultValidity),
      status: InviteStatus.pending,
      isUsed: false,
      usedByUserId: null,
      customerRecordId: customerDocRef.id,
      customerName: '${customer.firstName} ${customer.lastName}'.trim(),
      customerPhone: customer.phoneNumber,
      customerEmail: customer.email,
    );

    final batch = _db.batch();
    batch.set(customerDocRef, customerToWrite.toMap());
    batch.set(inviteDocRef, inviteToWrite.toMap());

    try {
      await batch.commit();
    } catch (e) {
      debugPrint('addCustomerWithInviteCode batch hatası: $e');
      throw Exception('Müşteri ve davet kodu oluşturulamadı: $e');
    }

    return (customer: customerToWrite, inviteCode: inviteToWrite);
  }

  Future<InviteCodeModel> regenerateInviteCode({
    required String distributorId,
    required String customerRecordId,
    required String oldInviteCodeId,
    required String customerName,
    required String customerPhone,
    String? customerEmail,
  }) async {
    const maxAttempts = 5;

    String? code;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final candidate = generateCode();
      final existing = await inviteCodesRef
          .where('code', isEqualTo: candidate)
          .limit(1)
          .get();
      if (existing.docs.isEmpty) {
        code = candidate;
        break;
      }
    }
    if (code == null) {
      throw Exception('Benzersiz davet kodu üretilemedi. Lütfen tekrar deneyin.');
    }

    final newInviteDocRef = _db.collection('inviteCodes').doc();
    final oldInviteDocRef = _db.collection('inviteCodes').doc(oldInviteCodeId);
    final customerDocRef = _db
        .collection('users')
        .doc(distributorId)
        .collection('customers')
        .doc(customerRecordId);

    final now = DateTime.now();
    final newInvite = InviteCodeModel(
      id: newInviteDocRef.id,
      code: code,
      distributorId: distributorId,
      createdAt: now,
      expiresAt: now.add(kInviteCodeDefaultValidity),
      status: InviteStatus.pending,
      isUsed: false,
      usedByUserId: null,
      customerRecordId: customerRecordId,
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
    );

    final batch = _db.batch();
    batch.update(oldInviteDocRef, {'status': 'expired'});
    batch.set(newInviteDocRef, newInvite.toMap());
    batch.update(customerDocRef, {'inviteCodeId': newInviteDocRef.id});

    try {
      await batch.commit();
    } catch (e) {
      debugPrint('regenerateInviteCode batch hatası: $e');
      throw Exception('Yeni davet kodu üretilemedi: $e');
    }

    return newInvite;
  }

  Future<InviteCodeModel?> validateInviteCode(String code) async {
    final snapshot = await inviteCodesRef
        .where('code', isEqualTo: code)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final inviteCode = snapshot.docs.first.data();
    final effective = inviteCode.effectiveStatus;

    if (effective == InviteStatus.used || inviteCode.isUsed) {
      throw Exception('Bu davet kodu daha önce kullanılmış.');
    }
    if (effective == InviteStatus.expired) {
      throw Exception(
        'Davet kodu süresi dolmuş. Lütfen distribütörünüzden yeni bir kod isteyin.',
      );
    }

    return inviteCode;
  }

  Future<void> signUpWithInviteCodeBatch({
    required UserProfileModel userProfile,
    required InviteCodeModel inviteCode,
    required String newUserId,
  }) async {
    try {
      final batch = _db.batch();

      final userProfileRef = userProfilesRef.doc(newUserId);
      batch.set(userProfileRef, userProfile, SetOptions(merge: true));

      final inviteCodeRef = inviteCodesRef.doc(inviteCode.id);
      batch.update(inviteCodeRef, {
        'isUsed': true,
        'status': 'used',
        'usedByUserId': newUserId,
      });

      if (inviteCode.customerRecordId != null &&
          inviteCode.customerRecordId!.isNotEmpty &&
          inviteCode.distributorId.isNotEmpty) {
        final customerDocRef = _db
            .collection('users')
            .doc(inviteCode.distributorId)
            .collection('customers')
            .doc(inviteCode.customerRecordId);
        batch.update(customerDocRef, {
          'linkedUserId': newUserId,
          'activatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('signUpWithInviteCodeBatch hatası: $e');
      throw Exception('Kayıt işlemi tamamlanamadı: $e');
    }
  }

  Future<UserProfileModel?> getDistributorProfile(String distributorId) async {
    try {
      final doc = await userProfilesRef.doc(distributorId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint('getDistributorProfile hatası: $e');
      return null;
    }
  }

  Stream<List<UserProfileModel>> getCustomersByDistributorId(
    String distributorId,
  ) {
    return userProfilesRef
        .where('assignedDistributorId', isEqualTo: distributorId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<List<UserProfileModel>> fetchCustomersByDistributorId(
    String distributorId,
  ) async {
    final snapshot = await userProfilesRef
        .where('assignedDistributorId', isEqualTo: distributorId)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Stream<List<InviteCodeModel>> getInviteCodesForDistributor(
    String distributorId,
  ) {
    return inviteCodesRef
        .where('distributorId', isEqualTo: distributorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList())
        .handleError((error) {
          debugPrint('getInviteCodesForDistributor hatası: $error');
          return <InviteCodeModel>[];
        });
  }

  Future<InviteCodeModel?> getInviteCodeForCustomer(
    String customerRecordId,
  ) async {
    try {
      final snapshot = await inviteCodesRef
          .where('customerRecordId', isEqualTo: customerRecordId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return snapshot.docs.first.data();
    } catch (e) {
      debugPrint('getInviteCodeForCustomer hatası: $e');
      return null;
    }
  }

  Future<void> deleteInviteCode(String inviteCodeId) async {
    try {
      await _db.collection('inviteCodes').doc(inviteCodeId).delete();
      debugPrint('deleteInviteCode başarılı: $inviteCodeId');
    } catch (e) {
      debugPrint('deleteInviteCode hatası: $e');
      throw Exception('Davet kodu silinemedi: $e');
    }
  }

  Future<int> deleteExpiredInviteCodes(String distributorId) async {
    try {
      final now = DateTime.now();
      final snapshot = await _db
          .collection('inviteCodes')
          .where('distributorId', isEqualTo: distributorId)
          .where('isUsed', isEqualTo: false)
          .where('expiresAt', isLessThan: Timestamp.fromDate(now))
          .get();

      if (snapshot.docs.isEmpty) return 0;

      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      debugPrint('deleteExpiredInviteCodes: ${snapshot.docs.length} kod silindi');
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('deleteExpiredInviteCodes hatası: $e');
      return 0;
    }
  }

  CollectionReference<ProgressEntryModel> progressEntriesRef(String userId) =>
      _db
          .collection('users')
          .doc(userId)
          .collection('progressEntries')
          .withConverter<ProgressEntryModel>(
            fromFirestore: (s, _) =>
                ProgressEntryModel.fromMap(s.data()!, s.id),
            toFirestore: (m, _) => m.toMap(),
          );

  Stream<List<ProgressEntryModel>> getProgressEntries(
    String userId, {
    int limitDays = 90,
  }) {
    final since = DateTime.now().subtract(Duration(days: limitDays));
    return progressEntriesRef(userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .orderBy('date', descending: false)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  Future<DocumentReference<ProgressEntryModel>> addProgressEntry(
    String userId,
    ProgressEntryModel entry,
  ) async {
    return await progressEntriesRef(userId).add(entry);
  }

  Future<void> updateProgressEntry(
    String userId,
    ProgressEntryModel entry,
  ) async {
    await progressEntriesRef(userId).doc(entry.id).update(entry.toMap());
  }

  Future<void> deleteProgressEntry(String userId, String entryId) async {
    await progressEntriesRef(userId).doc(entryId).delete();
  }

  Future<void> saveEarnedBadges(String userId, List<String> badgeIds) async {
    await userProfilesRef.doc(userId).update({'earnedBadges': badgeIds});
  }

  CollectionReference<Map<String, dynamic>> _waterLogsRef(String userId) =>
      _db.collection('users').doc(userId).collection('waterLogs');

  Stream<List<WaterLogModel>> getWaterLogs(String userId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return _waterLogsRef(userId)
        .where('time', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('time', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('time', descending: false)
        .snapshots()
        .map((s) => s.docs
            .map((d) => WaterLogModel.fromMap(d.data(), d.id))
            .toList());
  }

  Future<int?> getWaterDailyGoal(String userId) async {
    final doc = await userProfilesRef.doc(userId).get();
    if (!doc.exists) return null;
    final data = doc.data()?.toMap();
    return data?['waterDailyGoal'] as int?;
  }

  Future<void> setWaterDailyGoal(String userId, int goal) async {
    await userProfilesRef.doc(userId).update({'waterDailyGoal': goal});
  }

  Future<void> addWaterLog(String userId, WaterLogModel log) async {
    await _waterLogsRef(userId).add(log.toMap());
  }

  Future<void> deleteWaterLog(String userId, String logId) async {
    await _waterLogsRef(userId).doc(logId).delete();
  }

  Future<void> updateWaterLog(String userId, WaterLogModel log) async {
    await _waterLogsRef(userId).doc(log.id).update(log.toMap());
  }

  Future<void> clearWaterLogs(String userId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final snapshot = await _waterLogsRef(userId)
        .where('time', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('time', isLessThan: Timestamp.fromDate(endOfDay))
        .get();
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<DistributorCustomerInsights> getDistributorCustomerInsights(
    String customerUserId,
  ) async {
    try {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final endOfToday = startOfToday.add(const Duration(days: 1));
      final sevenDaysAgo = startOfToday.subtract(const Duration(days: 6));

      final latestProgressFuture = progressEntriesRef(customerUserId)
          .orderBy('date', descending: true)
          .limit(1)
          .get();
      final allProgressFuture = progressEntriesRef(customerUserId)
          .orderBy('date', descending: false)
          .get();
      final todayWaterFuture = _waterLogsRef(customerUserId)
          .where('time', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
          .where('time', isLessThan: Timestamp.fromDate(endOfToday))
          .get();
      final recentRoutinesFuture = _db
          .collection('users')
          .doc(customerUserId)
          .collection('dailyRoutines')
          .where(
            'scheduledTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo),
          )
          .where('scheduledTime', isLessThan: Timestamp.fromDate(endOfToday))
          .get();
      final userProfileFuture = getUserProfile(customerUserId);

      final results = await Future.wait([
        latestProgressFuture,
        allProgressFuture,
        todayWaterFuture,
        recentRoutinesFuture,
        userProfileFuture,
      ]);

      final latestProgressSnapshot =
          results[0] as QuerySnapshot<ProgressEntryModel>;
      final allProgressSnapshot =
          results[1] as QuerySnapshot<ProgressEntryModel>;
      final todayWaterSnapshot = results[2] as QuerySnapshot<Map<String, dynamic>>;
      final recentRoutinesSnapshot =
          results[3] as QuerySnapshot<Map<String, dynamic>>;
      final userProfile = results[4] as UserProfileModel?;

      final latestProgress = latestProgressSnapshot.docs.isNotEmpty
          ? latestProgressSnapshot.docs.first.data()
          : null;

      final todayWaterMl = todayWaterSnapshot.docs.fold<int>(
        0,
        (totalAmount, doc) =>
            totalAmount + ((doc.data()['amount'] as num?)?.toInt() ?? 0),
      );

      final routines = recentRoutinesSnapshot.docs.map((doc) => doc.data()).toList();
      final completedRoutines = routines.where((routine) =>
          (routine['isCompleted'] ?? routine['is_completed']) == true);

      DateTime? latestRoutineAt;
      if (recentRoutinesSnapshot.docs.isNotEmpty) {
        latestRoutineAt = recentRoutinesSnapshot.docs
            .map((doc) => ((doc.data()['scheduledTime'] ??
                    doc.data()['scheduled_time']) as Timestamp)
                .toDate())
            .fold<DateTime?>(
              null,
              (latest, current) =>
                  latest == null || current.isAfter(latest) ? current : latest,
            );
      }

      DateTime? latestWaterAt;
      if (todayWaterSnapshot.docs.isNotEmpty) {
        latestWaterAt = todayWaterSnapshot.docs
            .map((doc) => (doc.data()['time'] as Timestamp).toDate())
            .fold<DateTime?>(
              null,
              (latest, current) =>
                  latest == null || current.isAfter(latest) ? current : latest,
            );
      }

      final lastActivityCandidates = [
        latestProgress?.date,
        latestRoutineAt,
        latestWaterAt,
      ].whereType<DateTime>().toList()
        ..sort((a, b) => b.compareTo(a));

      // Son 90 günlük progress entries
      final cutoff = DateTime.now().subtract(const Duration(days: 90));
      final progressEntries = allProgressSnapshot.docs
          .map((doc) => doc.data())
          .where((e) => e.date.isAfter(cutoff))
          .toList();

      return DistributorCustomerInsights(
        latestProgress: latestProgress,
        progressEntries: progressEntries,
        todayWaterMl: todayWaterMl,
        waterGoalMl: userProfile?.waterDailyGoal ?? 2000,
        completedRoutinesLast7Days: completedRoutines.length,
        totalRoutinesLast7Days: routines.length,
        lastActivityAt:
            lastActivityCandidates.isEmpty ? null : lastActivityCandidates.first,
      );
    } catch (e) {
      debugPrint('getDistributorCustomerInsights hatası: $e');
      return const DistributorCustomerInsights(
        latestProgress: null,
        todayWaterMl: 0,
        waterGoalMl: 2000,
        completedRoutinesLast7Days: 0,
        totalRoutinesLast7Days: 0,
        lastActivityAt: null,
      );
    }
  }

  // ──────────────── Motivations ────────────────

  /// Get today's distributor message for a customer (if any)
  Future<String?> getDistributorMotivationMessage(String customerId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _db
          .collection('motivations')
          .doc(customerId)
          .collection('daily_messages')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return snapshot.docs.first.data()['distributor_mesaji'] as String?;
    } catch (e) {
      debugPrint('getDistributorMotivationMessage hatası: $e');
      return null;
    }
  }

  /// Save today's distributor message for a customer
  Future<void> saveDistributorMotivationMessage(
    String customerId,
    String message,
  ) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      await _db
          .collection('motivations')
          .doc(customerId)
          .collection('daily_messages')
          .doc('today')
          .set({
        'distributor_mesaji': message,
        'distributor_mesaji_tarihi': Timestamp.fromDate(startOfDay),
        'sistem_soz_index': now.millisecondsSinceEpoch ~/ 86400000 % 100,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('saveDistributorMotivationMessage hatası: $e');
    }
  }

  /// Save today's motivation score (1-10)
  Future<void> saveMotivationScore(String customerId, int score) async {
    try {
      final now = DateTime.now();
      final docId = '${customerId}_${now.year}_${now.month}_${now.day}';

      await _db
          .collection('motivation_scores')
          .doc(docId)
          .set({
        'skor': score,
        'tarih': Timestamp.now(),
        'musteri_id': customerId,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('saveMotivationScore hatası: $e');
    }
  }

  /// Get motivation scores for the last N days
  Future<List<int>> getMotivationScoresLastDays(String customerId, int days) async {
    try {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));
      final endDate = now.add(const Duration(days: 1));

      final snapshot = await _db
          .collection('motivation_scores')
          .where('musteri_id', isEqualTo: customerId)
          .where('tarih', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('tarih', isLessThan: Timestamp.fromDate(endDate))
          .orderBy('tarih', descending: true)
          .get();

      return snapshot.docs.map((d) => (d.data()['skor'] as num?)?.toInt() ?? 0).toList();
    } catch (e) {
      debugPrint('getMotivationScoresLastDays hatası: $e');
      return [];
    }
  }

  // ──────────────── Water & Daily Routines ────────────────

  Future<int> getAtRiskCustomerCount(String distributorId) async {
    try {
      final customers = await getCustomersByDistributorId(distributorId).first;
      if (customers.isEmpty) return 0;
      final insights = await Future.wait(
        customers.map((customer) => getDistributorCustomerInsights(customer.id)),
      );
      return insights.where((item) => item.isAtRisk).length;
    } catch (e) {
      debugPrint('getAtRiskCustomerCount hatası: $e');
      return 0;
    }
  }

  // ──────────────── Water Summaries ────────────────

  CollectionReference<Map<String, dynamic>> _waterSummariesRef(String userId) =>
      _db.collection('users').doc(userId).collection('waterSummaries');

  Future<WaterSummaryModel?> getWaterSummary(String userId, String dateStr) async {
    try {
      final doc = await _waterSummariesRef(userId).doc(dateStr).get();
      if (doc.exists && doc.data() != null) {
        return WaterSummaryModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('getWaterSummary hatası: $e');
      return null;
    }
  }

  Stream<WaterSummaryModel?> watchWaterSummary(String userId, String dateStr) {
    return _waterSummariesRef(userId).doc(dateStr).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return WaterSummaryModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  Future<void> setWaterSummary(String userId, WaterSummaryModel summary) async {
    try {
      await _waterSummariesRef(userId).doc(summary.id).set(summary.toMap());
    } catch (e) {
      debugPrint('setWaterSummary hatası: $e');
    }
  }
}