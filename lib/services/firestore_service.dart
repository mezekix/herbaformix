import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/customer_model.dart';
import '../models/follow_up_model.dart'; // Yeni oluşturduğumuz takip modelini buraya ekliyoruz.
import '../models/order_model.dart'; // OrderModel'i import et
import '../models/product_model.dart';
import '../models/scheduled_follow_up_model.dart'; // Yeni modelimizi import ediyoruz.
import '../models/user_profile_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ... (UserProfile, Product, Customer servis metotları aynı kalacak) ...
  CollectionReference<UserProfileModel> get userProfilesRef => _db
      .collection('userProfiles')
      .withConverter<UserProfileModel>(
        fromFirestore: (s, o) => UserProfileModel.fromMap(s.data()!, s.id),
        toFirestore: (m, o) => m.toMap(),
      );
  Future<void> setUserProfile(UserProfileModel userProfile) async {
    await userProfilesRef
        .doc(userProfile.id)
        .set(userProfile, SetOptions(merge: true));
  }

  Future<UserProfileModel?> getUserProfile(String userId) async {
    final d = await userProfilesRef.doc(userId).get();
    return d.exists ? d.data() : null;
  }

  CollectionReference<ProductModel> get productsRef => _db
      .collection('products')
      .withConverter<ProductModel>(
        fromFirestore: (s, o) => ProductModel.fromMap(s.data()!, s.id),
        toFirestore: (m, o) => m.toMap(),
      );
  Stream<List<ProductModel>> getProducts() {
    return productsRef
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  CollectionReference<CustomerModel> customersRef(String userId) => _db
      .collection('users')
      .doc(userId)
      .collection('customers')
      .withConverter<CustomerModel>(
        fromFirestore: (s, o) => CustomerModel.fromMap(s.data()!, s.id),
        toFirestore: (m, o) => m.toMap(),
      );
  Future<DocumentReference<CustomerModel>> addCustomer(
    String userId,
    CustomerModel customer,
  ) async {
    return await customersRef(userId).add(customer);
  }

  Stream<List<CustomerModel>> getCustomers(String userId) {
    return customersRef(userId)
        .orderBy('firstName')
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  /// Veritabanından belirli bir ID'ye sahip tek bir müşteriyi getirir.
  Future<CustomerModel?> getCustomer(String userId, String customerId) async {
    try {
      final docSnapshot = await customersRef(userId).doc(customerId).get();
      if (docSnapshot.exists) {
        return docSnapshot.data();
      }
      return null;
    } catch (e) {
      print("FirestoreService Hata (getCustomer): $e");
      rethrow;
    }
  }

  Future<void> updateCustomer(String userId, CustomerModel customer) async {
    await customersRef(userId).doc(customer.id).update(customer.toMap());
  }

  Future<void> deleteCustomer(String userId, String customerId) async {
    await customersRef(userId).doc(customerId).delete();
  }

  // --- Follow Ups (Takip Görüşmeleri) ---

  /// Belirli bir müşteriye ait takip görüşmeleri için Koleksiyon Referansı oluşturur.
  /// Firestore'daki veritabanı yolunu (path) tanımlar:
  /// users/{danışmanId}/customers/{müşteriId}/follow_ups/{takipId}
  CollectionReference<FollowUpModel> followUpsRef(
    String userId,
    String customerId,
  ) => _db
      .collection('users')
      .doc(userId)
      .collection('customers')
      .doc(customerId)
      .collection('follow_ups')
      .withConverter<FollowUpModel>(
        fromFirestore: (snapshot, _) =>
            FollowUpModel.fromMap(snapshot.data()!, snapshot.id),
        toFirestore: (followUp, _) => followUp.toMap(),
      );

  /// Belirli bir müşterinin tüm takip görüşmelerini getiren bir Stream (anlık veri akışı) döndürür.
  /// Görüşmeler, tarihe göre en yeniden eskiye doğru sıralanır.
  Stream<List<FollowUpModel>> getFollowUps(String userId, String customerId) {
    return followUpsRef(userId, customerId)
        .orderBy('date', descending: true)
        .snapshots() // Veritabanındaki her değişikliği anlık olarak dinler.
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList())
        .handleError((error) {
          print(
            "Takip görüşmeleri getirilirken hata oluştu (müşteri: $customerId): $error",
          );
          return []; // Hata durumunda boş bir liste döndürür.
        });
  }

  /// Veritabanına yeni bir takip görüşmesi ekler.
  Future<void> addFollowUp(
    String userId,
    String customerId,
    FollowUpModel followUp,
  ) async {
    try {
      // Modeli direkt olarak referansa ekliyoruz. ID'yi Firestore otomatik oluşturacak.
      await followUpsRef(userId, customerId).add(followUp);
    } catch (e) {
      print("Takip görüşmesi eklerken hata: $e");
      // Hata olursa, bunu çağıran kodun haberi olması için hatayı tekrar fırlatıyoruz.
      throw Exception("Takip görüşmesi eklenemedi: $e");
    }
  }

  /// Mevcut bir takip görüşmesini günceller.
  Future<void> updateFollowUp(
    String userId,
    String customerId,
    FollowUpModel followUp,
  ) async {
    try {
      await followUpsRef(
        userId,
        customerId,
      ).doc(followUp.id).update(followUp.toMap());
    } catch (e) {
      print("Takip görüşmesi güncellenirken hata: $e");
      throw Exception("Takip görüşmesi güncellenemedi: $e");
    }
  }

  /// Bir takip görüşmesini ID'sini kullanarak siler.
  Future<void> deleteFollowUp(
    String userId,
    String customerId,
    String followUpId,
  ) async {
    try {
      await followUpsRef(userId, customerId).doc(followUpId).delete();
    } catch (e) {
      print("Takip görüşmesi silerken hata: $e");
      throw Exception("Takip görüşmesi silinemedi: $e");
    }
  }

  // --- Scheduled Follow Ups (Planlanmış Takipler) ---

  /// `scheduled_follow_ups` ana koleksiyonu için bir referans oluşturur.
  CollectionReference<ScheduledFollowUpModel> scheduledFollowUpsRef() => _db
      .collection('scheduled_follow_ups')
      .withConverter<ScheduledFollowUpModel>(
        fromFirestore: (snapshot, _) =>
            ScheduledFollowUpModel.fromMap(snapshot.data()!, snapshot.id),
        toFirestore: (scheduled, _) => scheduled.toMap(),
      );

  /// Belirli bir danışmana ait, tamamlanmamış ve tarihi yaklaşan görevleri getirir.
  /// Bu, ana sayfadaki "Ajanda" bölümü için kullanılacak.
  Stream<List<ScheduledFollowUpModel>> getUpcomingFollowUpsForConsultant(
    String consultantId,
    DateTime inTheNext,
  ) {
    return scheduledFollowUpsRef()
        .where('consultantId', isEqualTo: consultantId)
        .where('isCompleted', isEqualTo: false)
        .where('dueDate', isLessThanOrEqualTo: Timestamp.fromDate(inTheNext))
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Belirli bir müşteriye ait tüm planlanmış görevleri getirir.
  /// Bu, müşteri detay sayfasındaki "Takip Planı" bölümü için kullanılacak.
  Stream<List<ScheduledFollowUpModel>> getScheduledFollowUpsForCustomer(
    String userId,
    String customerId,
  ) {
    return scheduledFollowUpsRef()
        .where('customerId', isEqualTo: customerId)
        .where('consultantId', isEqualTo: userId)
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Veritabanına bir dizi (batch) planlanmış takip görevi ekler.
  /// Bir sipariş teslim edildiğinde, tüm görevleri (1., 3., 7. gün vb.)
  /// tek bir işlemde, atomik olarak eklemek için bu metodu kullanacağız.
  Future<void> addScheduledFollowUpBatch(
    List<ScheduledFollowUpModel> followUps,
  ) async {
    try {
      final batch = _db.batch();

      for (final followUp in followUps) {
        final docRef = scheduledFollowUpsRef()
            .doc(); // Yeni bir doküman referansı oluştur.
        batch.set(docRef, followUp); // Bu referansa modeli ekle.
      }

      await batch.commit(); // Tüm işlemleri tek seferde veritabanına gönder.
    } catch (e) {
      print("Planlanmış takip grubu eklenirken hata: $e");
      throw Exception("Planlanmış takipler oluşturulamadı: $e");
    }
  }

  /// Belirli bir planlanmış takip görevini tamamlandı olarak işaretler.
  Future<void> markScheduledFollowUpAsCompleted(
    String scheduledFollowUpId,
  ) async {
    try {
      await scheduledFollowUpsRef().doc(scheduledFollowUpId).update({
        'isCompleted': true,
      });
    } catch (e) {
      print("Planlanmış takip tamamlandı olarak işaretlenirken hata: $e");
      throw Exception("Görev güncellenemedi: $e");
    }
  }

  // --- Orders ---
  // Belirli bir kullanıcıya ait siparişler için Koleksiyon Referansı
  // users/{userId}/orders/{orderId}
  CollectionReference<OrderModel> ordersRef(String userId) => _db
      .collection('users')
      .doc(userId)
      .collection('orders')
      .withConverter<OrderModel>(
        fromFirestore: (snapshot, _) =>
            OrderModel.fromMap(snapshot.data()!, snapshot.id),
        toFirestore: (order, _) => order.toMap(),
      );

  // Yeni sipariş ekleme
  Future<DocumentReference<OrderModel>> addOrder(
    String userId,
    OrderModel order,
  ) async {
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
    return ordersRef(userId)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => doc.data()).toList();
        })
        .handleError((error) {
          print(
            "Siparişleri getirirken hata oluştu (kullanıcı: $userId): $error",
          );
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
