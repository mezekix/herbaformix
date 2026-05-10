# Uygulama Planı: Müşteri Profil Ayarları

## Genel Bakış

Bu plan, HerbaFormix Flutter uygulamasına müşteri profil yönetimi ve davet kodu sistemini eklemek için gereken kodlama görevlerini kapsar. Görevler; veri modeli genişletmesinden başlayarak servis katmanı, state yönetimi, UI bileşenleri ve Firestore güvenlik kurallarına kadar sıralı ve bağımlılıkları net biçimde tanımlanmıştır.

## Görevler

- [x] 1. Veri Modelleri ve Temel Altyapı
  - [x] 1.1 `UserProfileModel`'i yeni alanlarla genişlet
    - `lib/models/user_profile_model.dart` dosyasına `birthDate`, `gender`, `healthNotes`, `allergies`, `medications`, `assignedDistributorId`, `profilePhotoUrl` alanlarını ekle
    - `toMap()` metodunu güncelle: `null` olan opsiyonel alanları map'e dahil etme (`if (field != null)` pattern'i)
    - `fromMap()` factory constructor'ını güncelle: `birthDate` için `int` → `DateTime` dönüşümü; beklenmedik tür gelirse `null` ata
    - `birthDate` için `millisecondsSinceEpoch` ↔ `DateTime` dönüşümünü uygula
    - _Gereksinimler: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7_

  - [ ]* 1.2 `UserProfileModel` serializasyon round-trip property testi yaz
    - **Özellik 1: UserProfileModel Serializasyon Round-Trip**
    - `test/models/user_profile_model_pbt_test.dart` dosyasını oluştur
    - `glados` paketi ile rastgele `UserProfileModel` örnekleri üret (tüm alan kombinasyonları)
    - `toMap()` → `fromMap()` zinciri sonucunda orijinal modelle eşdeğerliği doğrula (min 100 iterasyon)
    - **Doğrular: Gereksinim 1.2, 1.3, 1.4, 1.5**

  - [ ]* 1.3 `toMap()` null alanları dışlar property testi yaz
    - **Özellik 2: toMap() Null Alanları Dışlar**
    - `test/models/user_profile_model_pbt_test.dart` dosyasına ekle
    - Rastgele null/non-null alan kombinasyonlarıyla model üret
    - `toMap()` çıktısında null değerli anahtarların bulunmadığını doğrula
    - **Doğrular: Gereksinim 1.2**

  - [x] 1.4 `InviteCodeModel` sınıfını oluştur
    - `lib/models/invite_code_model.dart` dosyasını oluştur
    - `id`, `code`, `distributorId`, `createdAt`, `isUsed`, `usedByUserId` alanlarını tanımla
    - `fromMap(Map<String, dynamic> map, String id)` factory constructor'ını yaz
    - `toMap()` metodunu yaz
    - _Gereksinimler: 9.2_

  - [ ]* 1.5 `InviteCodeModel` round-trip birim testi yaz
    - `test/models/invite_code_model_test.dart` dosyasını oluştur
    - `fromMap()` / `toMap()` round-trip doğruluğunu test et
    - `isUsed` ve `usedByUserId` alanlarının doğru dönüşümünü test et
    - _Gereksinimler: 9.2_

