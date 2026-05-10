# Gereksinimler Belgesi

## Giriş

Bu özellik, HerbaFormix uygulamasındaki müşteri profil ekranını kapsamlı biçimde genişletir. Mevcut ekran yalnızca distribütör alanlarını göstermektedir; bu özellik ile müşteriye özel kişisel bilgiler, sağlık verileri, profil fotoğrafı, şifre değiştirme ve çıkış yapma işlevleri eklenir. Ayrıca distribütör-müşteri bağlantısını otomatikleştiren davet kodu sistemi hayata geçirilir: distribütör bir davet kodu üretir, müşteri kayıt sırasında bu kodu girerek ilgili distribütöre otomatik olarak bağlanır.

---

## Sözlük

- **Müşteri_Profil_Ekranı**: Müşteri rolündeki kullanıcının kendi profil bilgilerini görüntüleyip düzenleyebildiği Flutter ekranı.
- **UserProfileModel**: Firestore `userProfiles` koleksiyonundaki kullanıcı profilini temsil eden Dart model sınıfı.
- **AuthProvider**: Firebase Auth ve Firestore profil yönetimini koordine eden Flutter Provider sınıfı.
- **FirestoreService**: Firestore okuma/yazma işlemlerini soyutlayan servis sınıfı.
- **Davet_Kodu**: Distribütörün oluşturduğu, müşteri kaydında kullanılan benzersiz alfanümerik kod.
- **Davet_Sistemi**: Distribütörün davet kodu üretmesini ve müşterinin bu kodla distribütöre bağlanmasını sağlayan mekanizma.
- **Distribütör**: Herbalife ürünlerini satan ve müşteri takibi yapan kullanıcı rolü (`UserRole.distributor` ve üstü).
- **Müşteri**: Distribütör tarafından takip edilen son kullanıcı rolü (`UserRole.customer`).
- **assignedDistributorId**: Müşterinin bağlı olduğu distribütörün Firebase Auth UID'si; `UserProfileModel` üzerinde saklanır.
- **Firebase_Storage**: Profil fotoğraflarının depolandığı Firebase depolama servisi.
- **InviteCode_Koleksiyonu**: Firestore'da davet kodlarının saklandığı `inviteCodes` koleksiyonu.

---

## Gereksinimler

### Gereksinim 1: UserProfileModel Veri Modeli Genişletme

**Kullanıcı Hikayesi:** Bir geliştirici olarak, müşteriye özgü tüm profil alanlarını tek bir modelde tutmak istiyorum; böylece veri tutarlılığı sağlanır ve Firestore ile senkronizasyon kolaylaşır.

#### Kabul Kriterleri

1. THE **UserProfileModel** SHALL `birthDate` (DateTime, opsiyonel), `gender` (String, opsiyonel), `healthNotes` (String, opsiyonel), `allergies` (String, opsiyonel), `medications` (String, opsiyonel), `assignedDistributorId` (String, opsiyonel) ve `profilePhotoUrl` (String, opsiyonel) alanlarını içermelidir.
2. WHEN `toMap()` metodu çağrıldığında, THE **UserProfileModel** SHALL yeni alanları Firestore uyumlu anahtar-değer çiftlerine dönüştürmeli; değeri `null` olan opsiyonel alanları map'e dahil etmemelidir (Firestore dokümanında gereksiz `null` anahtarları oluşturmamak için).
3. WHEN `fromMap()` factory constructor'ı çağrıldığında, THE **UserProfileModel** SHALL Firestore'dan gelen alanları şu tür eşlemeleriyle dönüştürmelidir: `birthDate` → `int` → `DateTime`, `gender` → `String`, `healthNotes` → `String`, `allergies` → `String`, `medications` → `String`, `assignedDistributorId` → `String`, `profilePhotoUrl` → `String`.
4. WHEN `birthDate` alanı Firestore'a yazılırken, THE **UserProfileModel** SHALL tarihi `millisecondsSinceEpoch` (int) formatında saklamalıdır.
5. WHEN `birthDate` alanı Firestore'dan okunurken, THE **UserProfileModel** SHALL `millisecondsSinceEpoch` değerini `DateTime` nesnesine dönüştürmelidir.
6. IF herhangi bir opsiyonel alan Firestore'da mevcut değilse, THEN THE **UserProfileModel** SHALL ilgili alanı `null` olarak atamalıdır.
7. IF `fromMap()` içinde `birthDate` için Firestore'dan gelen değer `int` türünde değilse (örn. `String` veya beklenmedik bir tür), THEN THE **UserProfileModel** SHALL `birthDate` alanını `null` olarak atamalı ve sessizce devam etmelidir (veri bozulmasını önlemek için).

