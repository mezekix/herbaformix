class ProductModel {
  final String id;
  final String name;
  final double vp;
  final double? price;
  final String? sku;
  final String? category;
  final String? imageUrl;
  // YENİ ALANLAR:
  final String? description; // Ürün açıklaması
  final String? usageInfo; // Kullanım bilgisi
  final List<String>? benefits; // Faydaları (liste olarak)
  final List<String>? keyIngredients; // Ana içerikler (liste olarak)
  final String? shortDescription; // Kısa açıklama veya slogan

  ProductModel({
    required this.id,
    required this.name,
    required this.vp,
    this.price,
    this.sku,
    this.category,
    this.imageUrl,
    this.description,
    this.usageInfo,
    this.benefits,
    this.keyIngredients,
    this.shortDescription,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ProductModel(
      id: documentId,
      name: map['name'] ?? 'İsim Yok',
      vp: (map['vp'] ?? 0.0).toDouble(),
      price: (map['price'] as num?)?.toDouble(),
      sku: map['sku'] as String?,
      category: map['category'] as String?,
      imageUrl: map['imageUrl'] as String?,
      description: map['description'] as String?,
      usageInfo: map['usageInfo'] as String?,
      benefits: map['benefits'] != null
          ? List<String>.from(map['benefits'])
          : null,
      keyIngredients: map['keyIngredients'] != null
          ? List<String>.from(map['keyIngredients'])
          : null,
      shortDescription: map['shortDescription'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'vp': vp,
      'price': price,
      'sku': sku,
      'category': category,
      'imageUrl': imageUrl,
      'description': description,
      'usageInfo': usageInfo,
      'benefits': benefits,
      'keyIngredients': keyIngredients,
      'shortDescription': shortDescription,
    };
  }
}
