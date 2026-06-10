import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../features/program/models/program_template_model.dart';

/// `/programs/{programId}` — distribütörlerin oluşturduğu şablon program kataloğu.
///
/// Güvenlik: `firestore.rules` — okuma giriş yapmışlara, yazma yalnız distribütörlere.
/// Müşteriye özel aktif programlar (`/users/{uid}/program/active`) ayrı bir
/// yolda tutulur; bu repository onlarla ilgilenmez.
class ProgramTemplateRepository {
  ProgramTemplateRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _ref =>
      _db.collection('programs');

  /// Tüm şablonları stream olarak döner (en yeni güncellenen üstte).
  Stream<List<ProgramTemplateModel>> watchAll() {
    return _ref
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ProgramTemplateModel.fromMap(d.data(), d.id))
            .toList());
  }

  /// Belirli bir distribütörün şablonlarını stream olarak döner.
  Stream<List<ProgramTemplateModel>> watchByDistributor(String distributorId) {
    return _ref
        .where('createdBy', isEqualTo: distributorId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ProgramTemplateModel.fromMap(d.data(), d.id))
            .toList());
  }

  Future<ProgramTemplateModel?> getById(String id) async {
    try {
      final doc = await _ref.doc(id).get();
      if (!doc.exists || doc.data() == null) return null;
      return ProgramTemplateModel.fromMap(doc.data()!, doc.id);
    } on FirebaseException catch (e) {
      debugPrint('[ProgramTemplateRepository] getById hatası: ${e.message}');
      return null;
    }
  }

  /// Yeni şablon oluşturur, dokümanın ID'sini döner.
  Future<String> create(ProgramTemplateModel template) async {
    final docRef = await _ref.add(template.toMap());
    return docRef.id;
  }

  Future<void> update(ProgramTemplateModel template) async {
    final data = template.toMap();
    // Güncelleme zamanı her zaman sunucu güncellemesinde yenilenir.
    data['updatedAt'] = Timestamp.fromDate(DateTime.now());
    await _ref.doc(template.id).update(data);
  }

  Future<void> delete(String id) async {
    await _ref.doc(id).delete();
  }
}
