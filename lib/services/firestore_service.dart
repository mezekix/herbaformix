import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile_model.dart';
import '../models/product_model.dart';
import '../models/customer_model.dart';
import '../models/order_model.dart'; // OrderModel'i import et

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ... (UserProfile, Product, Customer servis metotları aynı kalacak) ...
  CollectionReference<UserProfileModel> get userProfilesRef => _db.collection('userProfiles').withConverter<UserProfileModel>(fromFirestore: (s,o) => UserProfileModel.fromMap(s.data()!, s.id), toFirestore: (m,o)=>m.toMap());
  Future<void> setUserProfile(UserProfileModel userProfile) async { await userProfilesRef.doc(userProfile.id).set(userProfile, SetOptions(merge: true)); }
  Future<UserProfileModel?> getUserProfile(String userId) async { final d = await userProfilesRef.doc(userId).get(); return d.exists ? d.data() : null; }
  CollectionReference<ProductModel> get productsRef => _db.collection('products').withConverter<ProductModel>(fromFirestore: (s,o) => ProductModel.fromMap(s.data()!, s.id), toFirestore: (m,o)=>m.toMap());
  Stream<List<ProductModel>> getProducts() { return productsRef.orderBy('name').snapshots().map((s) => s.docs.map((d) => d.data()).toList()); }
  CollectionReference<CustomerModel> customersRef(String userId) => _db.collection('users').doc(userId).collection('customers').withConverter<CustomerModel>(fromFirestore: (s,o) => CustomerModel.fromMap(s.data()!, s.id), toFirestore: (m,o)=>m.toMap());
  Future<DocumentReference<CustomerModel>> addCustomer(String userId, CustomerModel customer) async { return await customersRef(userId).add(customer); }
  Stream<List<CustomerModel>> getCustomers(String userId) { return customersRef(userId).orderBy('name').snapshots().map((s) => s.docs.map((d) => d.data()).toList()); }
  Future<void> updateCustomer(String userId, CustomerModel customer) async { await customersRef(userId).doc(customer.id).update(customer.toMap()); }
  Future<void> deleteCustomer(String userId, String customerId) async { await customersRef(userId).doc(customerId).delete(); }


  // --- Orders ---
  // Belirli bir kullanıcıya ait siparişler için Koleksiyon Referansı
  // users/{userId}/orders/{orderId}
  CollectionReference<OrderModel> ordersRef(String userId) =>
      _db.collection('users').doc(userId).collection('orders').withConverter<OrderModel>(
            fromFirestore: (snapshot, _) => OrderModel.fromMap(snapshot.data()!, snapshot.id),
            toFirestore: (order, _) => order.toMap(),
          );

  // Yeni sipariş ekleme
  Future<DocumentReference<OrderModel>> addOrder(String userId, OrderModel order) async {
    try {
      // userId'nin order modelinde doğru olduğundan emin olalım.
      final orderToAdd = OrderModel(
        id: '', // Firestore ID atayacak
        userId: userId,
        customerId: order.customerId,
        customerName: order.customerName,
        items: order.items,
        orderDate: order.orderDate, // Veya Timestamp.now()
        status: order.status,
        totalAmount: order.items.fold(0, (sum, item) => sum + item.totalPrice),
        totalVpEarned: order.items.fold(0, (sum, item) => sum + item.totalVp),
        notes: order.notes,
        shippingAddress: order.shippingAddress,
      );
      return await ordersRef(userId).add(orderToAdd);
    } catch (e) {
      print("Sipariş eklerken hata: $e");
      throw Exception("Sipariş eklenemedi: $e");
    }
  }

  // Kullanıcının tüm siparişlerini getiren bir Stream
  Stream<List<OrderModel>> getOrders(String userId) {
    return ordersRef(userId).orderBy('orderDate', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    }).handleError((error) {
      print("Siparişleri getirirken hata oluştu (kullanıcı: $userId): $error");
      return [];
    });
  }

  // Sipariş güncelleme (özellikle status güncellemesi için)
  Future<void> updateOrder(String userId, OrderModel order) async {
    try {
      await ordersRef(userId).doc(order.id).update(order.toMap());
    } catch (e) {
      print("Sipariş güncellerken hata: $e");
      throw Exception("Sipariş güncellenemedi: $e");
    }
  }

  // Sipariş silme (genellikle önerilmez, status 'cancelled' yapılabilir)
  Future<void> deleteOrder(String userId, String orderId) async {
    try {
      await ordersRef(userId).doc(orderId).delete();
    } catch (e) {
      print("Sipariş silerken hata: $e");
      throw Exception("Sipariş silinemedi: $e");
    }
  }
}