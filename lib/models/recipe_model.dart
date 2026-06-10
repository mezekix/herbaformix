class RecipeIngredient {
  final String name;
  final String amount;
  final String? note;

  RecipeIngredient({
    required this.name,
    required this.amount,
    this.note,
  });

  factory RecipeIngredient.fromMap(Map<String, dynamic> map) {
    return RecipeIngredient(
      name: map['name'] ?? '',
      amount: map['amount'] ?? '',
      note: map['note'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount,
      'note': note,
    };
  }
}

class RecipeNutrition {
  final int protein;
  final int carbs;
  final int fat;
  final int fiber;

  RecipeNutrition({
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
  });

  factory RecipeNutrition.fromMap(Map<String, dynamic> map) {
    return RecipeNutrition(
      protein: map['protein'] ?? 0,
      carbs: map['carbs'] ?? 0,
      fat: map['fat'] ?? 0,
      fiber: map['fiber'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
    };
  }
}

class RecipeModel {
  final String id;
  final String productId;
  final String title;
  final String description;
  final String? imageUrl;
  final int prepTimeMin;
  final int calories;
  final List<String> goals;
  final List<String> tags;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;
  final RecipeNutrition? nutritionInfo;
  final String? tips;
  final bool isRecommended;

  RecipeModel({
    required this.id,
    required this.productId,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.prepTimeMin,
    required this.calories,
    required this.goals,
    required this.tags,
    required this.ingredients,
    required this.steps,
    this.nutritionInfo,
    this.tips,
    this.isRecommended = false,
  });

  factory RecipeModel.fromMap(Map<String, dynamic> map) {
    return RecipeModel(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'],
      prepTimeMin: map['prepTimeMin'] ?? 0,
      calories: map['calories'] ?? 0,
      goals: List<String>.from(map['goals'] ?? []),
      tags: List<String>.from(map['tags'] ?? []),
      ingredients: List<RecipeIngredient>.from(
        (map['ingredients'] ?? []).map((x) => RecipeIngredient.fromMap(x)),
      ),
      steps: List<String>.from(map['steps'] ?? []),
      nutritionInfo: map['nutritionInfo'] != null
          ? RecipeNutrition.fromMap(map['nutritionInfo'])
          : null,
      tips: map['tips'],
      isRecommended: map['isRecommended'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'prepTimeMin': prepTimeMin,
      'calories': calories,
      'goals': goals,
      'tags': tags,
      'ingredients': ingredients.map((x) => x.toMap()).toList(),
      'steps': steps,
      'nutritionInfo': nutritionInfo?.toMap(),
      'tips': tips,
      'isRecommended': isRecommended,
    };
  }
}