---

### Gereksinim 2: Müşteri Profil Ekranı — Kişisel Bilgiler

**Kullanıcı Hikayesi:** Bir müşteri olarak, profil ekranımda ad-soyad, e-posta, telefon, doğum tarihi ve cinsiyet bilgilerimi görüntüleyip güncellemek istiyorum; böylece distribütörüm beni daha iyi tanıyabilir.

#### Kabul Kriterleri

1. WHEN müşteri rolündeki kullanıcı profil ekranını açtığında, THE **Müşteri_Profil_Ekranı** SHALL ad-soyad, e-posta (salt okunur), telefon, doğum tarihi ve cinsiyet alanlarını mevcut profil değerleriyle dolu olarak göstermelidir; değer yoksa alanlar boş görünmelidir.
2. THE **Müşteri_Profil_Ekranı** SHALL e-posta alanını kullanıcı tarafından düzenlenemeyen (salt okunur) bir widget olarak sunmalıdır.
3. WHEN kullanıcı doğum tarihi alanına dokunduğunda, THE **Müşteri_Profil_Ekranı** SHALL 1900-01-01 ile kayıt tarihinden bir gün öncesi arasındaki tarihleri seçilebilir kılan bir tarih seçici (date picker) açmalıdır.
4. THE **Müşteri_Profil_Ekranı** SHALL cinsiyet seçimi için "Kadın", "Erkek" ve "Belirtmek İstemiyorum" seçeneklerini sunmalıdır.
5. IF kullanıcı "Kaydet" butonuna bastığında ad-soyad alanı boş veya yalnızca boşluk karakterlerinden oluşuyorsa, THEN THE **Müşteri_Profil_Ekranı** SHALL kayıt işlemini engellemeli ve ad-soyad alanı altında bir doğrulama hata mesajı göstermelidir.
6. IF kullanıcı "Kaydet" butonuna bastığında telefon numarası alanı dolu ancak E.164 formatına uygun değilse (ülke kodu dahil 7–15 rakam), THEN THE **Müşteri_Profil_Ekranı** SHALL kayıt işlemini engellemeli ve telefon alanı altında bir doğrulama hata mesajı göstermelidir.
7. WHEN kayıt işlemi başarıyla tamamlandığında, THE **Müşteri_Profil_Ekranı** SHALL kullanıcıya görünür bir başarı bildirimi (örn. SnackBar) göstermelidir.
8. IF kayıt işlemi sırasında bir hata oluşursa, THEN THE **Müşteri_Profil_Ekranı** SHALL kullanıcıya hata bildirimi göstermeli, form alanlarındaki mevcut değerleri korumalı ve kayıt öncesi duruma geri dönmemelidir.

---

### Gereksinim 3: Müşteri Profil Ekranı — Sağlık Bilgileri

**Kullanıcı Hikayesi:** Bir müşteri olarak, sağlık durumumu, alerjilerimi ve kullandığım ilaçları profilime eklemek istiyorum; böylece distribütörüm bana uygun program önerebilir.

#### Kabul Kriterleri

