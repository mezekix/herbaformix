# Gemini AI — Kalori Tahmini Kurulumu

Uygulamadaki "AI ile tahmin" özelliği Google Gemini Flash modelini kullanır.
Yerel `food_database.json` listesinde bulunmayan yemekler için kullanıcı doğal
dilde yemek adı yazar, Gemini tahmini kalori bilgisi döndürür.

## 1) API Anahtarı Alma (5 dk)

1. [Google AI Studio](https://aistudio.google.com/app/apikey) adresine git
2. Google hesabınla giriş yap
3. **Get API key** → **Create API key in new project** (veya mevcut Cloud projeni seç)
4. Anahtar gösterildiğinde **kopyala**. Bir daha gösterilmez — kaybedersen yenisini oluştur

**Free tier**: Gemini Flash dakikada 15 istek, günde 1500 istek **ücretsiz**.
Küçük/orta uygulamalar için fazlasıyla yeterli; üzeri Google'ın faturalandırma
kurallarına tabi (1M girdi token ≈ 0,075 USD).

## 2) Anahtarı Build'e Geçirme

`flutter run` veya `flutter build` çağrılarında `--dart-define`:

```bash
flutter run --dart-define=GEMINI_API_KEY=AIza...senin_anahtarın
```

Release build için:

```bash
flutter build apk --release --dart-define=GEMINI_API_KEY=AIza...
flutter build ipa --release --dart-define=GEMINI_API_KEY=AIza...
```

### VS Code / IntelliJ ile sürekli çalıştırma

`.vscode/launch.json` dosyasına:

```json
{
  "configurations": [
    {
      "name": "Flutter (Gemini)",
      "type": "dart",
      "request": "launch",
      "program": "lib/main.dart",
      "args": [
        "--dart-define=GEMINI_API_KEY=AIza...senin_anahtarın"
      ]
    }
  ]
}
```

**ÖNEMLİ:** `.vscode/launch.json`'ı **`.gitignore`'a ekle** ki anahtar
yanlışlıkla repo'ya commit edilmesin.

## 3) Anahtarı Güvenliğe Alma (kritik)

Anahtar APK içinde compile-time olarak gömülür. Birisi APK'yı decompile ederse
çıkarabilir. Bunu mitigation için Google Cloud Console'da kısıtlama koy:

1. [Google Cloud Console — API Keys](https://console.cloud.google.com/apis/credentials)
2. Anahtarına tıkla → **Edit API key**
3. **Application restrictions** → **Android apps**:
   - **Add an item** ile uygulamanı ekle
   - **Package name**: `com.mze.herbaformix` (veya senin paketin)
   - **SHA-1 certificate fingerprint**: hem debug hem release SHA-1'i ekle
     - Debug için: `cd android && ./gradlew signingReport`
     - Release için: senin keystore'undaki SHA-1
4. **API restrictions** → **Restrict key** → "Generative Language API" seç
5. **Save**

Bu kısıtlamayla anahtar **sadece senin uygulamandan** çağrılabilir; farklı bir
uygulamadan veya curl'den çağırırlarsa 403 alır.

> **Not (iOS)**: iOS için ayrı bir Application restriction gerek olabilir
> (Bundle ID), o zaman Cloud Console'da yine ekleyeceksin.

## 4) Test Et

Uygulamayı `--dart-define` ile başlat → Kalori Sayacı → **Öğün Ekle** →
arama sonucu boşsa veya yemek listede yoksa alttaki **"AI tahmin"** butonu
görünür olmalı. Tıkla, yemek adı yaz, "Tahmin Et".

### Anahtarın çalışıp çalışmadığını anlamak

- `--dart-define` verilmemişse: "AI tahmin" butonu hiç görünmez (`FoodEstimationService.isConfigured` false döner)
- Verilmiş ama yanlışsa: "Tahmin Et" tıklanır, kırmızı hata kutusu çıkar ("API anahtarı geçersiz...")
- Çalışıyorsa: birkaç saniye yükleme, sonra yeşil önizleme kartı

## 5) Maliyet Takibi

[Google Cloud Console — Quotas](https://console.cloud.google.com/iam-admin/quotas) altında **Generative Language API** filtresi ile günlük tüketimi izleyebilirsin. Free tier limitlerinin altında kalman için budget alert kurman önerilir.

## 6) İleride Cloud Functions'a Geçiş

Uygulama büyürse anahtarı tamamen server tarafına almak için Firebase
Functions üzerinden proxy yazabilirsin. Bu, anahtarın hiç client'a inmeyeceği
en güvenli yol — ancak Firebase Blaze (faturalı) planı zorunlu. Şu anki
yapıda `FoodEstimationService` doğrudan Gemini'yi çağırır; Functions'a
taşıma noktasında bu servisin gövdesini bir HTTPS çağrısıyla değiştirmek
yeterli olacak.
