// MotivationRepository — fake_cloud_firestore ile mesaj + skor testleri
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:herbaformix/services/repositories/motivation_repository.dart';

void main() {
  group('MotivationRepository — distribütör mesajları', () {
    late FakeFirebaseFirestore fake;
    late MotivationRepository repo;
    const customerId = 'cust_1';

    setUp(() {
      fake = FakeFirebaseFirestore();
      repo = MotivationRepository(firestore: fake);
    });

    test('saveDistributorMotivationMessage o günün mesajını yazar', () async {
      await repo.saveDistributorMotivationMessage(
          customerId, 'Bugün harika bir gün olacak!');

      final doc = await fake
          .collection('motivations')
          .doc(customerId)
          .collection('daily_messages')
          .doc('today')
          .get();

      expect(doc.exists, true);
      expect(doc.data()?['distributor_mesaji'],
          'Bugün harika bir gün olacak!');
      expect(doc.data()?['distributor_mesaji_tarihi'], isA<Timestamp>());
    });

    test('saveDistributorMotivationMessage merge ile mesajı günceller',
        () async {
      await repo.saveDistributorMotivationMessage(customerId, 'İlk mesaj');
      await repo.saveDistributorMotivationMessage(
          customerId, 'Güncellenmiş mesaj');

      final doc = await fake
          .collection('motivations')
          .doc(customerId)
          .collection('daily_messages')
          .doc('today')
          .get();
      expect(doc.data()?['distributor_mesaji'], 'Güncellenmiş mesaj');
    });

    test('getDistributorMotivationMessage bugünün mesajını okur', () async {
      await repo.saveDistributorMotivationMessage(customerId, 'Test mesajı');

      final msg = await repo.getDistributorMotivationMessage(customerId);
      expect(msg, 'Test mesajı');
    });

    test('getDistributorMotivationMessage mesaj yoksa null döner', () async {
      final msg = await repo.getDistributorMotivationMessage('yok');
      expect(msg, isNull);
    });

    test('getDistributorMotivationMessage bir başkasının mesajını döndürmez',
        () async {
      await repo.saveDistributorMotivationMessage('musteri_A', 'A için');

      final bMsg = await repo.getDistributorMotivationMessage('musteri_B');
      expect(bMsg, isNull);
    });

    test('getDistributorMotivationMessage dünkü mesajı döndürmez', () async {
      // Dünkü mesajı manuel olarak yaz
      final yesterday =
          DateTime.now().subtract(const Duration(days: 1));
      await fake
          .collection('motivations')
          .doc(customerId)
          .collection('daily_messages')
          .doc('yesterday')
          .set({
        'distributor_mesaji': 'Dünkü mesaj',
        'timestamp': Timestamp.fromDate(yesterday),
      });

      final msg = await repo.getDistributorMotivationMessage(customerId);
      expect(msg, isNull);
    });
  });

  group('MotivationRepository — skorlar', () {
    late FakeFirebaseFirestore fake;
    late MotivationRepository repo;
    const customerId = 'cust_1';

    setUp(() {
      fake = FakeFirebaseFirestore();
      repo = MotivationRepository(firestore: fake);
    });

    test('saveMotivationScore skor belgesi yazar', () async {
      await repo.saveMotivationScore(customerId, 8);

      final snap = await fake
          .collection('motivation_scores')
          .where('musteri_id', isEqualTo: customerId)
          .get();
      expect(snap.docs.length, 1);
      expect(snap.docs.first.data()['skor'], 8);
      expect(snap.docs.first.data()['musteri_id'], customerId);
    });

    test('saveMotivationScore aynı gün için merge eder', () async {
      await repo.saveMotivationScore(customerId, 5);
      await repo.saveMotivationScore(customerId, 9);

      final snap = await fake
          .collection('motivation_scores')
          .where('musteri_id', isEqualTo: customerId)
          .get();
      // Doc ID gün-bazlı olduğu için tek belge
      expect(snap.docs.length, 1);
      expect(snap.docs.first.data()['skor'], 9);
    });

    test('getMotivationScoresLastDays mevcut skoru döner', () async {
      await repo.saveMotivationScore(customerId, 7);

      final scores = await repo.getMotivationScoresLastDays(customerId, 7);
      expect(scores, [7]);
    });

    test('getMotivationScoresLastDays hiç skor yoksa boş liste', () async {
      final scores = await repo.getMotivationScoresLastDays('yok', 7);
      expect(scores, isEmpty);
    });

    test('getMotivationScoresLastDays bir başkasının skorunu döndürmez',
        () async {
      await repo.saveMotivationScore('musteri_A', 6);

      final bScores =
          await repo.getMotivationScoresLastDays('musteri_B', 7);
      expect(bScores, isEmpty);
    });
  });
}