1. THE **Müşteri_Profil_Ekranı** SHALL sağlık durumu notları, alerji bilgileri ve ilaç kullanımı için en az 3 satır yüksekliğinde çok satırlı metin alanları içermelidir.
2. THE **Müşteri_Profil_Ekranı** SHALL boy (cm) alanını 50–300 cm aralığında ondalıklı sayı girişine izin veren bir alan olarak sunmalıdır.
3. THE **Müşteri_Profil_Ekranı** SHALL mevcut kilo (kg) ve hedef kilo (kg) alanlarını 10–500 kg aralığında ondalıklı sayı girişine izin veren alanlar olarak sunmalıdır.
4. IF kullanıcı boy, mevcut kilo veya hedef kilo alanına sayısal olmayan bir değer girerse, THEN THE **Müşteri_Profil_Ekranı** SHALL kayıt işlemini engellemeli ve ilgili alan altında doğrulama hata mesajı göstermelidir.
5. IF kullanıcı boy, mevcut kilo veya hedef kilo alanına izin verilen aralık dışında bir değer girerse (boy için 50–300 cm, kilo için 10–500 kg), THEN THE **Müşteri_Profil_Ekranı** SHALL kayıt işlemini engellemeli ve geçerli aralığı belirten bir doğrulama hata mesajı göstermelidir.
6. THE **Müşteri_Profil_Ekranı** SHALL sağlık durumu notları, alerji bilgileri, ilaç kullanımı, boy, mevcut kilo ve hedef kilo alanlarını opsiyonel olarak kabul etmeli; boş bırakıldığında kayıt işlemi engellenmelidir.
7. THE **Müşteri_Profil_Ekranı** SHALL sağlık durumu notları, alerji bilgileri ve ilaç kullanımı alanlarının her biri için en fazla 1000 karakter girişine izin vermelidir; bu sınır aşıldığında kullanıcıya görünür bir uyarı gösterilmelidir.

---

### Gereksinim 4: Müşteri Profil Ekranı — Profil Fotoğrafı

**Kullanıcı Hikayesi:** Bir müşteri olarak, profil fotoğrafımı yüklemek istiyorum; böylece distribütörüm beni kolayca tanıyabilir.

#### Kabul Kriterleri

1. WHILE kullanıcının `profilePhotoUrl` alanı boşken, THE **Müşteri_Profil_Ekranı** SHALL profil fotoğrafı alanını varsayılan bir yer tutucu (placeholder) avatar ile dairesel biçimde göstermelidir.
2. WHEN kullanıcı profil fotoğrafına dokunduğunda, THE **Müşteri_Profil_Ekranı** SHALL "Kameradan Çek" ve "Galeriden Seç" seçeneklerini sunan bir alt menü (bottom sheet) açmalıdır.
3. WHEN kullanıcı bir fotoğraf seçtiğinde, THE **Müşteri_Profil_Ekranı** SHALL seçilen fotoğrafı önizleme olarak göstermeli; yalnızca JPEG, PNG veya HEIC formatındaki ve 10 MB'ı aşmayan dosyaları kabul etmelidir.
4. WHEN kullanıcı "Kaydet" butonuna bastığında ve yeni bir fotoğraf seçilmişse, THE **AuthProvider** SHALL fotoğrafı Firebase Storage'a `users/{uid}/profile.jpg` yoluna yüklemeli ve dönen indirme URL'sini `profilePhotoUrl` alanına kaydetmelidir.
5. WHILE fotoğraf yükleme işlemi devam ederken, THE **Müşteri_Profil_Ekranı** SHALL avatar alanı üzerinde bir yükleme göstergesi (CircularProgressIndicator) göstermeli ve "Kaydet" butonunu devre dışı bırakmalıdır.
6. IF fotoğraf yükleme işlemi başarısız olursa, THEN THE **Müşteri_Profil_Ekranı** SHALL kullanıcıya hata bildirimi göstermeli ve önceki fotoğrafı (veya yer tutucuyu) geri yüklemeli; profil kaydı işlemi fotoğraf hatası nedeniyle tamamen iptal edilmemelidir.
7. WHEN fotoğraf yükleme işlemi başarıyla tamamlandığında, THE **Müşteri_Profil_Ekranı** SHALL yüklenen fotoğrafı ağdan (network) yükleyerek dairesel avatar alanında göstermelidir.
8. IF `profilePhotoUrl` alanı dolu ancak ağdan fotoğraf yüklenemezse, THEN THE **Müşteri_Profil_Ekranı** SHALL varsayılan yer tutucu avatarı göstermelidir.

