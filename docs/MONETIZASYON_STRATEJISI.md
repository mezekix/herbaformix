# Herbaformix — Monetizasyon Stratejisi Notu

> **Tarih:** 2026-06-14
> **Konu:** Uygulamaya reklam koyma ve AI maliyetini distribütöre yansıtma alternatifinin değerlendirilmesi
> **Durum:** Strateji önerisi, henüz uygulanmadı

---

## TL;DR

1. **3rd-party reklam (AdMob vb.) ÖNERILMIYOR** — kısa vadeli gelir, uzun vadeli müşteri/distribütör güveni kaybı; net negatif.
2. **Önerilen model:** Distribütöre sabit aylık subscription + AI kotası (Model C + A hibrit).
3. **AI maliyeti distribütöre yansıtılabilir ve yansıtılmalı** — sektör normu, distribütörler ödemeye alışkın.
4. **Müşteri tarafı sıfır friksiyon kalmalı** — müşteri kotayı/AI maliyetini hiç hissetmemeli.

---

## 1. Uygulamanın Profili (Karar Bağlamı)

Herbaformix klasik B2C app değil:

- **Çift taraflı kullanıcı:** Müşteriler (kalori/su takibi, programlar, ilerleme) + Distribütörler (müşteri yönetimi, sipariş, takip pipeline)
- **Müşteri zaten ödüyor:** Sipariş veriyor, fiziksel ürün alıyor
- **Hassas veri:** Kalori, kilo, ölçü → KVKK kapsamında
- **MLM/Network marketing modeli:** Distribütör tarafı = saha satış ekibi
- **AI entegrasyonu mevcut:** Gemini 2.5 Flash, food estimation servisi

Bu üç faktör (ödeyen müşteri + hassas veri + B2B/B2C hibrit) reklam için kırmızı bayrak; AI maliyet aktarımı için ise yeşil bayrak.

---

## 2. Reklam Sistemi Değerlendirmesi

### Neden Reklam Yanlış Karar

| Faktör | Etkisi |
|---|---|
| Müşteri zaten para ödüyor | "Üstüne reklam mı?" hissi |
| Sağlık/wellness niş | Programatik reklam = rakip ya da sahte sağlık ürünü riski |
| Distribütörün iş aracı | Müşterinin Apranax reklamı görmesi distribütörün profesyonel imajını çökertir |
| KVKK + reklam SDK | Sağlık verisi + reklam takibi ciddi hukuki risk |
| Premium konum | MyFitnessPal Premium, Apple Fitness+ — hiçbiri reklam göstermez |

### Müşteri Tepki Segmentleri

- **Yeni müşteri:** Onboarding tamamlama oranında %15-30 düşüş riski, app store'da 2-3 yıldız
- **Aktif kullanıcı:** Negatif yorum bırakma olasılığı en yüksek grup
- **Distribütör yakın çevresi:** Distribütöre "uygulamayı sildim" mesajı → distribütör sizden hesap sorar
- **Ads-free satın alan:** Sayısı %2-5'i geçmez; üstüne tortulu memnuniyetsizlik

### Distribütör Tepkileri (En Az Müşteri Kadar Önemli)

- Satış aracını "ucuz app" gibi gösterir
- Rakip ürün reklamı kâbusu (algoritma kontrolü yok)
- Müşteri kaybını size fatura ederler
- Saha güveni hızlı erir

### Kabaca Sayısal Tahmin (10.000 MAU)

| Senaryo | Reklam Geliri | Sipariş Kaybı | Net |
|---|---|---|---|
| AdMob banner + interstitial | $300-800/ay | -$2.000-5.000/ay | **Negatif** |
| Sadece banner | $100-250/ay | -$800-2.000/ay | **Negatif** |
| Reklam yok + premium feature | $0 + abonelik | +sipariş | **Pozitif** |

### "Reklamsız Satın Alma" Modelini Çözer mi?
**Hayır, kısmen.** Çünkü:
- Müşteri zaten ürün için ödüyor → çift ödeme algısı
- Dönüşüm oranı çok düşük (%1-3)
- Brand'i premium'dan ucuza çeker

### Eğer Yine de Reklam Kararlıysa (Hasarı Minimize Et)
1. Sadece ücretsiz/hiç sipariş vermemiş kullanıcılara
2. Sadece kendi ürün reklamlarınız (3rd-party SDK YOK)
3. Asla interstitial/rewarded video/pop-up
4. Hassas ekranlarda asla (kalori girerken, distribütörle iletişimde)
5. 4 hafta A/B test ile churn'ü ölç
6. Distribütörlere önceden duyur

---

## 3. AI Maliyetini Distribütöre Yansıtma (Önerilen Yön)

### Gerçek Maliyet (Gemini 2.5 Flash, Haziran 2026)

- Input: ~$0.075 / 1M token
- Output: ~$0.30 / 1M token
- Yemek tahmini başına: ~$0.0002

| Kullanım | Aylık Maliyet |
|---|---|
| 100 müşteri × 5/gün | ~$3 |
| 1.000 müşteri × 5/gün | ~$30 |
| 10.000 müşteri × 10/gün | ~$600 |
| + Görsel input | 3-5× üstüne |

