import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/progress_entry_model.dart';

/// `/users/{uid}/progressEntries/{entryId}` — gelişim/ölçüm kayıtları.
class ProgressRepository {
  ProgressRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<ProgressEntryModel> ref(String userId) => _db
      .collection('users')
      .doc(userId)
      .collection('progressEntries')
      .withConverter<ProgressEntryModel>(
        fromFirestore: (s, _) => ProgressEntryModel.fromMap(s.data()!, s.id),
        toFirestore: (m, _) => m.toMap(),
      );

  /// Son [limitDays] gündeki kayıtları kronolojik artan sırada akıtır.
  Stream<List<ProgressEntryModel>> getProgressEntries(
    String userId, {
    int limitDays = 90,
  }) {
    final since = DateTime.now().subtract(Duration(days: limitDays));
    return ref(userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .orderBy('date', descending: false)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  Future<DocumentReference<ProgressEntryModel>> addProgressEntry(
    String userId,
    ProgressEntryModel entry,
  ) =>
      ref(userId).add(entry);

  Future<void> updateProgressEntry(
    String userId,
    ProgressEntryModel entry,
  ) async {
    await ref(userId).doc(entry.id).update(entry.toMap());
  }

  Future<void> deleteProgressEntry(String userId, String entryId) async {
    await ref(userId).doc(entryId).delete();
  }
}