---

### Gereksinim 5: Müşteri Profil Ekranı — Distribütör Bilgisi (Salt Okunur)

**Kullanıcı Hikayesi:** Bir müşteri olarak, bağlı olduğum distribütörün adını ve iletişim bilgisini profilimde görmek istiyorum; böylece distribütörüme kolayca ulaşabilirim.

#### Kabul Kriterleri

1. IF `assignedDistributorId` alanı dolu ise, THEN THE **Müşteri_Profil_Ekranı** SHALL distribütörün adını ve telefon numarasını salt okunur bir kart içinde göstermelidir.
2. THE **Müşteri_Profil_Ekranı** SHALL distribütör bilgisi kartındaki tüm alanları yalnızca okunabilir (non-editable) widget'larla sunmalı; kullanıcı bu alanları klavye veya dokunma yoluyla değiştirememelidir.
3. IF `assignedDistributorId` alanı boş veya `null` ise, THEN THE **Müşteri_Profil_Ekranı** SHALL distribütör kartı yerine "Henüz bir distribütöre bağlı değilsiniz." bilgi mesajını göstermelidir.
4. WHEN distribütör bilgisi kartı gösterilirken, THE **FirestoreService** SHALL distribütörün profil bilgilerini `userProfiles/{assignedDistributorId}` yolundan okumalıdır.
5. IF `userProfiles/{assignedDistributorId}` dokümanı Firestore'da bulunamazsa veya okuma sırasında bir hata oluşursa, THEN THE **Müşteri_Profil_Ekranı** SHALL distribütör kartı yerine "Distribütör bilgisi yüklenemedi." hata mesajını göstermeli ve uygulamanın geri kalanı etkilenmemelidir.

---

### Gereksinim 6: Profil Kaydetme İşlemi

**Kullanıcı Hikayesi:** Bir müşteri olarak, profil bilgilerimi güncelleyip kaydedebilmek istiyorum; böylece bilgilerim her zaman güncel kalır.

#### Kabul Kriterleri

1. WHEN kullanıcı "Kaydet" butonuna bastığında, THE **Müşteri_Profil_Ekranı** SHALL önce form doğrulamasını çalıştırmalı; IF form geçerliyse THEN THE **AuthProvider** SHALL güncellenmiş `UserProfileModel`'i Firestore'a `merge: true` seçeneğiyle yazmalıdır.
2. IF kullanıcı "Kaydet" butonuna bastığında form geçersizse, THEN THE **Müşteri_Profil_Ekranı** SHALL Firestore'a yazma işlemi başlatmadan geçersiz alanları vurgulayan doğrulama hata mesajlarını göstermelidir.
3. WHEN kaydetme işlemi başarılı olduğunda, THE **Müşteri_Profil_Ekranı** SHALL kullanıcıya görünür bir başarı bildirimi (örn. SnackBar) göstermelidir.
4. IF kaydetme işlemi sırasında bir hata oluşursa (ağ hatası veya Firestore hatası), THEN THE **Müşteri_Profil_Ekranı** SHALL kullanıcıya hata bildirimi göstermeli ve form alanlarındaki mevcut değerleri korumalıdır.
5. WHILE kaydetme işlemi devam ederken, THE **Müşteri_Profil_Ekranı** SHALL "Kaydet" butonunu devre dışı bırakmalı ve yükleme göstergesi sunmalıdır.
6. THE **Müşteri_Profil_Ekranı** SHALL kaydetme işlemi tamamlanana kadar ekrandan çıkışı engellememelidir.