- [x] 2. Form Validasyon Katmanı
  - [x] 2.1 Profil formu validasyon fonksiyonlarını oluştur
    - `lib/features/profile/utils/profile_validators.dart` dosyasını oluştur
    - `validateName(String? value)`: boş veya yalnızca whitespace içeriyorsa hata döndür
    - `validatePhone(String? value)`: dolu ise E.164 formatını kontrol et (ülke kodu dahil 7–15 rakam)
    - `validateHeight(String? value)`: dolu ise sayısal ve [50, 300] aralığında olduğunu kontrol et
    - `validateWeight(String? value)`: dolu ise sayısal ve [10, 500] aralığında olduğunu kontrol et
    - `validateHealthField(String? value)`: dolu ise 1000 karakter sınırını kontrol et
    - _Gereksinimler: 2.5, 2.6, 3.2, 3.3, 3.4, 3.5, 3.7_

  - [ ]* 2.2 Ad-soyad whitespace validasyonu property testi yaz
    - **Özellik 3: Ad-Soyad Whitespace Validasyonu**
    - `test/features/profile/validation_pbt_test.dart` dosyasını oluştur
    - Rastgele whitespace string'leri üret (` `, `\t`, `\n` kombinasyonları)
    - `validateName()` çağrıldığında `null` olmayan hata mesajı döndüğünü doğrula
    - **Doğrular: Gereksinim 2.5**

  - [ ]* 2.3 Telefon E.164 validasyonu property testi yaz
    - **Özellik 4: Telefon E.164 Format Validasyonu**
    - `test/features/profile/validation_pbt_test.dart` dosyasına ekle
    - E.164 formatına uymayan string'ler üret (6 rakamdan az, 16 rakamdan fazla, harf içeren vb.)
    - `validatePhone()` çağrıldığında hata döndüğünü doğrula
    - **Doğrular: Gereksinim 2.6**

  - [ ]* 2.4 Boy aralık validasyonu property testi yaz
    - **Özellik 5: Boy Aralık Validasyonu**
    - `test/features/profile/validation_pbt_test.dart` dosyasına ekle
    - 50'den küçük ve 300'den büyük rastgele double değerler üret
    - `validateHeight()` çağrıldığında hata döndüğünü; [50, 300] aralığındaki değerler için `null` döndüğünü doğrula
    - **Doğrular: Gereksinim 3.2, 3.5**

  - [ ]* 2.5 Kilo aralık validasyonu property testi yaz
    - **Özellik 6: Kilo Aralık Validasyonu**
    - `test/features/profile/validation_pbt_test.dart` dosyasına ekle
    - 10'dan küçük ve 500'den büyük rastgele double değerler üret
    - `validateWeight()` çağrıldığında hata döndüğünü; [10, 500] aralığındaki değerler için `null` döndüğünü doğrula (hem mevcut kilo hem hedef kilo için)
    - **Doğrular: Gereksinim 3.3, 3.5**

  - [ ]* 2.6 Sağlık alanları karakter sınırı property testi yaz
    - **Özellik 7: Sağlık Alanları Karakter Sınırı Validasyonu**
    - `test/features/profile/validation_pbt_test.dart` dosyasına ekle
    - 1001+ karakter uzunluğunda rastgele string'ler üret
    - `validateHealthField()` çağrıldığında hata döndüğünü; ≤1000 karakter için `null` döndüğünü doğrula
    - **Doğrular: Gereksinim 3.7**

- [x] 3. Kontrol Noktası — Temel katman testleri
  - Tüm model ve validasyon testlerinin geçtiğini doğrula. Soru varsa kullanıcıya sor.

- [x] 4. Servis Katmanı Genişletmesi
  - [x] 4.1 `FirestoreService`'e davet kodu metodlarını ekle
    - `lib/services/firestore_service.dart` dosyasına ekle
    - `_generateCode()`: 8 karakterlik büyük harf+rakam kodu üretir
    - `createInviteCode(String distributorId)`: benzersizlik kontrolü yaparak `inviteCodes` koleksiyonuna yazar (max 5 deneme)
    - `validateInviteCode(String code)`: `inviteCodes` koleksiyonunda kodu arar, `InviteCodeModel?` döner
    - `signUpWithInviteCodeBatch({required UserProfileModel, required String inviteCodeId, required String newUserId})`: `WriteBatch` ile atomik yazma
    - `getDistributorProfile(String distributorId)`: `userProfiles/{distributorId}` dokümanını okur
    - `getCustomersByDistributorId(String distributorId)`: `assignedDistributorId == distributorId` olan profilleri stream olarak döner
    - _Gereksinimler: 5.4, 9.2, 9.3, 9.6, 10.2, 10.4, 10.8_

  - [ ]* 4.2 Davet kodu format garantisi property testi yaz
    - **Özellik 8: Davet Kodu Format Garantisi**
    - `test/services/invite_code_pbt_test.dart` dosyasını oluştur
    - `_generateCode()` fonksiyonunu 100+ kez çağır (test edilebilir hale getirmek için `@visibleForTesting` ile expose et)
    - Her seferinde uzunluk == 8 ve `RegExp(r'^[A-Z0-9]{8}$').hasMatch(code)` doğrula
    - **Doğrular: Gereksinim 9.2**

  - [ ]* 4.3 `FirestoreService` davet kodu birim testleri yaz
    - `test/services/firestore_service_invite_test.dart` dosyasını oluştur
    - `validateInviteCode` için geçerli/geçersiz/kullanılmış kod senaryolarını mock ile test et
    - _Gereksinimler: 10.2, 10.5, 10.6_

  - [x] 4.4 `AuthProvider`'a yeni metodları ekle
    - `lib/features/auth/providers/auth_provider.dart` dosyasına ekle
    - `changePassword({required String currentPassword, required String newPassword})`: `reauthenticateWithCredential` → `updatePassword` akışı; `FirebaseAuthException.code` değerine göre anlamlı hata fırlat
    - `uploadProfilePhoto(File imageFile)`: `users/{uid}/profile.jpg` yoluna yükle, URL döndür; hata durumunda `null` döndür
    - `signUpWithInviteCode({required String email, required String password, required UserRole role, String? inviteCode})`: davet kodu varsa doğrula, `signUpWithInviteCodeBatch` ile atomik kayıt yap
    - _Gereksinimler: 4.4, 7.5, 7.7, 7.8, 10.2, 10.3, 10.7, 10.8_

