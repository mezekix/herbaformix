import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/customer_model.dart';
import '../../models/invite_code_model.dart';
import '../../models/invite_status.dart';
import '../../models/user_profile_model.dart';
import '../../core/logger.dart';

/// `/inviteCodes/{codeId}` — distribütör davet kodu yaşam döngüsü.
///
/// Bu repository içerisinde bazı işlemler birden çok koleksiyona dokunan
/// atomik batch'ler çalıştırır:
/// - [addCustomerWithInviteCode]: customers + inviteCodes
/// - [signUpWithInviteCodeBatch]: userProfiles + inviteCodes + customers
/// - [regenerateInviteCode]: customers + inviteCodes
///
/// Cross-koleksiyon yazımlar kasıtlıdır — davet kodu hayat döngüsü gereği
/// transaction-benzeri bir bütünlüğe ihtiyaç duyar.
class InviteCodeRepository {
  InviteCodeRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<InviteCodeModel> get ref => _db
      .collection('inviteCodes')
      .withConverter<InviteCodeModel>(
        fromFirestore: (s, _) => InviteCodeModel.fromMap(s.data()!, s.id),
        toFirestore: (m, _) => m.toMap(),
      );

  CollectionReference<Map<String, dynamic>> get _lookupRef =>
      _db.collection('inviteCodeLookups');

  Map<String, dynamic> _lookupData(InviteCodeModel inviteCode) {
    return <String, dynamic>{
      'code': inviteCode.code,
      'distributorId': inviteCode.distributorId,
      'createdAt': Timestamp.fromDate(inviteCode.createdAt),
      'expiresAt': Timestamp.fromDate(inviteCode.expiresAt),
      'status': inviteCode.status.toFirestore(),
      'isUsed': inviteCode.isUsed,
      if (inviteCode.usedByUserId != null)
        'usedByUserId': inviteCode.usedByUserId,
      if (inviteCode.customerRecordId != null)
        'customerRecordId': inviteCode.customerRecordId,
    };
  }

