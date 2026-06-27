import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/customer_model.dart';
import '../../models/invite_code_model.dart';
import '../../models/invite_status.dart';
import '../../models/user_profile_model.dart';

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
      final existing = await ref.where('code', isEqualTo: code).limit(1).get();
      if (existing.docs.isEmpty) return code;
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
    await docRef.set(model);
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

  /// Geçerli bir davet kodunu doğrular ve [InviteCodeModel]'i döner.
  /// Kullanılmış / süresi geçmiş kodlarda anlamlı hata fırlatır.
  Future<InviteCodeModel?> validateInviteCode(String code) async {
    // Önce yeni yöntem (id == code) ile doğrudan dökümanı getirmeyi deniyoruz
    final docSnapshot = await ref.doc(code).get();
    
    InviteCodeModel? inviteCode;
    
    if (docSnapshot.exists) {
      inviteCode = docSnapshot.data();
    } else {
      // Geriye dönük uyumluluk: Eski UUID tabanlı kodlar için liste sorgusu
      try {
        final s = await ref.where('code', isEqualTo: code).limit(1).get();
        if (s.docs.isNotEmpty) {
          inviteCode = s.docs.first.data();
        }
      } catch (_) {}
    }

    if (inviteCode == null) return null;

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
  }) async {
    try {
      final batch = _db.batch();

      final userProfileRef =
          _db.collection('userProfiles').doc(newUserId);
      batch.set(userProfileRef, userProfile.toMap(), SetOptions(merge: true));

      final inviteCodeRef = ref.doc(inviteCode.id);
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

  Stream<List<InviteCodeModel>> getInviteCodesForDistributor(
    String distributorId,
  ) {
    return ref
        .where('distributorId', isEqualTo: distributorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList())
        .handleError((error) {
      debugPrint('getInviteCodesForDistributor hatası: $error');
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
      }
      await batch.commit();
      debugPrint('deleteExpiredInviteCodes: ${s.docs.length} kod silindi');
      return s.docs.length;
    } catch (e) {
      debugPrint('deleteExpiredInviteCodes hatası: $e');
      return 0;
    }
  }
}
