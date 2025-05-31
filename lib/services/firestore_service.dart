import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile_model.dart';
import '../models/product_model.dart'; // ProductModel'i import et

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- User Profiles ---
  CollectionReference<UserProfileModel> get userProfilesRef => _db.collection('userProfiles').withConverter<UserProfileModel>(
        fromFirestore: (snapshot, _) => UserProfileModel.fromMap(snapshot.data()!, snapshot.id),
        toFirestore: (profile, _) => profile.toMap(),
      );

  Future<void> setUserProfile(UserProfileModel userProfile) async { /* ... mevcut kod ... */ }
  Future<UserProfileModel?> getUserProfile(String userId) async { /* ... mevcut kod ... */ }

  // --- Products ---
  // Ürünler için Koleksiyon Referansı
  CollectionReference<ProductModel> get productsRef => _db.collection('products').withConverter<ProductModel>(
        fromFirestore: (snapshot, _) => ProductModel.fromMap(snapshot.data()!, snapshot.id),
        toFirestore: (product, _) => product.toMap(),
      );

  // Tüm ürünleri getiren bir Stream (Gerçek zamanlı güncellemeler için)
  Stream<List<ProductModel>> getProducts() {
    return productsRef.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    }).handleError((error) {
       print("Ürünleri getirirken hata oluştu: $error");
       return []; // Hata durumunda boş liste döndür
    });
  }

  // Tek seferlik ürünleri getiren Future (İsterseniz Stream yerine bunu kullanabilirsiniz)
  Future<List<ProductModel>> getProductsOnce() async {
    try {
        final snapshot = await productsRef.orderBy('name').get();
        return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print("Ürünleri (tek seferlik) getirirken hata oluştu: $e");
      return [];
    }
  }

  // TODO: Siparişler, Müşteriler için metotlar eklenecek
}