- [x] 5. Müşteri Listesi Birleştirme
  - [x] 5.1 `CustomerProvider`'a birleşik müşteri listesi metodunu ekle
    - `lib/features/customers/providers/customer_provider.dart` dosyasına ekle
    - `getCombinedCustomers()`: `users/{uid}/customers` alt koleksiyonu + `userProfiles` (assignedDistributorId eşleşmesi) listelerini birleştir
    - `userProfiles` kaynağını önceliklendir; aynı UID'yi yalnızca bir kez göster (deduplicate by UID)
    - `CombinedCustomerEntry` modelini tanımla: müşteri adı, telefon, bağlanma yöntemi (davet kodu / manuel)
    - _Gereksinimler: 11.1, 11.2, 11.4_

  - [ ]* 5.2 Müşteri listesi deduplicate property testi yaz
    - **Özellik 9: Müşteri Listesi Deduplicate**
    - `test/features/customers/customer_provider_pbt_test.dart` dosyasını oluştur
    - Rastgele iki müşteri listesi üret (bazı ortak UID'lerle)
    - `mergeAndDeduplicate()` çağrıldığında sonuçtaki UID'lerin unique olduğunu doğrula
    - `userProfiles` kaynağının önceliklendirildiğini doğrula
    - **Doğrular: Gereksinim 11.1, 11.4**

- [x] 6. Kontrol Noktası — Servis katmanı testleri
  - Tüm servis ve provider testlerinin geçtiğini doğrula. Soru varsa kullanıcıya sor.

- [x] 7. Profil Fotoğrafı ve Temel UI Bileşenleri
  - [x] 7.1 `ProfilePhotoWidget` bileşenini oluştur
    - `lib/features/profile/widgets/profile_photo_widget.dart` dosyasını oluştur
    - `photoUrl`, `localFile`, `isUploading`, `onTap` parametrelerini al
    - `photoUrl` doluysa `CachedNetworkImage` (veya `Image.network`) ile dairesel avatar göster; yüklenemezse placeholder göster
    - `localFile` varsa önizleme olarak göster
    - `isUploading: true` iken avatar üzerinde `CircularProgressIndicator` göster
    - Dokunulduğunda `BottomSheet` aç: "Kameradan Çek" / "Galeriden Seç" seçenekleri
    - `image_picker` ile fotoğraf seç; JPEG/PNG/HEIC ve max 10 MB kontrolü yap
    - _Gereksinimler: 4.1, 4.2, 4.3, 4.5, 4.7, 4.8_

  - [x] 7.2 `DistributorInfoCard` bileşenini oluştur
    - `lib/features/profile/widgets/distributor_info_card.dart` dosyasını oluştur
    - `assignedDistributorId` doluysa `FirestoreService.getDistributorProfile()` ile distribütör adı ve telefonunu yükle
    - Distribütör bilgilerini salt okunur kart içinde göster
    - `assignedDistributorId` boşsa "Henüz bir distribütöre bağlı değilsiniz." mesajı göster
    - Yükleme hatası durumunda "Distribütör bilgisi yüklenemedi." mesajı göster
    - _Gereksinimler: 5.1, 5.2, 5.3, 5.4, 5.5_

  - [x] 7.3 `ChangePasswordDialog` bileşenini oluştur
    - `lib/features/profile/widgets/change_password_dialog.dart` dosyasını oluştur
    - Mevcut şifre, yeni şifre, yeni şifre tekrarı alanlarını içer (şifre görünürlük toggle'ı ile)
    - Yeni şifre ≥ 6 karakter validasyonu; şifre uyuşmazlığı validasyonu
    - Onaylandığında `AuthProvider.changePassword()` çağır
    - Başarıda SnackBar göster ve diyalogu kapat
    - `wrong-password`, `requires-recent-login`, ağ hatası durumlarında ilgili alanda hata mesajı göster; diyalogu açık tut
    - _Gereksinimler: 7.2, 7.3, 7.4, 7.5, 7.6, 7.7, 7.8, 7.9_

  - [x] 7.4 `InviteCodeSection` bileşenini oluştur
    - `lib/features/profile/widgets/invite_code_section.dart` dosyasını oluştur
    - "Davet Kodu Oluştur" butonu: `FirestoreService.createInviteCode()` çağırır
    - Oluşturulan kodu büyük ve okunabilir biçimde göster; tek dokunuşla panoya kopyalama
    - Distribütörün kullanılmamış (`isUsed: false`) davet kodlarını oluşturulma tarihine göre sıralı listele
    - Hata durumunda SnackBar ile bildirim göster
    - _Gereksinimler: 9.1, 9.2, 9.4, 9.5, 9.6_

- [x] 8. Müşteri Profil Formu
  - [x] 8.1 `CustomerProfileView` bileşenini oluştur — Kişisel Bilgiler bölümü
    - `lib/features/profile/widgets/customer_profile_view.dart` dosyasını oluştur
    - `GlobalKey<FormState>` ile form yönetimi
    - `ProfilePhotoWidget` entegrasyonu (üstte)
    - Ad-soyad (zorunlu), e-posta (salt okunur `TextFormField`), telefon (E.164 validasyonu) alanları
    - Doğum tarihi: `showDatePicker` ile 1900-01-01 ile kayıt tarihinden bir gün öncesi arasında seçim
    - Cinsiyet: "Kadın", "Erkek", "Belirtmek İstemiyorum" seçenekli `DropdownButtonFormField`
    - Mevcut `AuthProvider.userProfile` değerleriyle alanları önceden doldur
    - _Gereksinimler: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

  - [x] 8.2 `CustomerProfileView`'a Sağlık Bilgileri bölümünü ekle
    - `lib/features/profile/widgets/customer_profile_view.dart` dosyasına ekle
    - Boy (cm), mevcut kilo (kg), hedef kilo (kg) alanları: ondalıklı sayı klavyesi, aralık validasyonu
    - Sağlık notları, alerjiler, ilaçlar: `maxLines: 3`, `maxLength: 1000`, karakter sayacı
    - Tüm sağlık alanları opsiyonel; boş bırakılabilir
    - _Gereksinimler: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7_

  - [x] 8.3 `CustomerProfileView`'a Distribütör Bilgisi ve Eylem butonlarını ekle
    - `lib/features/profile/widgets/customer_profile_view.dart` dosyasına ekle
    - `DistributorInfoCard` entegrasyonu
    - "Kaydet" butonu: form validasyonu → fotoğraf yükleme (varsa) → `AuthProvider.updateUserProfile()` akışı
    - Kaydetme sırasında buton devre dışı + `CircularProgressIndicator`
    - Başarıda SnackBar; hata durumunda hata SnackBar, form değerlerini koru
    - "Şifre Değiştir" butonu: `ChangePasswordDialog` açar
    - "Çıkış Yap" butonu: onay diyalogu → `AuthProvider.signOut()` → giriş ekranına yönlendir
    - _Gereksinimler: 4.4, 4.5, 4.6, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 7.1, 8.1, 8.2, 8.3, 8.4, 8.5_

- [x] 9. Distribütör Profil Görünümü ve Ekran Refactor
  - [x] 9.1 `DistributorProfileView` bileşenini oluştur
    - `lib/features/profile/widgets/distributor_profile_view.dart` dosyasını oluştur
    - Mevcut distribütör profil alanlarını (ad-soyad, distribütör seviyesi, VP hedefi) taşı
    - `InviteCodeSection` entegrasyonu
    - "Çıkış Yap" butonu: onay diyalogu → `AuthProvider.signOut()` → giriş ekranına yönlendir
    - _Gereksinimler: 8.1, 8.2, 8.3, 8.4, 8.5, 9.1_

  - [x] 9.2 `ProfileScreen`'i rol bazlı koşullu render ile refactor et
    - `lib/features/profile/screens/profile_screen.dart` dosyasını güncelle
    - `AuthProvider.userProfile?.role` değerine göre `CustomerProfileView` veya `DistributorProfileView` render et
    - Mevcut distribütör mantığını `DistributorProfileView`'a taşı; `ProfileScreen`'i ince bir wrapper'a dönüştür
    - _Gereksinimler: 2.1, 9.1_

- [x] 10. Kayıt Ekranına Davet Kodu Entegrasyonu
  - [x] 10.1 `LoginScreen`'e davet kodu alanını ekle
    - `lib/features/auth/screens/login_screen.dart` dosyasını güncelle
    - Kayıt modunda müşteri rolü seçildiğinde opsiyonel "Davet Kodu" `TextFormField` göster
    - Kayıt formunu `AuthProvider.signUpWithInviteCode()` metodunu kullanacak şekilde güncelle
    - Geçersiz kod (`null` dönüş) durumunda davet kodu alanı altında hata mesajı göster
    - Kullanılmış kod durumunda "Bu davet kodu daha önce kullanılmış." hata mesajı göster
    - Davet kodu boş bırakıldığında normal kayıt akışını sürdür
    - _Gereksinimler: 10.1, 10.2, 10.3, 10.5, 10.6, 10.7_

- [x] 11. Distribütör Müşteri Listesi Güncelleme
  - [x] 11.1 `CustomerListScreen`'i birleşik müşteri listesiyle güncelle
    - `lib/features/customers/screens/customer_list_screen.dart` dosyasını güncelle
    - `CustomerProvider.getCombinedCustomers()` metodunu kullan
    - Her müşteri kartında ad, telefon ve bağlanma yöntemi (davet kodu / manuel) göster
    - _Gereksinimler: 11.1, 11.2_

  - [x] 11.2 `CustomerDetailScreen`'i genişletilmiş profil alanlarıyla güncelle
    - `lib/features/customers/screens/customer_detail_screen.dart` dosyasını güncelle
    - Sağlık notları, alerjiler, ilaçlar, boy, kilo, hedef kilo alanlarını salt okunur biçimde göster
    - _Gereksinimler: 11.3_

- [x] 12. Firestore Güvenlik Kuralları
  - [x] 12.1 Firestore güvenlik kurallarını güncelle
    - `firestore.rules` dosyasını güncelle
    - `userProfiles/{userId}`: kullanıcı yalnızca kendi dokümanını okuyup yazabilir
    - `userProfiles/{userId}`: distribütör, `assignedDistributorId` kendi UID'siyle eşleşen dokümanları okuyabilir
    - `userProfiles/{userId}`: `assignedDistributorId` alanı istemci tarafından doğrudan güncellenemez
    - `inviteCodes`: yalnızca kimliği doğrulanmış kullanıcılar okuyabilir
    - `inviteCodes`: yalnızca distribütör rolündeki kullanıcılar yeni doküman oluşturabilir
    - `inviteCodes/{codeId}`: `isUsed` ve `usedByUserId` alanları yalnızca batch işlemi sırasında güncellenebilir
    - _Gereksinimler: 12.1, 12.2, 12.3, 12.4, 12.5, 12.6_

- [x] 13. Bağımlılık Kurulumu
  - [x] 13.1 Gerekli paketleri `pubspec.yaml`'a ekle
    - `image_picker: ^1.1.2` ekle
    - `firebase_storage: ^12.3.7` ekle
    - `dev_dependencies` altına `glados: ^0.5.0` ekle
    - `flutter pub get` çalıştır
    - _Gereksinimler: 4.2, 4.3_

- [x] 14. Son Kontrol Noktası — Tüm testler
  - Tüm birim, property-based ve entegrasyon testlerinin geçtiğini doğrula. Soru varsa kullanıcıya sor.

## Notlar

- `*` ile işaretli görevler opsiyoneldir; hızlı MVP için atlanabilir
- Her görev belirli gereksinimlere referans verir (izlenebilirlik için)
- Kontrol noktaları artımlı doğrulama sağlar
- Property testleri evrensel doğruluk özelliklerini; birim testleri belirli örnekleri ve sınır durumlarını doğrular
- `glados` paketi Dart ekosisteminde property-based testing için kullanılır (min 100 iterasyon)
- Fotoğraf yükleme hatası profil kaydını iptal etmez (bağımsız hata yönetimi)
- Davet kodu batch write atomikliği Firestore tarafından garanti edilir

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.4", "13.1"] },
    { "id": 1, "tasks": ["1.2", "1.3", "1.5", "2.1", "4.1"] },
    { "id": 2, "tasks": ["2.2", "2.3", "2.4", "2.5", "2.6", "4.2", "4.3", "4.4"] },
    { "id": 3, "tasks": ["5.1", "7.1", "7.2", "7.3", "7.4"] },
    { "id": 4, "tasks": ["5.2", "8.1"] },
    { "id": 5, "tasks": ["8.2", "9.1"] },
    { "id": 6, "tasks": ["8.3", "9.2", "10.1"] },
    { "id": 7, "tasks": ["11.1", "11.2", "12.1"] }
  ]
}
```
