import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../models/inventory_item_model.dart';
import '../../../models/inventory_movement_model.dart';
import '../../../models/product_model.dart';
import '../../../models/user_role.dart';
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
  StreamSubscription<List<InventoryMovementModel>>? _movementSubscription;

  List<InventoryItemModel> _items = const [];
  List<InventoryMovementModel> _movements = const [];
  bool _isLoading = false;
  String? _error;
  String? _currentUserId;
  UserRole? _currentRole;

  List<InventoryItemModel> get items => _items;
  List<InventoryMovementModel> get movements => _movements;
  List<InventoryItemModel> get lowStockItems =>
      _items.where((item) => item.isLowStock).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get stockValue => _items.fold(
    0,
    (total, item) => total + (item.onHandQuantity * item.averageUnitCost),
  );
  double get personalUseCost =>
      _movementCost(InventoryMovementType.personalUse);
  double get salesCost =>
      _movementCost(InventoryMovementType.sale) -
      _movementCost(InventoryMovementType.customerReturn);
  double get purchaseCost => _movementCost(InventoryMovementType.purchase);

  double _movementCost(InventoryMovementType type) => _movements
      .where((movement) => movement.type == type)
      .fold(
        0,
        (total, movement) =>
            total + (movement.quantityDelta.abs() * movement.unitCost),
      );

  void _onAuthChanged() {
    final userId = _authProvider.firebaseUser?.uid;
    final role = _authProvider.userProfile?.role;
    if (userId == _currentUserId && role == _currentRole) return;
    _currentUserId = userId;
    _currentRole = role;
    _inventorySubscription?.cancel();
    _movementSubscription?.cancel();
    _inventorySubscription = null;
    _movementSubscription = null;
    _items = const [];
    _movements = const [];
    final isCoach =
        role == UserRole.distributor ||
        role == UserRole.supervisor ||
        role == UserRole.successCreator;
    if (userId == null || !isCoach) {
      _isLoading = false;
      _error = null;
      notifyListeners();
      return;
    }
    _isLoading = true;
    _inventorySubscription = _repository
        .watchInventory(userId)
        .listen(
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
    _movementSubscription = _repository
        .watchMovements(userId)
        .listen(
          (movements) {
            _movements = movements;
            notifyListeners();
          },
          onError: (Object error) {
            _error = error.toString();
            notifyListeners();
          },
        );
  }

  Future<void> addInitialCount({
    required ProductModel product,
    required int quantity,
    required double unitCost,
    String? note,
    DateTime? occurredAt,
  }) => _record(
    product: product,
    quantityDelta: quantity,
    unitCost: unitCost,
    type: InventoryMovementType.initialCount,
    note: note,
    occurredAt: occurredAt,
  );

  Future<void> addPurchase({
    required ProductModel product,
    required int quantity,
    required double unitCost,
    String? note,
    DateTime? occurredAt,
  }) => _record(
    product: product,
    quantityDelta: quantity,
    unitCost: unitCost,
    type: InventoryMovementType.purchase,
    note: note,
    occurredAt: occurredAt,
  );

  Future<void> recordPersonalUse({
    required ProductModel product,
    required int quantity,
    String? note,
    DateTime? occurredAt,
  }) => _record(
    product: product,
    quantityDelta: -quantity,
    unitCost: 0,
    type: InventoryMovementType.personalUse,
    note: note,
    occurredAt: occurredAt,
  );

  Future<void> adjustStock({
    required ProductModel product,
    required int quantityDelta,
    required String note,
    DateTime? occurredAt,
  }) => _record(
    product: product,
    quantityDelta: quantityDelta,
    unitCost: 0,
    type: quantityDelta > 0
        ? InventoryMovementType.adjustmentIncrease
        : InventoryMovementType.adjustmentDecrease,
    note: note,
    occurredAt: occurredAt,
  );

  Future<void> _record({
    required ProductModel product,
    required int quantityDelta,
    required double unitCost,
    required InventoryMovementType type,
    String? note,
    DateTime? occurredAt,
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
          occurredAt: Timestamp.fromDate(occurredAt ?? DateTime.now()),
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
    _movementSubscription?.cancel();
    _authProvider.removeListener(_onAuthChanged);
    super.dispose();
  }
}