---

### Gereksinim 7: Şifre Değiştirme

**Kullanıcı Hikayesi:** Bir müşteri olarak, uygulama içinden şifremi değiştirebilmek istiyorum; böylece hesabımın güvenliğini koruyabilirim.

#### Kabul Kriterleri

1. THE **Müşteri_Profil_Ekranı** SHALL "Şifre Değiştir" butonunu içermelidir.
2. WHEN kullanıcı "Şifre Değiştir" butonuna bastığında, THE **Müşteri_Profil_Ekranı** SHALL mevcut şifre, yeni şifre ve yeni şifre tekrarı alanlarını içeren bir diyalog (dialog) açmalıdır.
3. IF kullanıcı şifre değiştirme formunu gönderdiğinde yeni şifre ile tekrar alanı birbirinden farklıysa, THEN THE **Müşteri_Profil_Ekranı** SHALL kayıt işlemini engellemeli ve uyuşmazlığı belirten bir doğrulama hata mesajı göstermelidir.
4. IF kullanıcı şifre değiştirme formunu gönderdiğinde yeni şifre 6 karakterden kısaysa, THEN THE **Müşteri_Profil_Ekranı** SHALL kayıt işlemini engellemeli ve minimum uzunluğu belirten bir doğrulama hata mesajı göstermelidir.
5. WHEN kullanıcı şifre değiştirme formunu geçerli verilerle onayladığında, THE **AuthProvider** SHALL Firebase Auth `reauthenticateWithCredential` metodunu mevcut şifreyle çağırmalı, ardından `updatePassword` metodunu yeni şifreyle çağırmalıdır.
6. WHEN şifre değiştirme işlemi başarılı olduğunda, THE **Müşteri_Profil_Ekranı** SHALL kullanıcıya başarı bildirimi göstermeli ve diyalogu kapatmalıdır.
7. IF Firebase Auth mevcut şifrenin yanlış olduğunu bildirirse, THEN THE **Müşteri_Profil_Ekranı** SHALL mevcut şifre alanı altında hata mesajı göstermeli ve diyalogu açık tutmalıdır.
8. IF Firebase Auth `requires-recent-login` hatası döndürürse, THEN THE **Müşteri_Profil_Ekranı** SHALL kullanıcıya yeniden giriş yapması gerektiğini bildiren bir hata mesajı göstermelidir.
9. IF şifre değiştirme sırasında ağ hatası oluşursa, THEN THE **Müşteri_Profil_Ekranı** SHALL kullanıcıya ağ hatası bildirimi göstermeli ve diyalogu açık tutmalıdır.

---

### Gereksinim 8: Çıkış Yapma

**Kullanıcı Hikayesi:** Bir müşteri olarak, uygulamadan güvenli biçimde çıkış yapabilmek istiyorum.

#### Kabul Kriterleri

1. THE **Müşteri_Profil_Ekranı** SHALL "Çıkış Yap" butonunu içermelidir.
2. WHEN kullanıcı "Çıkış Yap" butonuna bastığında, THE **Müşteri_Profil_Ekranı** SHALL kullanıcıdan onay isteyen bir diyalog göstermelidir.
3. WHEN kullanıcı onay diyalogunda onaylama seçeneğini seçtiğinde, THE **AuthProvider** SHALL Firebase Auth oturumunu sonlandırmalıdır.
4. WHEN oturum başarıyla sonlandırıldığında, THE **AuthProvider** SHALL kullanıcıyı giriş ekranına yönlendirmelidir.
5. IF oturum sonlandırma işlemi sırasında bir hata oluşursa, THEN THE **Müşteri_Profil_Ekranı** SHALL kullanıcıya hata bildirimi göstermeli ve kullanıcı oturum açık kalmalıdır.

---

### Gereksinim 9: Davet Kodu Üretme (Distribütör Tarafı)

**Kullanıcı Hikayesi:** Bir distribütör olarak, uygulama içinden davet kodu üretmek istiyorum; böylece müşterilerimi bu kodla sisteme bağlayabilirim.

