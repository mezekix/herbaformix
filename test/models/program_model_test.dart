import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:herbaformix/features/program/models/program_model.dart';

void main() {
  group('MealProduct', () {
    test('fromMap/toMap round-trip', () {
      final m = MealProduct.fromMap({'productId': 'p1', 'productName': 'Formül 1'});
      expect(m.productId, 'p1');
      expect(m.productName, 'Formül 1');
      final round = MealProduct.fromMap(m.toMap());
      expect(round.productId, m.productId);
      expect(round.productName, m.productName);
    });

    test('eksik alanlar için boş string', () {
      final m = MealProduct.fromMap({});
      expect(m.productId, '');
      expect(m.productName, '');
    });
  });

  group('MealSlot', () {
    Map<String, dynamic> baseSlotMap() => {
          'id': 'morning',
          'kind': 'morning',
          'label': 'Sabah Öğünü',
          'scheduledTime': '08:00',
          'isNormalMeal': false,
          'products': [
            {'productId': 'p1', 'productName': 'Formül 1'},
            {'productId': 'p2', 'productName': 'Tea Mix'},
          ],
        };

    test('fromMap tüm alanları doğru çevirir', () {
      final s = MealSlot.fromMap(baseSlotMap());
      expect(s.id, 'morning');
      expect(s.kind, MealSlotKind.morning);
      expect(s.label, 'Sabah Öğünü');
      expect(s.scheduledTime, '08:00');
      expect(s.isNormalMeal, false);
      expect(s.products.length, 2);
      expect(s.products[0].productId, 'p1');
    });

    test('kind: lunch/evening/snack/bilinmeyen → doğru enum', () {
      for (final entry in {
        'lunch': MealSlotKind.lunch,
        'evening': MealSlotKind.evening,
        'snack': MealSlotKind.snack,
        'bilinmeyen': MealSlotKind.morning, // varsayılan
      }.entries) {
        final s = MealSlot.fromMap({...baseSlotMap(), 'kind': entry.key});
        expect(s.kind, entry.value, reason: entry.key);
      }
    });

    test('toMap kind enum\'unu string\'e çevirir', () {
      final s = MealSlot.fromMap(baseSlotMap()..['kind'] = 'lunch');
      final map = s.toMap();
      expect(map['kind'], 'lunch');
    });

    test('round-trip slot eşitliği', () {
      final original = MealSlot.fromMap(baseSlotMap());
      final round = MealSlot.fromMap(original.toMap());
      expect(round.id, original.id);
      expect(round.kind, original.kind);
      expect(round.scheduledTime, original.scheduledTime);
      expect(round.products.length, original.products.length);
    });

    test('summary: normal yemek için "Normal Yemek"', () {
      final s = MealSlot.fromMap(baseSlotMap()..['isNormalMeal'] = true);
      expect(s.summary, 'Normal Yemek');
    });

    test('summary: ürün yoksa "Ürün seçilmedi"', () {
      final s = MealSlot.fromMap(baseSlotMap()
        ..['isNormalMeal'] = false
        ..['products'] = []);
      expect(s.summary, 'Ürün seçilmedi');
    });

    test('summary: ürün adlarını virgülle birleştirir', () {
      final s = MealSlot.fromMap(baseSlotMap());
      expect(s.summary, 'Formül 1, Tea Mix');
    });

    test('hasProducts: normal yemek değil + ürün varsa true', () {
      final s = MealSlot.fromMap(baseSlotMap());
      expect(s.hasProducts, true);
    });

    test('hasProducts: normal yemek ise false', () {
      final s = MealSlot.fromMap(baseSlotMap()..['isNormalMeal'] = true);
      expect(s.hasProducts, false);
    });

    test('copyWith belirtilen alanı günceller', () {
      final s = MealSlot.fromMap(baseSlotMap());
      final updated = s.copyWith(scheduledTime: '09:30');
      expect(updated.scheduledTime, '09:30');
      expect(updated.id, s.id);
      expect(updated.products.length, s.products.length);
    });
  });

  group('ProgramModel', () {
    final testStart = DateTime(2026, 1, 1);
    final testCreated = DateTime(2025, 12, 30);

    Map<String, dynamic> baseProgramMap() => {
          'userGoal': 'weight_loss',
          'startDate': Timestamp.fromDate(testStart),
          'durationMonths': 3,
          'currentWeight': 85.0,
          'targetWeight': 75.0,
          'createdAt': Timestamp.fromDate(testCreated),
          'isActive': true,
          'slots': [
            {
              'id': 'morning',
              'kind': 'morning',
              'label': 'Sabah Öğünü',
              'scheduledTime': '09:00',
              'isNormalMeal': false,
              'products': [],
            },
            {
              'id': 'evening',
              'kind': 'evening',
              'label': 'Akşam Öğünü',
              'scheduledTime': '19:00',
              'isNormalMeal': false,
              'products': [],
            },
            {
              'id': 'lunch',
              'kind': 'lunch',
              'label': 'Öğle Öğünü',
              'scheduledTime': '13:00',
              'isNormalMeal': true,
              'products': [],
            },
          ],
        };

    test('fromMap tüm alanları çevirir', () {
      final p = ProgramModel.fromMap(baseProgramMap(), 'active');
      expect(p.id, 'active');
      expect(p.userGoal, 'weight_loss');
      expect(p.startDate, testStart);
      expect(p.durationMonths, 3);
      expect(p.currentWeight, 85.0);
      expect(p.targetWeight, 75.0);
      expect(p.createdAt, testCreated);
      expect(p.isActive, true);
      expect(p.slots.length, 3);
    });

    test('fromMap eksik alanlar için varsayılan', () {
      final p = ProgramModel.fromMap({
        'startDate': Timestamp.fromDate(testStart),
        'createdAt': Timestamp.fromDate(testCreated),
      }, 'p');
      expect(p.userGoal, 'healthy_living');
      expect(p.durationMonths, 1);
      expect(p.isActive, true);
      expect(p.slots, isEmpty);
    });

    test('toMap weight_loss hedefinde currentWeight ve targetWeight yazar',
        () {
      final p = ProgramModel.fromMap(baseProgramMap(), 'active');
      final map = p.toMap();
      expect(map['currentWeight'], 85.0);
      expect(map['targetWeight'], 75.0);
    });

    test('toMap healthy_living hedefinde currentWeight/targetWeight yazmaz',
        () {
      final p = ProgramModel.fromMap(
          baseProgramMap()..['userGoal'] = 'healthy_living', 'p');
      final map = p.toMap();
      expect(map.containsKey('currentWeight'), false);
      expect(map.containsKey('targetWeight'), false);
    });

    test('endDate başlangıç + ay sayısı eklenmiş şekilde', () {
      final p = ProgramModel.fromMap(baseProgramMap(), 'p');
      expect(p.endDate.year, 2026);
      expect(p.endDate.month, 4); // Ocak + 3
      expect(p.endDate.day, 1);
    });

    test('sortedSlots saate göre artan sırayla', () {
      final p = ProgramModel.fromMap(baseProgramMap(), 'p');
      final times = p.sortedSlots.map((s) => s.scheduledTime).toList();
      expect(times, ['09:00', '13:00', '19:00']);
    });

    test('round-trip korunur', () {
      final original = ProgramModel.fromMap(baseProgramMap(), 'p');
      final round = ProgramModel.fromMap(original.toMap(), 'p');
      expect(round.userGoal, original.userGoal);
      expect(round.startDate, original.startDate);
      expect(round.durationMonths, original.durationMonths);
      expect(round.slots.length, original.slots.length);
      expect(round.currentWeight, original.currentWeight);
      expect(round.targetWeight, original.targetWeight);
    });
  });

  group('Yardımcı fonksiyonlar', () {
    test('calculateMinDuration: 5 kg fark → 1 ay', () {
      expect(calculateMinDuration(80, 75), 1);
    });
    test('calculateMinDuration: 11 kg fark → 3 ay', () {
      expect(calculateMinDuration(86, 75), 3);
    });
    test('calculateMinDuration: hedef >= mevcut → hata', () {
      expect(() => calculateMinDuration(70, 75), throwsArgumentError);
      expect(() => calculateMinDuration(70, 70), throwsArgumentError);
    });

    test('calculateWaterStepTime: öğünden 30 dk önce', () {
      expect(calculateWaterStepTime('09:00'), '08:30');
      expect(calculateWaterStepTime('13:15'), '12:45');
    });
    test('calculateWaterStepTime: bozuk format → "00:00"', () {
      expect(calculateWaterStepTime('bozuk'), '00:00');
    });

    test('calculateEveningMealTime: uyku saatinden 3 saat önce', () {
      expect(calculateEveningMealTime('23:00'), '20:00');
      expect(calculateEveningMealTime('22:30'), '19:30');
    });

    test('buildDefaultSlots: 3 slot döner', () {
      final slots = buildDefaultSlots('weight_loss',
          wakeTime: '07:00', lunchTime: '13:00', sleepTime: '23:00');
      expect(slots.length, 3);
      expect(slots[0].id, 'morning');
      expect(slots[1].id, 'lunch');
      expect(slots[2].id, 'evening');
    });

    test('buildDefaultSlots: kilo vermede öğle normal yemek', () {
      final slots = buildDefaultSlots('weight_loss');
      expect(slots[1].isNormalMeal, true);
    });

    test('buildDefaultSlots: sağlıklı yaşamda öğle normal yemek değil', () {
      final slots = buildDefaultSlots('healthy_living');
      expect(slots[1].isNormalMeal, false);
    });

    test('buildDefaultSlots: sabah saati uyanma + 1 saat', () {
      final slots = buildDefaultSlots('healthy_living', wakeTime: '07:00');
      expect(slots[0].scheduledTime, '08:00');
    });
  });
}
