class ProductModel {
  final String id;
  final String name;
  final double vp;
  final double? price;
  final String? stockNo; // Changed from sku
  final String? category;
  final String? imageUrl;
  // UPDATED AND NEW FIELDS:
  final String? overview; // Replaces description and shortDescription
  final String? usageInfo;
  final String? features; // New field (String)
  final String? ingredients; // New field (String)
  final int? recommendedOffsetMins; // Uyanma saatinden kaç dakika sonra kullanılacağı
  final Map<String, String>? instructionsByGoal; // Hedefe göre değişen kullanım bilgileri

  ProductModel({
    required this.id,
    required this.name,
    required this.vp,
    this.price,
    this.stockNo,
    this.category,
    this.imageUrl,
    this.overview,
    this.usageInfo,
    this.features,
    this.ingredients,
    this.recommendedOffsetMins,
    this.instructionsByGoal,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ProductModel(
      id: documentId,
      name: map['name'] ?? 'İsim Yok',
      vp: (map['vp'] ?? 0.0).toDouble(),
      price: (map['price'] as num?)?.toDouble(),
      stockNo: map['stockNo'] as String?, // Changed from sku
      category: map['category'] as String?,
      imageUrl: map['imageUrl'] as String?,
      overview: map['overview'] as String?, // Mapped from overview
      usageInfo: map['usageInfo'] as String?,
      features: map['features'] as String?, // Mapped from features
      ingredients: map['ingredients'] as String?, // Mapped from ingredients
      recommendedOffsetMins: map['recommended_offset_mins'] as int?,
      instructionsByGoal: map['instructions_by_goal'] != null
          ? Map<String, String>.from(map['instructions_by_goal'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'vp': vp,
      'price': price,
      'stockNo': stockNo, // Changed from sku
      'category': category,
      'imageUrl': imageUrl,
      'overview': overview,
      'usageInfo': usageInfo,
      'features': features,
      'ingredients': ingredients,
      'recommended_offset_mins': recommendedOffsetMins,
      'instructions_by_goal': instructionsByGoal,
    };
  }
}