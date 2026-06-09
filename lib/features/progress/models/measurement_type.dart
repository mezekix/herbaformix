import 'package:flutter/material.dart';

/// Vücut ölçüm türü — bir tek enum, hem grafik widget'ı hem provider hem
/// ProgressEntryModel arasında ortak konuşulan dil.
///
/// Yeni bir ölçüm türü eklemek için:
/// 1. Bu enum'a yeni bir değer ekleyin
/// 2. [ProgressEntryModel] modeline alanı ekleyin
/// 3. [ProgressEntryModel.valueFor] switch'ine yeni case ekleyin
/// (Geri kalan tüm parametrik kodlar — `latestFor`, `changeFor`,
///  WeightChartWidget — otomatik olarak uyumlu hâle gelir.)
enum MeasurementType {
  weight('Kilo Değişimi', 'kg', Icons.monitor_weight_outlined),
  waist('Bel Değişimi', 'cm', Icons.straighten),
  hip('Kalça Değişimi', 'cm', Icons.straighten),
  chest('Göğüs Değişimi', 'cm', Icons.straighten),
  arm('Kol Değişimi', 'cm', Icons.straighten),
  thigh('Bacak Değişimi', 'cm', Icons.straighten),
  bodyFat('Yağ Oranı Değişimi', '%', Icons.water_drop_outlined),
  muscleMass('Kas Kütlesi Değişimi', 'kg', Icons.fitness_center);

  final String label;
  final String unit;
  final IconData icon;
  const MeasurementType(this.label, this.unit, this.icon);
}
