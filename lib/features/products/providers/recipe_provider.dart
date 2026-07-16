import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:herbaformix/core/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/product_model.dart';
import '../../../models/recipe_model.dart';

typedef LocalRecipeLoader = Future<List<RecipeModel>> Function();

class RecipeProvider extends ChangeNotifier {
  RecipeProvider({
    FirebaseFirestore? firestore,
    LocalRecipeLoader? localRecipeLoader,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _localRecipeLoader = localRecipeLoader;

  static const _collectionName = 'recipes';
  static const _seenRecipeIdsKeyPrefix = 'seen_recipe_ids_v1_';

  final FirebaseFirestore _firestore;
  final LocalRecipeLoader? _localRecipeLoader;
  final Map<String, RecipeModel> _localRecipes = {};
  final Map<String, RecipeModel> _onlineRecipes = {};
  List<RecipeModel> _recipes = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  bool _isLoading = false;
  bool _hasStarted = false;
  bool _hasCompletedOnlineSync = false;

  List<RecipeModel> get recipes => List.unmodifiable(_recipes);
  bool get isLoading => _isLoading;
  bool get hasCompletedOnlineSync => _hasCompletedOnlineSync;

  /// Yerel tarifleri çevrimdışı yedek olarak yükler ve Firestore'u dinler.
  Future<void> loadRecipes() async {
    if (_hasStarted) return;
    _hasStarted = true;
    _isLoading = true;
    notifyListeners();

    try {
      final bundledRecipes =
          await (_localRecipeLoader?.call() ?? _loadBundledRecipes());
      _localRecipes
        ..clear()
        ..addEntries(
          bundledRecipes
              .where((recipe) => recipe.id.isNotEmpty)
              .map((recipe) => MapEntry(recipe.id, recipe)),
        );
      _rebuildRecipeList();
    } catch (e) {
      AppLogger.error(
        'Yerel tarifler yüklenirken hata',
        tag: 'RecipeProvider',
        error: e,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void startOnlineSync() {
    if (_subscription != null) return;
    _hasCompletedOnlineSync = false;
    _subscription = _firestore
        .collection(_collectionName)
        .snapshots()
        .listen(_applyOnlineSnapshot, onError: _handleOnlineError);
  }

  void stopOnlineSync() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    _onlineRecipes.clear();
    _hasCompletedOnlineSync = false;
    _rebuildRecipeList();
  }

  Future<List<RecipeModel>> _loadBundledRecipes() async {
    final jsonString = await rootBundle.loadString('assets/recipes.json');
    final data = json.decode(jsonString) as Map<String, dynamic>;
    final recipeList = data['recipes'] as List<dynamic>? ?? const [];
    return recipeList
        .map((item) => RecipeModel.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  void _applyOnlineSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final onlineRecipes = <String, RecipeModel>{};
    for (final document in snapshot.docs) {
      try {
        onlineRecipes[document.id] = RecipeModel.fromMap({
          ...document.data(),
          'id': document.id,
        });
      } catch (e) {
        AppLogger.error(
          'Geçersiz online tarif atlandı: ${document.id}',
          tag: 'RecipeProvider',
          error: e,
        );
      }
    }

    _onlineRecipes
      ..clear()
      ..addAll(onlineRecipes);
    _hasCompletedOnlineSync = true;
    _rebuildRecipeList();
    notifyListeners();
  }

  void _handleOnlineError(Object error, StackTrace stackTrace) {
    _hasCompletedOnlineSync = true;
    AppLogger.error(
      'Online tarifler dinlenemedi; yerel tarifler kullanılıyor',
      tag: 'RecipeProvider',
      error: error,
      stackTrace: stackTrace,
    );
    notifyListeners();
  }

  void _rebuildRecipeList() {
    _recipes = <String, RecipeModel>{
      ..._localRecipes,
      ..._onlineRecipes,
    }.values.toList()..sort((a, b) => a.title.compareTo(b.title));
  }

  /// İlk kullanımda paket tarifleri görülmüş kabul edilir; yalnızca sonradan
  /// Firestore'a eklenen kimlikler yeni tarif olarak bildirilir.
  Future<int> countUnseenOnlineRecipes(String userId) async {
    if (userId.isEmpty || !_hasCompletedOnlineSync) return 0;
    final preferences = await SharedPreferences.getInstance();
    final key = '$_seenRecipeIdsKeyPrefix$userId';
    final seenIds = (preferences.getStringList(key) ?? _localRecipes.keys)
        .toSet();
    final unseenCount = _onlineRecipes.keys
        .where((id) => !seenIds.contains(id))
        .length;
    if (unseenCount == 0) await markAllRecipesSeen(userId);
    return unseenCount;
  }

  Future<void> markAllRecipesSeen(String userId) async {
    if (userId.isEmpty) return;
    final preferences = await SharedPreferences.getInstance();
    final ids = _recipes.map((recipe) => recipe.id).toList()..sort();
    await preferences.setStringList('$_seenRecipeIdsKeyPrefix$userId', ids);
  }

  /// Sadece Firestore kuralları tarafından yetkilendirilmiş distribütörler için
  /// yeni shake tarifini çevrimiçi kataloğa ekler.
  Future<void> addRecipe(RecipeModel recipe) async {
    if (recipe.id.isEmpty) {
      throw ArgumentError.value(
        recipe.id,
        'recipe.id',
        'Tarif kimliği boş olamaz.',
      );
    }

    final data = recipe.toMap()..remove('id');
    await _firestore.collection(_collectionName).doc(recipe.id).set(data);
  }

  List<RecipeModel> getRecipesForProduct(ProductModel product) {
    final name = product.name.toLowerCase();
    final isFormula1 = name.contains('formül 1') || name.contains('formul 1');
    if (!isFormula1) return const [];
    return _recipes
        .where((recipe) => recipe.productId == 'formul1_id')
        .toList();
  }

  List<RecipeModel> filterByGoal(List<RecipeModel> all, String? userGoal) {
    if (userGoal == null || userGoal.isEmpty) return all;
    return all.where((recipe) => recipe.goals.contains(userGoal)).toList();
  }

  List<RecipeModel> getRecommended(List<RecipeModel> all) {
    return all.where((recipe) => recipe.isRecommended).toList();
  }

  RecipeModel? getDailyRecipe(String? userGoal) {
    if (_recipes.isEmpty) return null;
    final filtered = filterByGoal(_recipes, userGoal);
    final listToUse = filtered.isNotEmpty ? filtered : _recipes;
    final daysSinceEpoch = DateTime.now().millisecondsSinceEpoch ~/ 86400000;
    return listToUse[daysSinceEpoch % listToUse.length];
  }

  RecipeModel? getRecipeForRoutine(String? userGoal, String routineId) {
    if (_recipes.isEmpty) return null;
    final filtered = filterByGoal(_recipes, userGoal);
    final listToUse = filtered.isNotEmpty ? filtered : _recipes;
    final index = routineId.hashCode.abs() % listToUse.length;
    return listToUse[index];
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
