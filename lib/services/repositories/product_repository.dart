import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/product_model.dart';

/// `/products/{productId}` — ürün katalogu CRUD'u.
class ProductRepository {
  ProductRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<ProductModel> get ref => _db
      .collection('products')
      .withConverter<ProductModel>(
        fromFirestore: (s, _) => ProductModel.fromMap(s.data()!, s.id),
        toFirestore: (m, _) => m.toMap(),
      );

  Stream<List<ProductModel>> getProducts() {
    return ref
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  Future<DocumentReference<ProductModel>> addProduct(ProductModel product) =>
      ref.add(product);

  Future<void> updateProduct(ProductModel product) async {
    await ref.doc(product.id).update(product.toMap());
  }

  Future<void> deleteProduct(String productId) async {
    await ref.doc(productId).delete();
  }
}
