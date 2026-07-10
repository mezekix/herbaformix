import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/customer_model.dart';
import '../models/distributor_customer_insights.dart';
import '../models/follow_up_model.dart';
import '../models/invite_code_model.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../models/progress_entry_model.dart';
import '../models/scheduled_follow_up_model.dart';
import '../models/user_profile_model.dart';
import '../models/water_log_model.dart';
import '../models/water_summary_model.dart';
import 'repositories/customer_insights_service.dart';
import 'repositories/customer_repository.dart';
import 'repositories/invite_code_repository.dart';
import 'repositories/motivation_repository.dart';
import 'repositories/order_repository.dart';
import 'repositories/product_repository.dart';
import 'repositories/progress_repository.dart';
import 'repositories/user_profile_repository.dart';
import 'repositories/water_repository.dart';
import 'package:herbaformix/core/logger.dart';

/// `FirestoreService` artık bir **facade**'dir. Tüm gerçek mantık
/// `lib/services/repositories/` altındaki odaklı repository sınıflarındadır:
///
/// - [UserProfileRepository]
/// - [ProductRepository]
/// - [CustomerRepository] (customers + follow_ups + scheduled_follow_ups)
/// - [OrderRepository]
/// - [InviteCodeRepository]
/// - [ProgressRepository]
/// - [WaterRepository] (waterLogs + waterSummaries)
/// - [MotivationRepository]
/// - [CustomerInsightsService] (cross-domain composition)
///
/// Bu sınıf, mevcut çağrı yerlerinin (`~30 dosya`) tek seferde refactor
/// edilmemesi için geriye uyumlu bir API sunar. Yeni kod yazarken repository
/// sınıflarını doğrudan kullanmayı tercih edin — bu facade ileride
/// `@Deprecated` ile işaretlenebilir.
class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance,
        _userProfileRepo = UserProfileRepository(firestore: firestore),
        _productRepo = ProductRepository(firestore: firestore),
        _customerRepo = CustomerRepository(firestore: firestore),
        _orderRepo = OrderRepository(firestore: firestore),
        _inviteCodeRepo = InviteCodeRepository(firestore: firestore),
        _progressRepo = ProgressRepository(firestore: firestore),
        _waterRepo = WaterRepository(firestore: firestore),
        _motivationRepo = MotivationRepository(firestore: firestore),
        _insightsService = CustomerInsightsService(firestore: firestore);

  final FirebaseFirestore _db;
  final UserProfileRepository _userProfileRepo;
  final ProductRepository _productRepo;
  final CustomerRepository _customerRepo;
  final OrderRepository _orderRepo;
  final InviteCodeRepository _inviteCodeRepo;
  final ProgressRepository _progressRepo;
  final WaterRepository _waterRepo;
  final MotivationRepository _motivationRepo;
  final CustomerInsightsService _insightsService;

  // Repository erişimi — yeni kod doğrudan repo'lara erişebilir
  UserProfileRepository get userProfile => _userProfileRepo;
  ProductRepository get products => _productRepo;
  CustomerRepository get customers => _customerRepo;
  OrderRepository get orders => _orderRepo;
  InviteCodeRepository get inviteCodes => _inviteCodeRepo;
  ProgressRepository get progress => _progressRepo;
  WaterRepository get water => _waterRepo;
  MotivationRepository get motivations => _motivationRepo;
  CustomerInsightsService get insights => _insightsService;

  // ── UserProfileRepository delegate ─────────────────────────────────────

  CollectionReference<UserProfileModel> get userProfilesRef =>
      _userProfileRepo.ref;
  Future<void> setUserProfile(UserProfileModel u) =>
      _userProfileRepo.setUserProfile(u);
  Future<UserProfileModel?> getUserProfile(String id) =>
      _userProfileRepo.getUserProfile(id);
  Stream<UserProfileModel?> watchUserProfile(String id) =>
      _userProfileRepo.watchUserProfile(id);
  Future<UserProfileModel?> getDistributorProfile(String id) =>
      _userProfileRepo.getDistributorProfile(id);
  Stream<List<UserProfileModel>> getCustomersByDistributorId(String id) =>
      _userProfileRepo.getCustomersByDistributorId(id);
  Future<List<UserProfileModel>> fetchCustomersByDistributorId(String id) =>
      _userProfileRepo.fetchCustomersByDistributorId(id);
  Future<void> disconnectDistributor(String customerUserId) =>
      _userProfileRepo.disconnectDistributor(customerUserId);
  Future<void> saveEarnedBadges(String userId, List<String> badgeIds) =>
      _userProfileRepo.saveEarnedBadges(userId, badgeIds);
  Future<int?> getWaterDailyGoal(String userId) =>
      _userProfileRepo.getWaterDailyGoal(userId);
  Future<void> setWaterDailyGoal(String userId, int goal) =>
      _userProfileRepo.setWaterDailyGoal(userId, goal);

  // ── ProductRepository delegate ─────────────────────────────────────────

  CollectionReference<ProductModel> get productsRef => _productRepo.ref;
  Stream<List<ProductModel>> getProducts({bool customerVisibleOnly = false}) =>
      _productRepo.getProducts(customerVisibleOnly: customerVisibleOnly);
  Future<DocumentReference<ProductModel>> addProduct(ProductModel p) =>
      _productRepo.addProduct(p);
  Future<void> updateProduct(ProductModel p) => _productRepo.updateProduct(p);
  Future<void> deleteProduct(String id) => _productRepo.deleteProduct(id);

  // ── CustomerRepository delegate ────────────────────────────────────────

  CollectionReference<CustomerModel> customersRef(String userId) =>
      _customerRepo.customersRef(userId);
  Future<DocumentReference<CustomerModel>> addCustomer(
          String userId, CustomerModel c) =>
      _customerRepo.addCustomer(userId, c);
  Stream<List<CustomerModel>> getCustomers(String userId) =>
      _customerRepo.getCustomers(userId);
  Future<List<CustomerModel>> fetchAllCustomers(String userId) =>
      _customerRepo.fetchAllCustomers(userId);
  Future<CustomerModel?> getCustomer(String userId, String customerId) =>
      _customerRepo.getCustomer(userId, customerId);
  Future<CustomerModel?> getCustomerByLinkedUserId(
          String distributorId, String linkedUserId) =>
      _customerRepo.getCustomerByLinkedUserId(distributorId, linkedUserId);
  Future<CustomerModel> createCustomerRecordFromUserProfile({
    required String distributorId,
    required UserProfileModel profile,
  }) =>
      _customerRepo.createCustomerRecordFromUserProfile(
        distributorId: distributorId,
        profile: profile,
      );
  Future<void> updateCustomer(String userId, CustomerModel c) =>
      _customerRepo.updateCustomer(userId, c);
  Future<void> deleteCustomer(String userId, String customerId) =>
      _customerRepo.deleteCustomer(userId, customerId);

  CollectionReference<FollowUpModel> followUpsRef(
          String userId, String customerId) =>
      _customerRepo.followUpsRef(userId, customerId);
  Stream<List<FollowUpModel>> getFollowUps(String userId, String customerId) =>
      _customerRepo.getFollowUps(userId, customerId);
  Future<void> addFollowUp(
          String userId, String customerId, FollowUpModel f) =>
      _customerRepo.addFollowUp(userId, customerId, f);
  Future<void> updateFollowUp(
          String userId, String customerId, FollowUpModel f) =>
      _customerRepo.updateFollowUp(userId, customerId, f);
  Future<void> deleteFollowUp(
          String userId, String customerId, String followUpId) =>
      _customerRepo.deleteFollowUp(userId, customerId, followUpId);

  CollectionReference<ScheduledFollowUpModel> scheduledFollowUpsRef() =>
      _customerRepo.scheduledFollowUpsRef();
  Stream<List<ScheduledFollowUpModel>> getUpcomingFollowUpsForConsultant(
          String consultantId, DateTime inTheNext) =>
      _customerRepo.getUpcomingFollowUpsForConsultant(consultantId, inTheNext);
  Stream<List<ScheduledFollowUpModel>> getScheduledFollowUpsForCustomer(
    String userId,
    String customerId, {
    String? linkedUserId,
  }) =>
      _customerRepo.getScheduledFollowUpsForCustomer(
        userId,
        customerId,
        linkedUserId: linkedUserId,
      );
  Future<void> addScheduledFollowUpBatch(List<ScheduledFollowUpModel> f) =>
      _customerRepo.addScheduledFollowUpBatch(f);
  Future<void> markScheduledFollowUpAsCompleted(String id) =>
      _customerRepo.markScheduledFollowUpAsCompleted(id);
  Future<void> snoozeScheduledFollowUp(String id, DateTime newDueDate) =>
      _customerRepo.snoozeScheduledFollowUp(id, newDueDate);
  Future<void> deleteScheduledFollowUp(String id) =>
      _customerRepo.deleteScheduledFollowUp(id);
  Future<void> addSingleScheduledFollowUp(ScheduledFollowUpModel f) =>
      _customerRepo.addSingleScheduledFollowUp(f);
  Future<void> updateScheduledFollowUp(ScheduledFollowUpModel f) =>
      _customerRepo.updateScheduledFollowUp(f);
  Stream<List<ScheduledFollowUpModel>> getAllScheduledFollowUpsForConsultant(
          String consultantId) =>
      _customerRepo.getAllScheduledFollowUpsForConsultant(consultantId);

  // ── OrderRepository delegate ───────────────────────────────────────────

  CollectionReference<OrderModel> ordersRef(String userId) =>
      _orderRepo.ref(userId);
  Stream<List<OrderModel>> getOrders(String userId, {String? customerId}) =>
      _orderRepo.getOrders(userId, customerId: customerId);
  Future<DocumentReference<OrderModel>> addOrder(String userId, OrderModel o) =>
      _orderRepo.addOrder(userId, o);
  Future<void> updateOrder(String userId, OrderModel o) =>
      _orderRepo.updateOrder(userId, o);
  Future<void> deleteOrder(String userId, String orderId) =>
      _orderRepo.deleteOrder(userId, orderId);

  // ── InviteCodeRepository delegate ──────────────────────────────────────

  CollectionReference<InviteCodeModel> get inviteCodesRef =>
      _inviteCodeRepo.ref;

  // Not: `generateCode()` test'i artık `InviteCodeRepository` üzerinden
  // doğrudan çağrılır; facade'tan kaldırıldı.

  Future<InviteCodeModel> createInviteCode(
    String distributorId, {
    String? customerRecordId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
  }) =>
      _inviteCodeRepo.createInviteCode(
        distributorId,
        customerRecordId: customerRecordId,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
      );

  Future<({CustomerModel customer, InviteCodeModel inviteCode})>
      addCustomerWithInviteCode({
    required String distributorId,
    required CustomerModel customer,
  }) =>
          _inviteCodeRepo.addCustomerWithInviteCode(
            distributorId: distributorId,
            customer: customer,
          );

  Future<InviteCodeModel> regenerateInviteCode({
    required String distributorId,
    required String customerRecordId,
    required String oldInviteCodeId,
    required String customerName,
    required String customerPhone,
    String? customerEmail,
  }) =>
      _inviteCodeRepo.regenerateInviteCode(
        distributorId: distributorId,
        customerRecordId: customerRecordId,
        oldInviteCodeId: oldInviteCodeId,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
      );

  Future<InviteCodeModel?> validateInviteCode(String code) =>
      _inviteCodeRepo.validateInviteCode(code);

  Future<void> signUpWithInviteCodeBatch({
    required UserProfileModel userProfile,
    required InviteCodeModel inviteCode,
    required String newUserId,
  }) =>
      _inviteCodeRepo.signUpWithInviteCodeBatch(
        userProfile: userProfile,
        inviteCode: inviteCode,
        newUserId: newUserId,
      );

  Stream<List<InviteCodeModel>> getInviteCodesForDistributor(String id) =>
      _inviteCodeRepo.getInviteCodesForDistributor(id);
  Future<InviteCodeModel?> getInviteCodeForCustomer(String customerRecordId) =>
      _inviteCodeRepo.getInviteCodeForCustomer(customerRecordId);
  Future<void> deleteInviteCode(String id) =>
      _inviteCodeRepo.deleteInviteCode(id);
  Future<int> deleteExpiredInviteCodes(String distributorId) =>
      _inviteCodeRepo.deleteExpiredInviteCodes(distributorId);

  // ── ProgressRepository delegate ────────────────────────────────────────

  CollectionReference<ProgressEntryModel> progressEntriesRef(String userId) =>
      _progressRepo.ref(userId);
  Stream<List<ProgressEntryModel>> getProgressEntries(
    String userId, {
    int limitDays = 90,
  }) =>
      _progressRepo.getProgressEntries(userId, limitDays: limitDays);
  Future<DocumentReference<ProgressEntryModel>> addProgressEntry(
          String userId, ProgressEntryModel e) =>
      _progressRepo.addProgressEntry(userId, e);
  Future<void> updateProgressEntry(String userId, ProgressEntryModel e) =>
      _progressRepo.updateProgressEntry(userId, e);
  Future<void> deleteProgressEntry(String userId, String entryId) =>
      _progressRepo.deleteProgressEntry(userId, entryId);

  // ── WaterRepository delegate ───────────────────────────────────────────

  Stream<List<WaterLogModel>> getWaterLogs(String userId, DateTime date) =>
      _waterRepo.getWaterLogs(userId, date);
  Future<void> addWaterLog(String userId, WaterLogModel log) =>
      _waterRepo.addWaterLog(userId, log);
  Future<void> deleteWaterLog(String userId, String logId) =>
      _waterRepo.deleteWaterLog(userId, logId);
  Future<void> updateWaterLog(String userId, WaterLogModel log) =>
      _waterRepo.updateWaterLog(userId, log);
  Future<void> clearWaterLogs(String userId, DateTime date) =>
      _waterRepo.clearWaterLogs(userId, date);
  Future<WaterSummaryModel?> getWaterSummary(String userId, String dateStr) =>
      _waterRepo.getWaterSummary(userId, dateStr);
  Stream<WaterSummaryModel?> watchWaterSummary(String userId, String dateStr) =>
      _waterRepo.watchWaterSummary(userId, dateStr);
  Future<void> setWaterSummary(String userId, WaterSummaryModel summary) =>
      _waterRepo.setWaterSummary(userId, summary);

  // ── MotivationRepository delegate ──────────────────────────────────────

  Future<String?> getDistributorMotivationMessage(String customerId) =>
      _motivationRepo.getDistributorMotivationMessage(customerId);
  Stream<String?> watchDistributorMotivationMessage(String customerId) =>
      _motivationRepo.watchDistributorMotivationMessage(customerId);
  Future<void> saveDistributorMotivationMessage(
          String customerId, String message) =>
      _motivationRepo.saveDistributorMotivationMessage(customerId, message);
  Future<void> saveMotivationScore(String customerId, int score) =>
      _motivationRepo.saveMotivationScore(customerId, score);
  Future<List<int>> getMotivationScoresLastDays(String customerId, int days) =>
      _motivationRepo.getMotivationScoresLastDays(customerId, days);

  // ── CustomerInsightsService delegate ───────────────────────────────────

  Future<DistributorCustomerInsights> getDistributorCustomerInsights(
          String customerUserId) =>
      _insightsService.getDistributorCustomerInsights(customerUserId);
  Future<int> getAtRiskCustomerCount(String distributorId) =>
      _insightsService.getAtRiskCustomerCount(distributorId);

  // ── Hesap silme (müşteri) ──────────────────────────────────────────────

  /// Müşteri hesabının Firestore tarafındaki **tüm** verisini siler.
  /// Auth user silme akışı çağıran tarafa (AuthProvider) aittir.
  ///
  /// Silinen veriler:
  /// - `/userProfiles/{uid}`
  /// - `/users/{uid}/calorieLogs/*`
  /// - `/users/{uid}/waterLogs/*`
  /// - `/users/{uid}/waterSummaries/*`
  /// - `/users/{uid}/progressEntries/*`
  /// - `/users/{uid}/dailyRoutines/*`
  /// - `/users/{uid}/daily_exercise/*`
  /// - `/users/{uid}/program/active`
  /// - `/users/{uid}` (ana doc, varsa)
  /// - `/userProfiles/{uid}`
  /// - `/motivations/{uid}/daily_messages/*` + `/motivations/{uid}` doc
  /// - `/motivation_scores/*` where `musteri_id == uid`
  /// - `/inviteCodes/*` where `usedByUserId == uid`
  ///
  /// Distribütör CRM kaydı **silinmez** — sadece güncellenir:
  /// `linkedUserId` temizlenir, `isActive=false`, `notes`'a
  /// "Müşteri hesabını sildi (tarih)" eklenir. Distribütörün iş notları korunur.
  Future<void> deleteCustomerAccountData(String uid) async {
    // 1) Profil bilgisini önce oku — distribütör CRM kaydına ulaşmak için
    //    assignedDistributorId lazım. Profil zaten yoksa devam et.
    final profile = await _userProfileRepo.getUserProfile(uid);
    final assignedDistributorId = profile?.assignedDistributorId;

    // 2) Distribütör CRM kaydını tamamen sil (kişisel verilerin -email vb.- kalmaması için).
    if (assignedDistributorId != null && assignedDistributorId.isNotEmpty) {
      try {
        final crmRecord = await _customerRepo.getCustomerByLinkedUserId(
          assignedDistributorId,
          uid,
        );
        if (crmRecord != null) {
          // Önce müşterinin altındaki follow_ups koleksiyonunu sil
          await _deleteSubcollection('users/$assignedDistributorId/customers/${crmRecord.id}/follow_ups');
          // Sonra CRM müşteri kaydını sil
          await _safeDeleteDoc(_db
              .collection('users')
              .doc(assignedDistributorId)
              .collection('customers')
              .doc(crmRecord.id));
        }
      } catch (e) {
        AppLogger.error('Distribütör CRM kaydı silme hatası: $e', tag: 'FirestoreService', error: e);
      }
    }

    // 3) Tüm olası alt koleksiyonları sil (müşteri veya distribütör fark etmeksizin).
    try {
      final customersSnap = await _db.collection('users/$uid/customers').get();
      for (final customerDoc in customersSnap.docs) {
        await _deleteSubcollection('users/$uid/customers/${customerDoc.id}/follow_ups');
      }
    } catch (e) {
      AppLogger.error('Müşteriler follow_ups silme hatası: $e', tag: 'FirestoreService', error: e);
    }

    await _deleteSubcollection('users/$uid/customers');
    await _deleteSubcollection('users/$uid/orders');
    await _deleteSubcollection('users/$uid/calorieLogs');
    await _deleteSubcollection('users/$uid/waterLogs');
    await _deleteSubcollection('users/$uid/waterSummaries');
    await _deleteSubcollection('users/$uid/progressEntries');
    await _deleteSubcollection('users/$uid/dailyRoutines');
    await _deleteSubcollection('users/$uid/daily_exercise');
    await _deleteSubcollection('users/$uid/program');
    await _deleteSubcollection('motivations/$uid/daily_messages');

    // Davet kodlarını temizle (eğer distribütör ise)
    await _deleteQuery(
      _db.collection('inviteCodes').where('distributorId', isEqualTo: uid),
    );

    // 4) Tek dokümanları sil.
    await _safeDeleteDoc(_db.collection('motivations').doc(uid));
    await _safeDeleteDoc(_db.collection('users').doc(uid));
    await _safeDeleteDoc(_db.collection('userProfiles').doc(uid));

    // 5) Sorgu temelli temizlik.
    // motivation_scores koleksiyonu
    await _deleteQuery(
      _db.collection('motivation_scores').where('musteri_id', isEqualTo: uid),
    );
    // Müşterinin kullandığı davet kodlarını temizle (usedByUserId alanı)
    await _deleteQuery(
      _db.collection('inviteCodes').where('usedByUserId', isEqualTo: uid),
    );
  }

  /// Belirtilen alt koleksiyondaki tüm dokümanları 450'lik batch'ler halinde siler.
  Future<void> _deleteSubcollection(String path) async {
    try {
      final snap = await _db.collection(path).get();
      if (snap.docs.isNotEmpty) {
        await _deleteDocs(snap.docs.map((d) => d.reference).toList());
      }
    } catch (e) {
      AppLogger.error('Alt koleksiyon silme hatası ($path): $e', tag: 'FirestoreService', error: e);
    }
  }

  /// Bir sorgunun döndürdüğü tüm dokümanları siler.
  Future<void> _deleteQuery(Query query) async {
    try {
      final snap = await query.get();
      if (snap.docs.isNotEmpty) {
        await _deleteDocs(snap.docs.map((d) => d.reference).toList());
      }
    } catch (e) {
      AppLogger.error('Sorgu silme hatası: $e', tag: 'FirestoreService', error: e);
    }
  }

  /// Referans listesini Firestore batch limiti (500) altında chunk'lara
  /// böler ve siler.
  Future<void> _deleteDocs(List<DocumentReference> refs) async {
    const chunkSize = 450;
    for (var i = 0; i < refs.length; i += chunkSize) {
      final end = (i + chunkSize < refs.length) ? i + chunkSize : refs.length;
      final batch = _db.batch();
      for (final ref in refs.sublist(i, end)) {
        batch.delete(ref);
      }
      await batch.commit();
    }
  }

  /// Doküman silme; doküman zaten yoksa hata fırlatmaz.
  Future<void> _safeDeleteDoc(DocumentReference ref) async {
    try {
      await ref.delete();
    } catch (e) {
      AppLogger.error('Doküman silme hatası (${ref.path}): $e', tag: 'FirestoreService', error: e);
    }
  }

  /// Yerel Firestore önbelleğini ve bağlantısını sıfırlar.
  /// Hesap silme veya kilitlenme durumlarında yerel SQLite veritabanının
  /// sunucuyla tutarsız kalmasını engellemek için kullanılır.
  Future<void> clearLocalCache() async {
    try {
      await _db.terminate();
      await _db.clearPersistence();
    } catch (e) {
      AppLogger.error('Firestore clearLocalCache hatası: $e', tag: 'FirestoreService', error: e);
    }
  }
}
