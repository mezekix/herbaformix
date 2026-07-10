import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/product_model.dart';

/// `/products/{productId}` — ürün katalogu CRUD'u.
class ProductRepository {
  ProductRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  static const customerVisibleCategories = ['İç Beslenme', 'Dış Beslenme'];

  final FirebaseFirestore _db;

  CollectionReference<ProductModel> get ref => _db
      .collection('products')
      .withConverter<ProductModel>(
        fromFirestore: (s, _) => ProductModel.fromMap(s.data()!, s.id),
        toFirestore: (m, _) => m.toMap(),
      );

  Stream<List<ProductModel>> getProducts({bool customerVisibleOnly = false}) {
    final Query<ProductModel> query = customerVisibleOnly
        ? ref.where('category', whereIn: customerVisibleCategories)
        : ref.orderBy('name');

    return query.snapshots().map((s) {
      final products = s.docs.map((d) => d.data()).toList();
      if (customerVisibleOnly) {
        products.sort((a, b) => a.name.compareTo(b.name));
      }
      return products;
    });
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
