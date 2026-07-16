import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:herbaformix/features/products/providers/recipe_provider.dart';
import 'package:herbaformix/models/recipe_model.dart';

RecipeModel recipe(String id, String title) {
  return RecipeModel.fromMap({
    'id': id,
    'productId': 'formul1_id',
    'title': title,
    'description': 'Aciklama',
    'prepTimeMin': 5,
    'calories': 200,
    'goals': ['healthy_living'],
    'tags': ['shake'],
    'ingredients': <Map<String, dynamic>>[],
    'steps': ['Karistir'],
    'isRecommended': false,
  });
}

Map<String, dynamic> recipeData(String title) {
  return recipe('ignored', title).toMap()..remove('id');
}

Future<void> waitFor(bool Function() condition) async {
  for (var attempt = 0; attempt < 50 && !condition(); attempt++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  expect(condition(), isTrue);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'online tarifleri yerel tariflerle birlestirir ve gercek zamanli gunceller',
    () async {
      final firestore = FakeFirebaseFirestore();
      final provider = RecipeProvider(
        firestore: firestore,
        localRecipeLoader: () async => [recipe('local-shake', 'Yerel Shake')],
      );

      await provider.loadRecipes();
      provider.startOnlineSync();
      await waitFor(() => provider.hasCompletedOnlineSync);
      expect(provider.recipes.map((item) => item.id), contains('local-shake'));

      await firestore
          .collection('recipes')
          .doc('online-shake')
          .set(recipeData('Online Shake'));
      await waitFor(
        () => provider.recipes.any((item) => item.id == 'online-shake'),
      );

      expect(provider.recipes, hasLength(2));
      provider.dispose();
    },
  );

  test('yalnizca gorulmemis online tarifleri kullaniciya bildirir', () async {
    final firestore = FakeFirebaseFirestore();
    final provider = RecipeProvider(
      firestore: firestore,
      localRecipeLoader: () async => [recipe('local-shake', 'Yerel Shake')],
    );

    await provider.loadRecipes();
    provider.startOnlineSync();
    await waitFor(() => provider.hasCompletedOnlineSync);
    await firestore
        .collection('recipes')
        .doc('new-online-shake')
        .set(recipeData('Yeni Online Shake'));
    await waitFor(
      () => provider.recipes.any((item) => item.id == 'new-online-shake'),
    );

    expect(await provider.countUnseenOnlineRecipes('customer-1'), 1);
    await provider.markAllRecipesSeen('customer-1');
    expect(await provider.countUnseenOnlineRecipes('customer-1'), 0);

    await firestore
        .collection('recipes')
        .doc('second-online-shake')
        .set(recipeData('Ikinci Online Shake'));
    await waitFor(
      () => provider.recipes.any((item) => item.id == 'second-online-shake'),
    );
    expect(await provider.countUnseenOnlineRecipes('customer-1'), 1);
    provider.dispose();
  });

  test('tarifi Firestore koleksiyonuna belge kimligiyle ekler', () async {
    final firestore = FakeFirebaseFirestore();
    final provider = RecipeProvider(firestore: firestore);
    final newRecipe = recipe('distributor-shake', 'Distribütör Shake');

    await provider.addRecipe(newRecipe);

    final snapshot = await firestore
        .collection('recipes')
        .doc(newRecipe.id)
        .get();
    expect(snapshot.exists, isTrue);
    expect(snapshot.data()?['title'], newRecipe.title);
    expect(snapshot.data(), isNot(contains('id')));
    provider.dispose();
  });
}
