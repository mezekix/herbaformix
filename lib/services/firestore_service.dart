import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/customer_model.dart';
import '../models/follow_up_model.dart'; // Yeni oluşturduğumuz takip modelini buraya ekliyoruz.
import '../models/invite_code_model.dart';
import '../models/order_model.dart'; // OrderModel'i import et
import '../models/product_model.dart';
import '../models/progress_entry_model.dart';
import '../models/scheduled_follow_up_model.dart'; // Yeni modelimizi import ediyoruz.
import '../models/user_profile_model.dart';
import '../models/water_log_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ... (UserProfile, Product, Customer servis metotları aynı kalacak) ...
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

  /// Veritabanından belirli bir ID'ye sahip tek bir müşteriyi getirir.
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

  Future<void> updateCustomer(String userId, CustomerModel customer) async {
    await customersRef(userId).doc(customer.id).update(customer.toMap());
  }

  Future<void> deleteCustomer(String userId, String customerId) async {
    await customersRef(userId).doc(customerId).delete();
  }

  // --- Follow Ups (Takip Görüşmeleri) ---

  /// Belirli bir müşteriye ait takip görüşmeleri için Koleksiyon Referansı oluşturur.
  /// Firestore'daki veritabanı yolunu (path) tanımlar:
  /// users/{danışmanId}/customers/{müşteriId}/follow_ups/{takipId}
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

  /// Belirli bir müşterinin tüm takip görüşmelerini getiren bir Stream (anlık veri akışı) döndürür.
  /// Görüşmeler, tarihe göre en yeniden eskiye doğru sıralanır.
  Stream<List<FollowUpModel>> getFollowUps(String userId, String customerId) {
    return followUpsRef(userId, customerId)
        .orderBy('date', descending: true)
        .snapshots() // Veritabanındaki her değişikliği anlık olarak dinler.
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList())
        .handleError((error) {
          debugPrint(
            "Takip görüşmeleri getirilirken hata oluştu (müşteri: $customerId): $error",
          );
          return []; // Hata durumunda boş bir liste döndürür.
        });
  }

  /// Veritabanına yeni bir takip görüşmesi ekler.
  Future<void> addFollowUp(
    String userId,
    String customerId,
    FollowUpModel followUp,
  ) async {
    try {
      // Modeli direkt olarak referansa ekliyoruz. ID'yi Firestore otomatik oluşturacak.
      await followUpsRef(userId, customerId).add(followUp);
    } catch (e) {
      debugPrint("Takip görüşmesi eklerken hata: $e");
      // Hata olursa, bunu çağıran kodun haberi olması için hatayı tekrar fırlatıyoruz.
      throw Exception("Takip görüşmesi eklenemedi: $e");
    }
  }

  /// Mevcut bir takip görüşmesini günceller.
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

  /// Bir takip görüşmesini ID'sini kullanarak siler.
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

  // --- Scheduled Follow Ups (Planlanmış Takipler) ---

  /// `scheduled_follow_ups` ana koleksiyonu için bir referans oluşturur.
  CollectionReference<ScheduledFollowUpModel> scheduledFollowUpsRef() => _db
      .collection('scheduled_follow_ups')
      .withConverter<ScheduledFollowUpModel>(
        fromFirestore: (snapshot, _) =>
            ScheduledFollowUpModel.fromMap(snapshot.data()!, snapshot.id),
        toFirestore: (scheduled, _) => scheduled.toMap(),
      );

  /// Belirli bir danışmana ait, tamamlanmamış ve tarihi yaklaşan görevleri getirir.
  /// Bu, ana sayfadaki "Ajanda" bölümü için kullanılacak.
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

  /// Belirli bir müşteriye ait tüm planlanmış görevleri getirir.
  /// Bu, müşteri detay sayfasındaki "Takip Planı" bölümü için kullanılacak.
  Stream<List<ScheduledFollowUpModel>> getScheduledFollowUpsForCustomer(
    String userId,
    String customerId,
  ) {
    return scheduledFollowUpsRef()
        .where('customerId', isEqualTo: customerId)
        .where('consultantId', isEqualTo: userId)
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Veritabanına bir dizi (batch) planlanmış takip görevi ekler.
  /// Bir sipariş teslim edildiğinde, tüm görevleri (1., 3., 7. gün vb.)
  /// tek bir işlemde, atomik olarak eklemek için bu metodu kullanacağız.
  Future<void> addScheduledFollowUpBatch(
    List<ScheduledFollowUpModel> followUps,
  ) async {
    try {
      final batch = _db.batch();

      for (final followUp in followUps) {
        final docRef = scheduledFollowUpsRef()
            .doc(); // Yeni bir doküman referansı oluştur.
        batch.set(docRef, followUp); // Bu referansa modeli ekle.
      }

      await batch.commit(); // Tüm işlemleri tek seferde veritabanına gönder.
    } catch (e) {
      debugPrint("Planlanmış takip grubu eklenirken hata: $e");
      throw Exception("Planlanmış takipler oluşturulamadı: $e");
    }
  }

  /// Belirli bir planlanmış takip görevini tamamlandı olarak işaretler.
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

  /// Belirli bir planlanmış takip görevini siler.
  Future<void> deleteScheduledFollowUp(String scheduledFollowUpId) async {
    try {
      await scheduledFollowUpsRef().doc(scheduledFollowUpId).delete();
    } catch (e) {
      debugPrint("Planlanmış takip silinirken hata: $e");
      throw Exception("Planlanmış takip silinemedi: $e");
    }
  }

  // --- Orders (Siparişler) ---

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

  // --- Davet Kodu (Invite Code) ---

  /// `inviteCodes` koleksiyonu için converter'lı referans.
  CollectionReference<InviteCodeModel> get inviteCodesRef => _db
      .collection('inviteCodes')
      .withConverter<InviteCodeModel>(
        fromFirestore: (s, _) => InviteCodeModel.fromMap(s.data()!, s.id),
        toFirestore: (m, _) => m.toMap(),
      );

  /// 8 karakterlik büyük harf + rakam kodu üretir ([A-Z0-9] charset).
  @visibleForTesting
  String generateCode() {
    const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(8, (_) => charset[random.nextInt(charset.length)]).join();
  }

  /// Benzersizlik kontrolü yaparak `inviteCodes` koleksiyonuna yeni bir davet kodu yazar.
  ///
  /// Maksimum 5 deneme ile çakışma kontrolü yapar.
  /// Başarılı olursa oluşturulan [InviteCodeModel]'i döner.
  /// 5 denemede de çakışma olursa exception fırlatır.
  Future<InviteCodeModel> createInviteCode(String distributorId) async {
    const maxAttempts = 5;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final code = generateCode();

      // Çakışma kontrolü: aynı kod var mı?
      final existing = await inviteCodesRef
          .where('code', isEqualTo: code)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        // Çakışma var, yeni kod dene
        continue;
      }

      // Benzersiz kod bulundu, Firestore'a yaz
      final model = InviteCodeModel(
        id: '', // Firestore otomatik ID atayacak
        code: code,
        distributorId: distributorId,
        createdAt: DateTime.now(),
        isUsed: false,
        usedByUserId: null,
      );

      final docRef = await inviteCodesRef.add(model);
      final snapshot = await docRef.get();
      return snapshot.data()!;
    }

    throw Exception(
      'Benzersiz davet kodu üretilemedi. Lütfen tekrar deneyin.',
    );
  }

  /// `inviteCodes` koleksiyonunda verilen kodu arar.
  ///
  /// Kod bulunamazsa `null` döner.
  /// Kod `isUsed: true` ise exception fırlatır.
  Future<InviteCodeModel?> validateInviteCode(String code) async {
    final snapshot = await inviteCodesRef
        .where('code', isEqualTo: code)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final inviteCode = snapshot.docs.first.data();

    if (inviteCode.isUsed) {
      throw Exception('Bu davet kodu daha önce kullanılmış.');
    }

    return inviteCode;
  }

  /// `WriteBatch` ile atomik yazma: kullanıcı profili oluşturma + davet kodu güncelleme.
  ///
  /// - `userProfiles/{newUserId}` dokümanını batch'e ekler.
  /// - `inviteCodes/{inviteCodeId}` dokümanını `isUsed: true, usedByUserId: newUserId` ile batch'e ekler.
  /// - `batch.commit()` ile atomik olarak yazar.
  Future<void> signUpWithInviteCodeBatch({
    required UserProfileModel userProfile,
    required String inviteCodeId,
    required String newUserId,
  }) async {
    try {
      final batch = _db.batch();

      // userProfiles/{uid} dokümanını batch'e ekle
      final userProfileRef = userProfilesRef.doc(newUserId);
      batch.set(userProfileRef, userProfile, SetOptions(merge: true));

      // inviteCodes/{codeId} dokümanını güncelle
      final inviteCodeRef = inviteCodesRef.doc(inviteCodeId);
      batch.update(inviteCodeRef, {
        'isUsed': true,
        'usedByUserId': newUserId,
      });

      await batch.commit();
    } catch (e) {
      debugPrint('signUpWithInviteCodeBatch hatası: $e');
      throw Exception('Kayıt işlemi tamamlanamadı: $e');
    }
  }

  /// `userProfiles/{distributorId}` dokümanını okur.
  ///
  /// Doküman bulunamazsa `null` döner.
  Future<UserProfileModel?> getDistributorProfile(String distributorId) async {
    try {
      final doc = await userProfilesRef.doc(distributorId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint('getDistributorProfile hatası: $e');
      return null;
    }
  }

  /// `assignedDistributorId == distributorId` olan `userProfiles` dokümanlarını
  /// stream olarak döner.
  Stream<List<UserProfileModel>> getCustomersByDistributorId(
    String distributorId,
  ) {
    return userProfilesRef
        .where('assignedDistributorId', isEqualTo: distributorId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // --- Progress Entries (İlerleme Kayıtları) ---

  /// `users/{userId}/progressEntries` koleksiyonu için referans.
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

  /// Son [limitDays] günlük ilerleme kayıtlarını stream olarak döner.
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

  /// Yeni bir ilerleme kaydı ekler.
  Future<DocumentReference<ProgressEntryModel>> addProgressEntry(
    String userId,
    ProgressEntryModel entry,
  ) async {
    return await progressEntriesRef(userId).add(entry);
  }

  /// Mevcut bir ilerleme kaydını günceller.
  Future<void> updateProgressEntry(
    String userId,
    ProgressEntryModel entry,
  ) async {
    await progressEntriesRef(userId).doc(entry.id).update(entry.toMap());
  }

  /// Bir ilerleme kaydını siler.
  Future<void> deleteProgressEntry(String userId, String entryId) async {
    await progressEntriesRef(userId).doc(entryId).delete();
  }

  /// Kullanıcının kazandığı rozet ID'lerini Firestore'a kaydeder.
  Future<void> saveEarnedBadges(String userId, List<String> badgeIds) async {
    await userProfilesRef.doc(userId).update({'earnedBadges': badgeIds});
  }

  // --- Water Logs (Su Takibi) ---

  /// `users/{userId}/waterLogs` koleksiyonu için referans.
  CollectionReference<Map<String, dynamic>> _waterLogsRef(String userId) =>
      _db.collection('users').doc(userId).collection('waterLogs');

  /// Belirli bir günün su loglarını stream olarak döner.
  Stream<List<WaterLogModel>> getWaterLogs(String userId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return _waterLogsRef(userId)
        .where('time',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('time', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('time', descending: false)
        .snapshots()
        .map((s) => s.docs
            .map((d) => WaterLogModel.fromMap(d.data(), d.id))
            .toList());
  }

  /// Kullanıcının günlük su hedefini döner (userProfiles'dan).
  /// Hedef `waterDailyGoal` alanında saklanır.
  Future<int?> getWaterDailyGoal(String userId) async {
    final doc = await userProfilesRef.doc(userId).get();
    if (!doc.exists) return null;
    final data = doc.data()?.toMap();
    return data?['waterDailyGoal'] as int?;
  }

  /// Günlük su hedefini günceller.
  Future<void> setWaterDailyGoal(String userId, int goal) async {
    await userProfilesRef.doc(userId).update({'waterDailyGoal': goal});
  }

  /// Yeni bir su logu ekler.
  Future<void> addWaterLog(String userId, WaterLogModel log) async {
    await _waterLogsRef(userId).add(log.toMap());
  }

  /// Belirli bir su logunu siler.
  Future<void> deleteWaterLog(String userId, String logId) async {
    await _waterLogsRef(userId).doc(logId).delete();
  }

  /// Belirli bir günün tüm su loglarını siler.
  Future<void> clearWaterLogs(String userId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final snapshot = await _waterLogsRef(userId)
        .where('time',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('time', isLessThan: Timestamp.fromDate(endOfDay))
        .get();
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
