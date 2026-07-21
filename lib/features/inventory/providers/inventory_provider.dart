import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../models/inventory_item_model.dart';
import '../../../models/inventory_movement_model.dart';
import '../../../models/product_model.dart';
import '../../../services/repositories/inventory_repository.dart';
import '../../auth/providers/auth_provider.dart';

class InventoryProvider extends ChangeNotifier {
  InventoryProvider(this._repository, this._authProvider) {
    _authProvider.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  final InventoryRepository _repository;
  final AuthProvider _authProvider;
  StreamSubscription<List<InventoryItemModel>>? _inventorySubscription;

  List<InventoryItemModel> _items = const [];
  bool _isLoading = false;
  String? _error;
  String? _currentUserId;

  List<InventoryItemModel> get items => _items;
  List<InventoryItemModel> get lowStockItems =>
      _items.where((item) => item.isLowStock).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _onAuthChanged() {
    final userId = _authProvider.firebaseUser?.uid;
    if (userId == _currentUserId) return;
    _currentUserId = userId;
    _inventorySubscription?.cancel();
    _items = const [];
    if (userId == null) {
      notifyListeners();
      return;
    }
    _isLoading = true;
    _inventorySubscription = _repository.watchInventory(userId).listen(
      (items) {
        _items = items;
        _isLoading = false;
        notifyListeners();
      },
      onError: (Object error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> addInitialCount({
    required ProductModel product,
    required int quantity,
    required double unitCost,
    String? note,
  }) => _record(
        product: product,
        quantityDelta: quantity,
        unitCost: unitCost,
        type: InventoryMovementType.initialCount,
        note: note,
      );

  Future<void> addPurchase({
    required ProductModel product,
    required int quantity,
    required double unitCost,
    String? note,
  }) => _record(
        product: product,
        quantityDelta: quantity,
        unitCost: unitCost,
        type: InventoryMovementType.purchase,
        note: note,
      );

  Future<void> recordPersonalUse({
    required ProductModel product,
    required int quantity,
    String? note,
  }) => _record(
        product: product,
        quantityDelta: -quantity,
        unitCost: 0,
        type: InventoryMovementType.personalUse,
        note: note,
      );

  Future<void> adjustStock({
    required ProductModel product,
    required int quantityDelta,
    required String note,
  }) => _record(
        product: product,
        quantityDelta: quantityDelta,
        unitCost: 0,
        type: quantityDelta > 0
            ? InventoryMovementType.adjustmentIncrease
            : InventoryMovementType.adjustmentDecrease,
        note: note,
      );

  Future<void> _record({
    required ProductModel product,
    required int quantityDelta,
    required double unitCost,
    required InventoryMovementType type,
    String? note,
  }) async {
    final userId = _currentUserId;
    if (userId == null) throw StateError('Oturum bulunamadı.');
    if (quantityDelta == 0) throw ArgumentError('Adet sıfır olamaz.');
    _error = null;
    _isLoading = true;
    notifyListeners();
    try {
      final movementRef = _repository.movementRef(userId).doc();
      await _repository.recordMovement(
        userId,
        InventoryMovementModel(
          id: movementRef.id,
          productId: product.id,
          productName: product.name,
          stockNo: product.stockNo,
          type: type,
          quantityDelta: quantityDelta,
          unitCost: unitCost,
          occurredAt: Timestamp.now(),
          createdAt: Timestamp.now(),
          note: note?.trim().isEmpty ?? true ? null : note!.trim(),
        ),
      );
    } catch (error) {
      _error = error.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _inventorySubscription?.cancel();
    _authProvider.removeListener(_onAuthChanged);
    super.dispose();
  }
}
