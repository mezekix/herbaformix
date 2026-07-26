import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/customer_product_price_model.dart';

class CustomerProductPriceRepository {
  CustomerProductPriceRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<CustomerProductPriceModel> ref(String distributorId) =>
      _db
          .collection('users')
          .doc(distributorId)
          .collection('customerProductPrices')
          .withConverter(
            fromFirestore: (snapshot, _) => CustomerProductPriceModel.fromMap(
              snapshot.data()!,
              snapshot.id,
            ),
            toFirestore: (model, _) => model.toMap(),
          );

  Future<void> save(String distributorId, CustomerProductPriceModel price) =>
      ref(distributorId).doc(price.id).set(price);

  Future<CustomerProductPriceModel?> get(
    String distributorId,
    String customerId,
    String productId,
  ) async {
    final snapshot = await ref(
      distributorId,
    ).doc('${customerId}_$productId').get();
    return snapshot.data();
  }
}
