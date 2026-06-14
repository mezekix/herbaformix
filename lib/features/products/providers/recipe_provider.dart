import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../../models/product_model.dart';
import '../../../models/recipe_model.dart';

class RecipeProvider extends ChangeNotifier {
  List<RecipeModel> _recipes = [];
  bool _isLoading = false;

  List<RecipeModel> get recipes => _recipes;
  bool get isLoading => _isLoading;

  Future<void> loadRecipes() async {
    if (_recipes.isNotEmpty) return; // Zaten yüklendi

    _isLoading = true;
    notifyListeners();

    try {
      final jsonString = await rootBundle.loadString('assets/recipes.json');
      final data = json.decode(jsonString);
      
      final List<dynamic> recipeList = data['recipes'] ?? [];
      _recipes = recipeList.map((x) => RecipeModel.fromMap(x)).toList();
      
    } catch (e) {
      debugPrint('Tarifler yüklenirken hata: $e');
      _recipes = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Belirli bir ürün için olan tarifleri getirir.
  /// Tarifler şimdilik yalnızca Formül 1 ürünleri içindir; başka ürünlerde
  /// (örn. cilt bakımı, dış beslenme) boş liste döner.
  List<RecipeModel> getRecipesForProduct(ProductModel product) {
    final name = product.name.toLowerCase();
    final isFormula1 = name.contains('formül 1') || name.contains('formul 1');
    if (!isFormula1) return const [];
    return _recipes.where((r) => r.productId == 'formul1_id').toList();
  }

  /// Hedefe göre tarifleri filtreler
  List<RecipeModel> filterByGoal(List<RecipeModel> all, String? userGoal) {
    if (userGoal == null || userGoal.isEmpty) return all;
    return all.where((r) => r.goals.contains(userGoal)).toList();
  }

  /// Önerilen tarifleri getirir
  List<RecipeModel> getRecommended(List<RecipeModel> all) {
    return all.where((r) => r.isRecommended).toList();
  }

  /// Günün tarifini hesaplar (seed mantığı ile)
  RecipeModel? getDailyRecipe(String? userGoal) {
    if (_recipes.isEmpty) return null;
    
    // Önce hedefe uygun tarifleri filtrele
    final filtered = filterByGoal(_recipes, userGoal);
    final listToUse = filtered.isNotEmpty ? filtered : _recipes;
    
    // Seed hesaplama
    final daysSinceEpoch = DateTime.now().millisecondsSinceEpoch ~/ 86400000;
    final index = daysSinceEpoch % listToUse.length;
    
    return listToUse[index];
  }
}
