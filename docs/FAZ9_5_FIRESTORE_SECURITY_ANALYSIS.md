# Faz 9.5 Firestore Güvenlik Analizi

## Veri yolları ve sahiplik

| Yol | Amaç | Okuma/Yazma yetkisi |
|---|---|---|
| `users/{distributorId}/inventory/{productId}` | Güncel ürün stoğu ve ağırlıklı ortalama maliyet | Yalnızca belge yolundaki distribütör/koç rolü |
| `users/{distributorId}/inventoryMovements/{movementId}` | Değiştirilemez stok hareket defteri | Yalnızca sahip distribütör okuyup oluşturabilir; güncelleme/silme yok |
| `users/{distributorId}/customerProductPrices/{customerId_productId}` | Müşteri + ürün özel fiyatı | Yalnızca sahip distribütör/koç; müşteri okuyamaz |
| `users/{distributorId}/orders/{orderId}` | Talep, satış, ödeme ve stok çevrimi | Sahip distribütör yönetir; atanmış müşteri yalnızca kendi bekleyen talebini oluşturur ve sınırlı alanları değiştirir |

Firestore veritabanı türü `FIRESTORE_NATIVE` (Standard) olarak doğrulandı.

## Şema ve sorgular

- Envanter `productName` alanına göre sıralanır.
- Hareketler `occurredAt desc` ile izlenir. İlk sürümde ürün filtresi kullanılmadığı için ek bileşik indeks gerekmez.
- Özel fiyat belge kimliği, `customerId + '_' + productId` ile deterministiktir; tek belge okumasıyla uygulanır.
- Sipariş teslimatı, sipariş belgesi + ilgili tüm stok bakiyeleri + değiştirilemez hareket belgelerini tek Firestore transaction içinde günceller.
- Teslimat çevrimi (`inventoryCycle`) ve deterministik hareket kimlikleri tekrar çalıştırmada çift stok düşümünü engeller.

## Kurallarda doğrulanan sınırlar

- Bilinmeyen alanlar reddedilir (`keys().hasOnly`).
- Metin uzunlukları, sayısal aralıklar, enum değerleri ve timestamp türleri doğrulanır.
- Stok bakiyesi negatif olamaz.
- Stok hareketi sıfır adetli veya negatif maliyetli olamaz ve oluşturulduktan sonra değiştirilemez.
- Müşteri özel fiyatı müşteri tarafından okunamaz; belge kimliği içerikteki müşteri ve ürünle eşleşmek zorundadır.
- Müşteri talebi yalnızca `pending`, ödeme bekliyor, tahsilat `0` ve stok çevrimi `0` olarak oluşturulabilir.
- Teslim edilmiş sipariş doğrudan silinemez; önce iptal edilerek transaction içinde stok iadesi yapılmalıdır.

## Saldırı denetimi

Emülatör testleri şu denemeleri reddeder:

- Başka distribütörün veya müşterinin stok/maliyet verisini okuması.
- Stok hareketinin sonradan değiştirilmesi.
- Negatif stok veya şema dışı alan yazılması.
- Müşterinin özel fiyatı okuması ya da sahte ödeme/tahsilat/stok çevrimi göndermesi.
- Yanlış kimlikli özel fiyat belgesi yazılması.
- Teslim edilmiş siparişin stok iadesi olmadan silinmesi.

## Bilinçli sınır

Distribütör kendi stok verisinin sahibidir ve kendi fiziksel sayım düzeltmesini yapabilir. İstemci transaction'ı bakiye ile hareket defterini birlikte yazar; hareketler sonradan değiştirilemez. Daha yüksek güven gerektiren çok kullanıcılı muhasebe senaryosunda stok mutasyonları güvenilir sunucu fonksiyonuna taşınmalıdır.
