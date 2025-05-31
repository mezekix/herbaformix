class ProductModel {
  final String id; // Firestore doküman ID'si
  final String name; // Ürün Adı
  final double vp; // Hacim Puanı (Volume Points)
  final double? price; // Fiyat (Opsiyonel)
  final String? sku; // Stok Kodu (Opsiyonel)
  final String? category; // Kategori (Opsiyonel)
  final String? imageUrl; // Ürün Görseli URL'si (Opsiyonel)

  ProductModel({
    required this.id,
    required this.name,
    required this.vp,
    this.price,
    this.sku,
    this.category,
    this.imageUrl,
  });

  // Firestore'dan Map'i ProductModel'e dönüştürme
  factory ProductModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ProductModel(
      id: documentId,
      name: map['name'] ?? 'İsim Yok',
      vp: (map['vp'] ?? 0.0).toDouble(), // VP'nin double olduğundan emin olalım
      price: (map['price'] as num?)?.toDouble(), // Fiyat null olabilir
      sku: map['sku'] as String?,
      category: map['category'] as String?,
      imageUrl: map['imageUrl'] as String?,
    );
  }

  // ProductModel'i Firestore için Map'e dönüştürme (Şimdilik gerekmez ama ekleyelim)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'vp': vp,
      'price': price,
      'sku': sku,
      'category': category,
      'imageUrl': imageUrl,
    };
  }
}
