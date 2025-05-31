// Bu servis, Firestore veritabanı ile etkileşimleri yönetir.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile_model.dart'; // Oluşturduğumuz UserProfileModel

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Kullanıcı Profili için Koleksiyon Referansı

  CollectionReference<UserProfileModel> get userProfilesRef => _db.collection('userProfiles').withConverter<UserProfileModel>(
        fromFirestore: (snapshot, _) => UserProfileModel.fromMap(snapshot.data()!, snapshot.id),
        toFirestore: (profile, _) => profile.toMap(),
      );


  // Yeni kullanıcı için profil oluşturma veya mevcut profili güncelleme
  Future<void> setUserProfile(UserProfileModel userProfile) async {
    try {
      // Doküman ID'si olarak kullanıcının UID'sini kullanıyoruz.
      await userProfilesRef.doc(userProfile.id).set(userProfile, SetOptions(merge: true));
      print('Kullanıcı profili başarıyla kaydedildi/güncellendi: ${userProfile.id}');
    } catch (e) {
      print('setUserProfile Hata: $e');
      // Hata yönetimi UI'da yapılmalı
      throw Exception("Profil kaydedilemedi: $e");
    }
  }

  // Kullanıcı profilini getirme
  Future<UserProfileModel?> getUserProfile(String userId) async {
    try {
      final docSnapshot = await userProfilesRef.doc(userId).get();
      if (docSnapshot.exists) {
        print('Kullanıcı profili bulundu: $userId');
        return docSnapshot.data();
      } else {
        print('Kullanıcı profili bulunamadı: $userId');
        return null; // Profil yoksa null döner
      }
    } catch (e) {
      print('getUserProfile Hata: $e');
      throw Exception("Profil getirilemedi: $e");
    }
  }

  // TODO: MVP sonrası için ürünler, siparişler, müşteriler için metotlar eklenecek
  // Future<void> addProduct(...) async {}
  // Stream<List<ProductModel>> getProducts() async* {}
}