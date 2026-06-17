import 'package:flutter_test/flutter_test.dart';
import 'package:herbaformix/models/recipe_model.dart';

void main() {
  group('RecipeIngredient', () {
    test('fromMap doğru çevirir', () {
      final i = RecipeIngredient.fromMap(
          {'name': 'Süt', 'amount': '250 ml', 'note': 'yağsız'});
      expect(i.name, 'Süt');
      expect(i.amount, '250 ml');
      expect(i.note, 'yağsız');
    });

    test('eksik note → null', () {
      final i = RecipeIngredient.fromMap({'name': 'X', 'amount': '1'});
      expect(i.note, isNull);
    });

    test('eksik name/amount → boş string', () {
      final i = RecipeIngredient.fromMap({});
      expect(i.name, '');
      expect(i.amount, '');
    });

    test('round-trip korunur', () {
      final original = RecipeIngredient(name: 'Muz', amount: '1 adet');
      final round = RecipeIngredient.fromMap(original.toMap());
      expect(round.name, 'Muz');
      expect(round.amount, '1 adet');
      expect(round.note, isNull);
    });
  });

  group('RecipeNutrition', () {
    test('fromMap doğru çevirir', () {
      final n = RecipeNutrition.fromMap(
          {'protein': 25, 'carbs': 40, 'fat': 8, 'fiber': 5});
      expect(n.protein, 25);
      expect(n.carbs, 40);
      expect(n.fat, 8);
      expect(n.fiber, 5);
    });

    test('eksik alanlar → 0', () {
      final n = RecipeNutrition.fromMap({});
      expect(n.protein, 0);
      expect(n.carbs, 0);
      expect(n.fat, 0);
      expect(n.fiber, 0);
    });

    test('round-trip korunur', () {
      final original =
          RecipeNutrition(protein: 30, carbs: 50, fat: 10, fiber: 6);
      final round = RecipeNutrition.fromMap(original.toMap());
      expect(round.protein, 30);
      expect(round.carbs, 50);
      expect(round.fat, 10);
      expect(round.fiber, 6);
    });
  });

  group('RecipeModel', () {
    Map<String, dynamic> baseMap() => {
          'id': 'r1',
          'productId': 'formul1_id',
          'title': 'Çikolatalı Smoothie',
          'description': 'Yüksek protein, az yağ',
          'imageUrl': 'https://x.com/i.jpg',
          'videoUrl': null,
          'prepTimeMin': 5,
          'calories': 220,
          'goals': ['weight_loss', 'healthy_living'],
          'tags': ['kahvaltı', 'protein'],
          'ingredients': [
            {'name': 'Formül 1', 'amount': '2 ölçek'},
            {'name': 'Süt', 'amount': '250 ml'},
          ],
          'steps': ['Karıştır', 'Ser'],
          'nutritionInfo': {
            'protein': 25,
            'carbs': 30,
            'fat': 5,
            'fiber': 3,
          },
          'tips': 'Soğuk içilebilir',
          'isRecommended': true,
        };

    test('fromMap tüm alanları çevirir', () {
      final r = RecipeModel.fromMap(baseMap());
      expect(r.id, 'r1');
      expect(r.productId, 'formul1_id');
      expect(r.title, 'Çikolatalı Smoothie');
      expect(r.description, 'Yüksek protein, az yağ');
      expect(r.imageUrl, 'https://x.com/i.jpg');
      expect(r.videoUrl, isNull);
      expect(r.prepTimeMin, 5);
      expect(r.calories, 220);
      expect(r.goals, ['weight_loss', 'healthy_living']);
      expect(r.tags, ['kahvaltı', 'protein']);
      expect(r.ingredients.length, 2);
      expect(r.ingredients[0].name, 'Formül 1');
      expect(r.steps, ['Karıştır', 'Ser']);
      expect(r.nutritionInfo?.protein, 25);
      expect(r.tips, 'Soğuk içilebilir');
      expect(r.isRecommended, true);
    });

    test('eksik alanlar için varsayılan', () {
      final r = RecipeModel.fromMap({});
      expect(r.id, '');
      expect(r.title, '');
      expect(r.prepTimeMin, 0);
      expect(r.calories, 0);
      expect(r.goals, isEmpty);
      expect(r.tags, isEmpty);
      expect(r.ingredients, isEmpty);
      expect(r.steps, isEmpty);
      expect(r.isRecommended, false);
      expect(r.nutritionInfo, isNull);
    });

    test('nutritionInfo null ise null kalır', () {
      final map = baseMap()..['nutritionInfo'] = null;
      final r = RecipeModel.fromMap(map);
      expect(r.nutritionInfo, isNull);
    });

    test('toMap tüm alanları yazar', () {
      final r = RecipeModel.fromMap(baseMap());
      final map = r.toMap();
      expect(map['id'], 'r1');
      expect(map['title'], 'Çikolatalı Smoothie');
      expect(map['goals'], ['weight_loss', 'healthy_living']);
      expect((map['ingredients'] as List).length, 2);
      expect(map['nutritionInfo'], isNotNull);
      expect((map['nutritionInfo'] as Map)['protein'], 25);
    });

    test('round-trip korunur', () {
      final original = RecipeModel.fromMap(baseMap());
      final round = RecipeModel.fromMap(original.toMap());
      expect(round.id, original.id);
      expect(round.title, original.title);
      expect(round.calories, original.calories);
      expect(round.goals, original.goals);
      expect(round.ingredients.length, original.ingredients.length);
      expect(round.nutritionInfo?.protein, original.nutritionInfo?.protein);
      expect(round.isRecommended, original.isRecommended);
    });
  });
}
