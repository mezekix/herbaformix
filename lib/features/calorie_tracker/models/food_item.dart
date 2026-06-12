/// Yerel yemek veritabanından (assets/data/food_database.json) yüklenen
/// tek bir yemek/içecek/yiyecek girişi.
///
/// Şema örneği:
/// ```json
/// {
///   "id": "tavuklu_pilav",
///   "name": "Tavuklu Pilav",
///   "aliases": ["tavuk pilav", "pirinçli tavuk"],
///   "category": "ana_yemek",
///   "defaultServingSize": 1,
///   "defaultServingUnit": "porsiyon",
///   "caloriesPerServing": 450
/// }
/// ```
///
/// **`defaultServingUnit`** olası değerler: `porsiyon`, `gram`, `adet`,
/// `bardak`, `dilim`, `kase`, `tabak`, `kaşık`, `şişe`, `kutu`.
///
/// **`aliases`** Türkçe arama esnekliği içindir — kullanıcının yazabileceği
/// alternatif isimler (yazım hataları değil, anlamlı varyantlar).
class FoodItem {
  /// Stabil id (slug). Eklenmiş öğünde referans için kullanılabilir.
  final String id;

  /// Kullanıcıya gösterilen isim. Türkçe karakterli, doğru yazılmış.
  final String name;

  /// Ek arama anahtarları. Kullanıcı bunlardan birini yazınca da bulunur.
  final List<String> aliases;

  /// Kategori — `ana_yemek`, `corba`, `kahvalti`, `icecek`, `meyve`,
  /// `sebze`, `atistirmalik`, `tatli`, `et_urunu`, `sut_urunu`, `bakliyat`,
  /// `paketli_urun`, `fast_food`.
  final String category;

  /// Varsayılan porsiyon büyüklüğü (genelde 1 — "1 porsiyon", "100 gram" gibi).
  final double defaultServingSize;

  /// Porsiyon birimi: porsiyon / gram / adet / bardak / dilim / vs.
  final String defaultServingUnit;

  /// Bir varsayılan porsiyonun toplam kalorisi (kcal).
  final int caloriesPerServing;

  const FoodItem({
    required this.id,
    required this.name,
    required this.aliases,
    required this.category,
    required this.defaultServingSize,
    required this.defaultServingUnit,
    required this.caloriesPerServing,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'] as String,
      name: json['name'] as String,
      aliases: (json['aliases'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      category: json['category'] as String? ?? 'diger',
      defaultServingSize: (json['defaultServingSize'] as num?)?.toDouble() ?? 1,
      defaultServingUnit: json['defaultServingUnit'] as String? ?? 'porsiyon',
      caloriesPerServing: (json['caloriesPerServing'] as num).round(),
    );
  }

  /// Kullanıcının seçtiği [multiplier] çarpanına göre toplam kaloriyi döner.
  /// Örn: 1× tavuklu pilav = 450 kcal, 0.5× = 225 kcal.
  int caloriesFor(double multiplier) =>
      (caloriesPerServing * multiplier).round();

  /// "1 porsiyon" / "2 dilim" gibi insan okunabilir porsiyon metni.
  String servingLabel(double multiplier) {
    final size = defaultServingSize * multiplier;
    final sizeText = _formatNumber(size);
    return '$sizeText $defaultServingUnit';
  }

  static String _formatNumber(double n) {
    if (n == n.truncateToDouble()) return n.toInt().toString();
    return n.toStringAsFixed(1);
  }
}