### Üç Faturalandırma Modeli

#### Model A — Kredi Havuzu
Distribütör aylık kredi paketi alır, müşterileri tüketir.
- ✅ Maliyet predictable
- ❌ Müşteri ay ortasında kota tükenmesi kötü UX

#### Model B — Müşteri Başına Abonelik
Aktif müşteri başına ödeme.
- ✅ Sezgisel ("müşterim = kazancım = tool ücreti")
- ❌ Aktif/pasif tanımı kritik, tracking karmaşık

#### Model C — Distribütör Sabit Subscription (sektör normu)
Aylık sabit ücret, her şey dahil.
- ✅ MLM dünyasında zaten böyle çalışıyor (BackOffice fee)
- ❌ Fair use eşiği gerek

### Önerilen: Model C + A Hibrit

**Sabit subscription + aşım için ek kredi:**

```
Bedava:        5 müşteriye kadar, AI yok, temel takip
Distribütör:   ₺199/ay  →  50 müşteri + AI kotalı + insights
Pro:           ₺499/ay  →  Sınırsız müşteri + AI sınırsız (fair use)
                            + öncelikli destek + raporlar
```

Kota aşımında: Ek kredi paketi (Model A) ile esneklik.

### Distribütöre Mesajlama

> "₺199/ay verdiğiniz tool'la 50 müşterinizin uygulamadaki AI'lı kalori takibi,
> ölçüm grafikleri ve haftalık raporları açık kalıyor. Churn oranınız %30 düşüyor,
> ayda 1 ekstra sipariş bile net kârlı."

### Müşteri Tarafı (Kritik)

✅ **DOĞRU:** AI butonu her zaman aktif görünür. Kota dolarsa graceful fallback (manuel ekleme önerisi).

❌ **YANLIŞ:** "Distribütörünüz AI hakkı tanımlamamış" gibi mesaj.

❌ **YANLIŞ:** Müşteriye "AI hakkı satın al" pop-up.

---

## 4. Teknik Uygulama Taslağı

### 4.1 Firestore Schema Eklemesi

```
distributors/{distributorId}/usage/{yyyy-MM}
  - aiCalls: int
  - planType: 'free' | 'distributor' | 'pro'
  - quotaLimit: int
  - resetAt: timestamp
```

### 4.2 `FoodEstimationService.estimate()` Değişikliği

- Çağrıdan önce müşterinin distribütör ID'sini al
- Distribütörün plan/kota durumunu kontrol et
- Sayaç artır, limit aşılırsa graceful fallback
- Müşteri başına da soft limit (örn. günde 30 çağrı abuse engeli)

### 4.3 Distribütör Paneline Yeni Ekran

"AI Kullanımı" sayfası: bu ay kaç çağrı, plana göre yüzde, upgrade CTA.

### 4.4 Bonus: Distribütör Tarafında AI Feature'lar

Asıl katlama potansiyeli buradan:
- "Müşterimin son 3 ayını özetle" → AI rapor
- "Bu müşteri için kişiselleştirilmiş program öner" → AI program drafting
- "Bu hafta hangi müşterilerime özel mesaj atayım?" → AI prioritizer
- "Sipariş geçmişinden cross-sell önerisi" → AI sales coach

Bunlar için distribütör memnuniyetle öder → AI maliyet merkezi değil, **kâr merkezi**.

---

## 5. Riskler ve Önlemler

| Risk | Önlem |
|---|---|
| Distribütör "şimdi para mı?" tepkisi | İlk 3 ay ücretsiz tam erişim, değer görüp ödesin |
| Distribütör abone olmazsa müşteri churn | Free tier'da temel uygulama (su, manuel kalori, ölçüm) tam çalışsın |
| Tek distribütör abuse'u | Müşteri başına soft limit (günde 30 AI çağrısı) |
| Fatura sürprizi | Sabit plan + kota; kullanım bazlı dinamik fiyat KOYMA |
| Ödeme entegrasyon karmaşıklığı | İlk versiyon manuel (WhatsApp + admin paneli upgrade); Iyzico/Stripe sonra |

---

## 6. Yol Haritası

| Faz | Süre | Yapılacak |
|---|---|---|
| **1. Tracking** | 1-2 gün | AI usage tracking infrastructure, henüz limit yok |
| **2. Distribütör Görünürlüğü** | 2-4 hafta | Distribütör paneline "AI kullanımı" sayfası, ücretsiz |
| **3. Veri Toplama** | 2-3 ay | Real kullanım datası, plan fiyatlandırması için baz |
| **4. Launch** | 3-4 ay | Sabit subscription'ı aç, mevcut distribütörlere 3 ay grandfather indirim |

---

## 7. Karar Özeti

- ❌ **Reklam ekleme** (3rd-party, programatik)
- ✅ **AI maliyetini distribütör subscription'ı içinde aktar** (Model C + A hibrit)
- ✅ **Distribütör tarafına AI feature'lar ekle** (gerçek kâr merkezi)
- ✅ **Müşteri tarafında sıfır friksiyon** (kota/maliyet hiç görünmesin)
- ⏭ **İlk adım:** AI usage tracking infrastructure'ı kur (henüz limit yok, sadece sayım)