  /// 8 karakterli, ABCD...Z0..9 alfabesinden kriptografik rastgele kod.
  @visibleForTesting
  String generateCode() {
    const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(
      8,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// Maks 5 deneme yaparak çakışmayan bir kod üretir; aksi hâlde fırlatır.
  Future<String> _uniqueCode() async {
    const maxAttempts = 5;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final code = generateCode();
      final docSnapshot = await _lookupRef.doc(code).get();
      if (!docSnapshot.exists) return code;
    }
    throw Exception('Benzersiz davet kodu üretilemedi. Lütfen tekrar deneyin.');
  }

  Future<InviteCodeModel> createInviteCode(
    String distributorId, {
    String? customerRecordId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
  }) async {
    final code = await _uniqueCode();
    final now = DateTime.now();
    final model = InviteCodeModel(
      id: code,
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

    final docRef = ref.doc(code);
    final batch = _db.batch();
    // `docRef` is typed as DocumentReference<InviteCodeModel>; pass the model
    // itself so Firestore invokes the registered converter. Passing toMap()
    // here makes WriteBatch infer Object and causes a runtime converter cast.
    batch.set(docRef, model);
    batch.set(_lookupRef.doc(code), _lookupData(model));
    await batch.commit();
    final snapshot = await docRef.get();
    return snapshot.data()!;
  }

  /// Müşteri kaydını ve davet kodunu **atomik** olarak oluşturur.
  Future<({CustomerModel customer, InviteCodeModel inviteCode})>
  addCustomerWithInviteCode({
    required String distributorId,
    required CustomerModel customer,
  }) async {
    final code = await _uniqueCode();

    final customerDocRef = _db
        .collection('users')
        .doc(distributorId)
        .collection('customers')
        .doc();

    final inviteDocRef = _db.collection('inviteCodes').doc(code);

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
      inviteCodeId: code,
    );

    final inviteToWrite = InviteCodeModel(
      id: code,
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
    batch.set(_lookupRef.doc(code), _lookupData(inviteToWrite));

    try {
      await batch.commit();
    } catch (e) {
      AppLogger.error(
        'Davet koduyla müşteri ekleme batch hatası',
        tag: 'InviteCodeRepository',
        error: e,
      );
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
    final code = await _uniqueCode();

    final newInviteDocRef = _db.collection('inviteCodes').doc(code);
    final oldInviteDocRef = _db.collection('inviteCodes').doc(oldInviteCodeId);
    final customerDocRef = _db
        .collection('users')
        .doc(distributorId)
        .collection('customers')
        .doc(customerRecordId);

    final now = DateTime.now();
    final newInvite = InviteCodeModel(
      id: code,
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
    batch.update(_lookupRef.doc(oldInviteCodeId), {'status': 'expired'});
    batch.set(newInviteDocRef, newInvite.toMap());
    batch.set(_lookupRef.doc(code), _lookupData(newInvite));
    batch.update(customerDocRef, {'inviteCodeId': newInviteDocRef.id});

    try {
      await batch.commit();
    } catch (e) {
      AppLogger.error(
        'Davet kodu yenileme batch hatası',
        tag: 'InviteCodeRepository',
        error: e,
      );
      throw Exception('Yeni davet kodu üretilemedi: $e');
    }

    return newInvite;
  }

  /// Geçerli bir davet kodunu doğrular ve [InviteCodeModel]'i döner.
  /// Kullanılmış / süresi geçmiş kodlarda anlamlı hata fırlatır.
  Future<InviteCodeModel?> validateInviteCode(String code) async {
    final normalizedCode = code.trim().toUpperCase();
    final docSnapshot = await _lookupRef.doc(normalizedCode).get();
    if (!docSnapshot.exists) return null;

    final data = docSnapshot.data();
    if (data == null) return null;
    final inviteCode = InviteCodeModel.fromMap(data, normalizedCode);

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

  /// Yeni kullanıcının profilini oluşturur, davet kodunu kullanılmış işaretler
  /// ve varsa ilgili customer kaydını günceller — hepsi tek batch'te.
  Future<void> signUpWithInviteCodeBatch({
    required UserProfileModel userProfile,
    required InviteCodeModel inviteCode,
    required String newUserId,
    bool existingUser = false,
  }) async {
    try {
      final batch = _db.batch();

      final userProfileRef = _db.collection('userProfiles').doc(newUserId);
      if (existingUser) {
        batch.update(userProfileRef, {
          'assignedDistributorId': inviteCode.distributorId,
          'connectionInviteCodeId': inviteCode.id,
        });
      } else {
        batch.set(userProfileRef, userProfile.toMap(), SetOptions(merge: true));
      }

      final inviteCodeRef = ref.doc(inviteCode.id);
      batch.update(inviteCodeRef, {
        'isUsed': true,
        'status': 'used',
        'usedByUserId': newUserId,
      });
      batch.update(_lookupRef.doc(inviteCode.id), {
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
      AppLogger.error(
        'Davet koduyla kayıt batch hatası',
        tag: 'InviteCodeRepository',
        error: e,
      );
      throw Exception('Kayıt işlemi tamamlanamadı: $e');
    }
  }

  Stream<List<InviteCodeModel>> getInviteCodesForDistributor(
    String distributorId,
  ) {
    return ref
        .where('distributorId', isEqualTo: distributorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList())
        .handleError((error) {
          AppLogger.error(
            'Distribütör davet kodları alınamadı',
            tag: 'InviteCodeRepository',
            error: error,
          );
          return <InviteCodeModel>[];
        });
  }

  Future<InviteCodeModel?> getInviteCodeForCustomer(
    String customerRecordId,
  ) async {
    try {
      final s = await ref
          .where('customerRecordId', isEqualTo: customerRecordId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      if (s.docs.isEmpty) return null;
      return s.docs.first.data();
    } catch (e) {
      AppLogger.error(
        'Müşteri davet kodu alınamadı',
        tag: 'InviteCodeRepository',
        error: e,
      );
      return null;
    }
  }

  Future<void> deleteInviteCode(String inviteCodeId) async {
    try {
      final batch = _db.batch();
      batch.delete(_db.collection('inviteCodes').doc(inviteCodeId));
      batch.delete(_lookupRef.doc(inviteCodeId));
      await batch.commit();
      AppLogger.info('Davet kodu silindi', tag: 'InviteCodeRepository');
    } catch (e) {
      AppLogger.error(
        'Davet kodu silinemedi',
        tag: 'InviteCodeRepository',
        error: e,
      );
      throw Exception('Davet kodu silinemedi: $e');
    }
  }

  /// Süresi dolmuş ve kullanılmamış kodları toplu siler. Silinen kod sayısı
  /// döner; hata durumunda 0.
  Future<int> deleteExpiredInviteCodes(String distributorId) async {
    try {
      final now = DateTime.now();
      final s = await _db
          .collection('inviteCodes')
          .where('distributorId', isEqualTo: distributorId)
          .where('isUsed', isEqualTo: false)
          .where('expiresAt', isLessThan: Timestamp.fromDate(now))
          .get();

      if (s.docs.isEmpty) return 0;

      final batch = _db.batch();
      for (final doc in s.docs) {
        batch.delete(doc.reference);
        batch.delete(_lookupRef.doc(doc.id));
      }
      await batch.commit();
      AppLogger.info(
        '${s.docs.length} süresi dolmuş davet kodu silindi',
        tag: 'InviteCodeRepository',
      );
      return s.docs.length;
    } catch (e) {
      AppLogger.error(
        'Süresi dolmuş davet kodları silinemedi',
        tag: 'InviteCodeRepository',
        error: e,
      );
      return 0;
    }
  }
}
