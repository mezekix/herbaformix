import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/meal_model.dart';

class CalorieProvider with ChangeNotifier {
  static const _calorieGoalKey = 'calorie_goal';
  static const _mealsKey = 'meals';
  static const _lastResetKey = 'calorie_last_reset';

  final Uuid _uuid = const Uuid();

  int _calorieGoal = 2000;
  List<Meal> _meals = [];
  bool _isLoading = false;
  DateTime? _lastResetDate;

  CalorieProvider() {
    _loadData();
  }

  // Getters
  int get calorieGoal => _calorieGoal;
  int get totalCalories => _meals.fold(0, (sum, meal) => sum + meal.calories);
  List<Meal> get meals => List.unmodifiable(_meals);
  bool get isLoading => _isLoading;
  double get progress => (totalCalories > 0 && _calorieGoal > 0)
      ? totalCalories / _calorieGoal
      : 0.0;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> _loadData() async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _calorieGoal = prefs.getInt(_calorieGoalKey) ?? 2000;
      final lastResetString = prefs.getString(_lastResetKey);
      if (lastResetString != null) {
        _lastResetDate = DateTime.parse(lastResetString);
        _checkForAutoReset();
      }

      final mealsJson = prefs.getStringList(_mealsKey) ?? [];
      _meals = mealsJson
          .map((json) => Meal.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      debugPrint("Kalori verileri yüklenirken hata oluştu: $e");
      _meals = []; // Hata durumunda listeyi temizle
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_calorieGoalKey, _calorieGoal);
    final mealsJson = _meals.map((meal) => jsonEncode(meal.toJson())).toList();
    await prefs.setStringList(_mealsKey, mealsJson);
    if (_lastResetDate != null) {
      await prefs.setString(_lastResetKey, _lastResetDate!.toIso8601String());
    }
  }

  void _checkForAutoReset() {
    final now = DateTime.now();
    if (_lastResetDate == null || now.difference(_lastResetDate!).inDays >= 1) {
      resetCalories();
    }
  }

  Future<void> addMeal(String name, int calories) async {
    final newMeal = Meal(
      id: _uuid.v4(),
      name: name,
      calories: calories,
      timestamp: DateTime.now(),
    );
    _meals.add(newMeal);
    _meals.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    await _saveData();
    notifyListeners();
  }

  Future<void> removeMeal(String mealId) async {
    _meals.removeWhere((meal) => meal.id == mealId);
    await _saveData();
    notifyListeners();
  }

  Future<void> setCalorieGoal(int newGoal) async {
    if (newGoal > 0) {
      _calorieGoal = newGoal;
      await _saveData();
      notifyListeners();
    }
  }

  Future<void> resetCalories() async {
    _meals.clear();
    _lastResetDate = DateTime.now();
    await _saveData();
    notifyListeners();
  }
}
