import 'package:flutter/foundation.dart';
import '../../../models/product_model.dart';
import '../../../services/firestore_service.dart';
import 'dart:async'; // StreamSubscription için

class ProductProvider with ChangeNotifier {
  final FirestoreService _firestoreService;
  List<ProductModel> _products = [];
  bool _isLoading = false;
  StreamSubscription<List<ProductModel>>? _productsSubscription; // Stream'i dinlemek için

  ProductProvider(this._firestoreService) {
    fetchProducts(); // Provider oluşturulduğunda ürünleri çekmeye başla
  }

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;

  void fetchProducts() {
    _isLoading = true;
    notifyListeners();

    // Önceki dinleyiciyi iptal et (varsa)
    _productsSubscription?.cancel();

    // Firestore'dan gelen stream'i dinle
    _productsSubscription = _firestoreService.getProducts().listen((productsData) {
      _products = productsData;
      _isLoading = false;
      print("ProductProvider: ${productsData.length} ürün yüklendi.");
      notifyListeners(); // UI'ı güncelle
    }, onError: (error) {
      print("ProductProvider Hata: $error");
      _isLoading = false;
      _products = []; // Hata durumunda listeyi boşalt
      notifyListeners();
    });
  }

  // Provider yok edildiğinde StreamSubscription'ı iptal etmeyi unutma!
  @override
  void dispose() {
    _productsSubscription?.cancel();
    super.dispose();
  }
}