#### Kabul Kriterleri

1. THE **Distribütör_Paneli** SHALL distribütörün davet kodu üretebileceği bir "Davet Kodu Oluştur" butonu içermelidir.
2. WHEN distribütör "Davet Kodu Oluştur" butonuna bastığında, THE **FirestoreService** SHALL Firestore `inviteCodes` koleksiyonunda şu alanları içeren yeni bir doküman oluşturmalıdır: `code` (büyük harf ve rakamlardan oluşan benzersiz 8 karakterlik alfanümerik string), `distributorId` (distribütörün UID'si), `createdAt` (Timestamp), `isUsed` (boolean, başlangıç değeri `false`), `usedByUserId` (String, başlangıç değeri `null`).
3. WHEN yeni bir davet kodu üretilmeden önce, THE **FirestoreService** SHALL üretilen kodun `inviteCodes` koleksiyonunda mevcut olmadığını doğrulamalı; çakışma durumunda yeni bir kod üretmelidir.
4. WHEN davet kodu başarıyla oluşturulduğunda, THE **Distribütör_Paneli** SHALL kodu ekranda büyük ve okunabilir biçimde göstermeli ve tek dokunuşla panoya kopyalama seçeneği sunmalıdır.
5. THE **Distribütör_Paneli** SHALL distribütörün daha önce oluşturduğu ve henüz kullanılmamış (`isUsed: false`) davet kodlarını oluşturulma tarihine göre sıralı olarak listeleyebilmelidir.
6. IF davet kodu oluşturma sırasında bir hata oluşursa, THEN THE **Distribütör_Paneli** SHALL kullanıcıya hata bildirimi göstermeli ve Firestore'a kısmi yazma yapılmamış olmalıdır.

---

### Gereksinim 10: Davet Koduyla Kayıt (Müşteri Tarafı)

**Kullanıcı Hikayesi:** Bir müşteri olarak, distribütörümden aldığım davet koduyla kayıt olmak istiyorum; böylece otomatik olarak distribütörüme bağlanabilirim.

#### Kabul Kriterleri

1. THE **Giriş_Ekranı** SHALL kayıt modunda müşteri rolü seçildiğinde opsiyonel bir "Davet Kodu" metin alanı göstermelidir.
2. WHEN kullanıcı kayıt formunu gönderdiğinde ve davet kodu alanı doluysa, THE **AuthProvider** SHALL Firestore `inviteCodes` koleksiyonunda `code` alanı girilen değere eşit olan dokümanı aramalıdır.
3. WHEN davet kodu geçerliyse (`isUsed: false` ve doküman mevcut), THE **AuthProvider** SHALL yeni kullanıcının `UserProfileModel.assignedDistributorId` alanını ilgili dokümanın `distributorId` değeriyle doldurmalıdır.
4. WHEN davet kodu başarıyla kullanıldığında, THE **FirestoreService** SHALL `inviteCodes` koleksiyonundaki ilgili dokümanı `isUsed: true` ve `usedByUserId: <yeni kullanıcı UID>` olarak güncellemeli; bu güncellemeyi kullanıcı profili oluşturmayla aynı Firestore batch işleminde atomik olarak gerçekleştirmelidir.
5. IF girilen davet kodu `inviteCodes` koleksiyonunda bulunamazsa, THEN THE **Giriş_Ekranı** SHALL kayıt işlemini engellemeli ve davet kodu alanı altında geçersiz kod hata mesajı göstermelidir.
6. IF girilen davet kodu `isUsed: true` ise, THEN THE **Giriş_Ekranı** SHALL kayıt işlemini engellemeli ve davet kodu alanı altında kodun daha önce kullanıldığını belirten hata mesajı göstermelidir.
7. WHEN davet kodu alanı boş bırakıldığında, THE **AuthProvider** SHALL kayıt işlemini davet kodu olmadan tamamlamalı ve `assignedDistributorId` alanını `null` olarak bırakmalıdır.
8. IF batch yazma işlemi (profil oluşturma + davet kodu güncelleme) kısmen başarısız olursa, THEN THE **FirestoreService** SHALL tüm işlemi geri almalı (rollback) ve kullanıcıya hata bildirimi göstermelidir; kısmi durum oluşmamalıdır.

---

### Gereksinim 11: Distribütör Panelinde Bağlı Müşteri Görünümü

**Kullanıcı Hikayesi:** Bir distribütör olarak, davet kodum aracılığıyla bağlanan müşterilerimi panelimde görmek istiyorum; böylece müşteri takibimi kolayca yapabilirim.

#### Kabul Kriterleri

1. WHEN distribütör müşteri listesini görüntülediğinde, THE **CustomerProvider** SHALL hem `users/{distributorId}/customers` alt koleksiyonundaki müşterileri hem de `userProfiles` koleksiyonunda `assignedDistributorId` alanı distribütörün UID'siyle eşleşen müşterileri birleştirerek tekrarsız (deduplicated) bir liste olarak sunmalıdır.
2. THE **Müşteri_Listesi** SHALL her müşteri kartında müşterinin adını, telefon numarasını ve bağlanma yöntemini (davet kodu veya manuel ekleme) göstermelidir.
3. WHEN distribütör bir müşteri kartına tıkladığında, THE **Müşteri_Detay_Ekranı** SHALL müşterinin tüm profil bilgilerini (sağlık notları, alerjiler, ilaçlar dahil) salt okunur biçimde göstermelidir.
4. WHEN iki farklı kaynaktan (alt koleksiyon ve `userProfiles`) aynı müşteri geliyorsa, THE **CustomerProvider** SHALL müşteriyi listede yalnızca bir kez göstermeli ve `userProfiles` kaynağındaki veriyi önceliklendirmelidir.

---

### Gereksinim 12: Veri Güvenliği ve Firestore Kuralları

**Kullanıcı Hikayesi:** Bir sistem yöneticisi olarak, müşteri profil verilerinin yalnızca yetkili kullanıcılar tarafından erişilebilir olmasını istiyorum; böylece kullanıcı gizliliği korunur.

#### Kabul Kriterleri

1. THE **Firestore_Güvenlik_Kuralları** SHALL bir kullanıcının yalnızca kendi `userProfiles/{userId}` dokümanını okuyup yazabilmesine izin vermelidir; başka bir kullanıcının profilini okuma veya yazma girişimi reddedilmelidir.
2. THE **Firestore_Güvenlik_Kuralları** SHALL bir distribütörün yalnızca `assignedDistributorId` alanı kendi UID'siyle eşleşen `userProfiles` dokümanlarını okuyabilmesine izin vermelidir.
3. THE **Firestore_Güvenlik_Kuralları** SHALL `inviteCodes` koleksiyonunda yalnızca kimliği doğrulanmış (`request.auth != null`) kullanıcıların okuma yapabilmesine izin vermelidir.
4. THE **Firestore_Güvenlik_Kuralları** SHALL `inviteCodes` koleksiyonunda yalnızca `userProfiles/{uid}.role` alanı distribütör rolüne sahip kullanıcıların yeni doküman oluşturabilmesine izin vermelidir.
5. THE **Firestore_Güvenlik_Kuralları** SHALL `userProfiles/{userId}` dokümanında `assignedDistributorId` alanının istemci tarafından doğrudan güncellenmesini reddetmelidir; bu alan yalnızca davet kodu batch yazma işlemi sırasında sunucu tarafı mantığıyla atanabilir.
6. THE **Firestore_Güvenlik_Kuralları** SHALL `inviteCodes/{codeId}` dokümanında `isUsed` ve `usedByUserId` alanlarının yalnızca batch yazma işlemi sırasında güncellenebilmesini sağlamalı; istemci tarafından doğrudan bu alanların değiştirilmesi reddedilmelidir.
