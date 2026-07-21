# FAZ 23 Firestore güvenlik analizi

## Hedef ve veri erişimi

- Instance: `projects/herbaformix/databases/(default)`
- Edition/type/location: Standard / Firestore Native / `eur3`
- Yeni yol: `/users/{userId}/notifications/{notificationId}`
- Sorgular: `createdAt desc, limit 100`; okunmamış toplu güncelleme için
  `isRead == false, limit 100`.
- Bildirim oluşturma Cloud Functions/Admin SDK sorumluluğundadır. Mobil istemci
  oluşturamaz; kullanıcı yalnızca kendi kayıtlarını okuyabilir, silebilir ve
  `isRead/readAt` alanlarını false -> true geçişiyle güncelleyebilir.
- Tercihler mevcut özel `/userProfiles/{uid}.notificationSettings` haritasında
  tutulur; başka kullanıcılara açılmaz.

## Şema

Zorunlu alanlar: `type`, `title`, `body`, `createdAt`, `isRead`. İsteğe bağlı
alanlar: `readAt`, `/home` ile sınırlandırılmış `actionPath`, `sourceId`.
Kurallar alan listesini, türleri, enum değerlerini ve tüm string boyutlarını
doğrular. `createdAt`, içerik ve yönlendirme alanları istemci güncellemesinde
değiştirilemez.

## Saldırı matrisi

| Deneme | Sonuç / savunma |
|---|---|
| Kimliksiz listeleme | Reddedilir; sahip oturumu zorunlu. |
| Başka kullanıcının okuması/yazması | Yol sahibinin UID kontrolüyle reddedilir. |
| İstemciden sahte bildirim oluşturma | `allow create: if false`. |
| Başlık/gövde/createdAt ele geçirme | Güncelleme alanları yalnızca `isRead/readAt`. |
| Sahte alan ve şema kirletme | `keys().hasOnly(...)` doğrulaması. |
| 1 MB metin / kaynak tüketimi | Başlık 160, gövde 2000 karakter ile sınırlı. |
| Tür/type juggling | Enum ve Firestore tip kontrolleri. |
| Geçersiz deep link | Yalnızca `^/home(/.*)?$`, en fazla 300 karakter. |
| Okundu durumunu tekrar oynatma | Yalnızca `false -> true` geçişine izin verilir. |
| Yetki yükseltme / sahiplik değiştirme | Sahiplik belge alanında değil, güvenilir path UID'sindedir. |
| Yetkisiz silme | Yalnızca path sahibi silebilir. |
| Query/rule uyumsuzluğu | Sahip bazlı alt koleksiyon sorgusu kuralla uyumludur. |

Bu belge FAZ 23 kapsamındaki yeni koleksiyonun incelemesidir; mevcut diğer
koleksiyonların kurallarını yeniden sertleştirme iddiası taşımaz.
