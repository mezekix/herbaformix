// DailySuccessRing widget testleri.
// Bu widget hiçbir Provider'a bağımlı değil — saf prop-driven; bu yüzden
// MaterialApp altında doğrudan pump edilebilir.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:herbaformix/features/home/widgets/daily_success_ring.dart';

void main() {
  Widget pumpRing({
    double productProgress = 0.0,
    double waterProgress = 0.0,
    double exerciseProgress = 0.0,
    String activeTaskLabel = '',
    bool hasProgram = true,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: DailySuccessRing(
            productProgress: productProgress,
            waterProgress: waterProgress,
            exerciseProgress: exerciseProgress,
            activeTaskLabel: activeTaskLabel,
            hasProgram: hasProgram,
          ),
        ),
      ),
    );
  }

  group('DailySuccessRing', () {
    testWidgets('hasProgram=false → boş SizedBox render', (tester) async {
      await tester.pumpWidget(pumpRing(hasProgram: false));

      // TAMAMLANDI etiketi görünmemeli
      expect(find.text('TAMAMLANDI'), findsNothing);
      // Ürün/Su/Egzersiz legend de görünmemeli
      expect(find.textContaining('Ürün'), findsNothing);
      expect(find.textContaining('Su'), findsNothing);
    });

    testWidgets('hasProgram=true → TAMAMLANDI etiketi görünür',
        (tester) async {
      await tester.pumpWidget(pumpRing(hasProgram: true));
      await tester.pump(const Duration(milliseconds: 1100)); // entry animasyonu

      expect(find.text('TAMAMLANDI'), findsOneWidget);
    });

    testWidgets('3 legend etiketi (Ürün / Su / Egzersiz) görünür',
        (tester) async {
      await tester.pumpWidget(pumpRing(
        productProgress: 0.5,
        waterProgress: 0.8,
        exerciseProgress: 1.0,
      ));
      await tester.pump(const Duration(milliseconds: 1100));

      // Legend formatı: "Ürün %50", "Su %80", "Egzersiz %100"
      expect(find.textContaining('Ürün'), findsOneWidget);
      expect(find.textContaining('Su'), findsOneWidget);
      expect(find.textContaining('Egzersiz'), findsOneWidget);
    });

    testWidgets('legend yüzdesi prop\'larla eşleşir', (tester) async {
      await tester.pumpWidget(pumpRing(
        productProgress: 0.5,
        waterProgress: 0.75,
        exerciseProgress: 1.0,
      ));
      await tester.pump(const Duration(milliseconds: 1100));

      expect(find.text('Ürün %50'), findsOneWidget);
      expect(find.text('Su %75'), findsOneWidget);
      expect(find.text('Egzersiz %100'), findsOneWidget);
    });

    testWidgets('activeTaskLabel verildiğinde gösterilir', (tester) async {
      await tester.pumpWidget(pumpRing(
        activeTaskLabel: 'Sabah Öğünü',
        productProgress: 0.3,
      ));
      await tester.pump(const Duration(milliseconds: 1100));

      expect(find.text('Sabah Öğünü'), findsOneWidget);
    });

    testWidgets('activeTaskLabel boşsa gösterilmez', (tester) async {
      await tester.pumpWidget(pumpRing(
        productProgress: 0.3,
      ));
      await tester.pump(const Duration(milliseconds: 1100));

      // boş label render edilmemeli — TAMAMLANDI var ama özel label yok
      expect(find.text(''), findsNothing);
    });

    testWidgets('0% tüm dilimler için yüzde 0 gösterir', (tester) async {
      await tester.pumpWidget(pumpRing());
      await tester.pump(const Duration(milliseconds: 1100));

      // Ortalama yüzde 0 → "%0" görünmeli
      expect(find.text('%0'), findsOneWidget);
    });

    testWidgets('hepsi 1.0 → ortalama %100 gösterir', (tester) async {
      await tester.pumpWidget(pumpRing(
        productProgress: 1.0,
        waterProgress: 1.0,
        exerciseProgress: 1.0,
      ));
      await tester.pump(const Duration(milliseconds: 1100));

      expect(find.text('%100'), findsOneWidget);
    });

    testWidgets('orta seviye → doğru ortalama yüzde', (tester) async {
      // (0.3 + 0.6 + 0.9) / 3 = 0.6 → %60
      await tester.pumpWidget(pumpRing(
        productProgress: 0.3,
        waterProgress: 0.6,
        exerciseProgress: 0.9,
      ));
      await tester.pump(const Duration(milliseconds: 1100));

      expect(find.text('%60'), findsOneWidget);
    });

    testWidgets('prop güncellemesi yeni yüzdeyi gösterir', (tester) async {
      await tester.pumpWidget(pumpRing(productProgress: 0.2));
      await tester.pump(const Duration(milliseconds: 1100));
      expect(find.text('Ürün %20'), findsOneWidget);

      // Prop'u güncelle
      await tester.pumpWidget(pumpRing(productProgress: 0.7));
      await tester.pump(const Duration(milliseconds: 1100));
      expect(find.text('Ürün %70'), findsOneWidget);
    });

    testWidgets('CustomPaint widget\'ı render olunur', (tester) async {
      await tester.pumpWidget(pumpRing(productProgress: 0.5));
      await tester.pump(const Duration(milliseconds: 1100));

      // En az bir CustomPaint olmalı (ring painter)
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
