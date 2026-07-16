import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum FavoriteType { product, recipe }

class FavoritesProvider extends ChangeNotifier {
  FavoritesProvider({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  final Set<String> _favoriteKeys = {};
  String? _userId;

  bool isFavorite(FavoriteType type, String itemId) =>
      _favoriteKeys.contains(_key(type, itemId));

  Set<String> favoriteIds(FavoriteType type) => Set.unmodifiable(
        _favoriteKeys
            .where((key) => key.startsWith('${type.name}_'))
            .map((key) => key.substring(type.name.length + 1)),
      );

  void updateUser(String? userId) {
    if (_userId == userId) return;
    _subscription?.cancel();
    _subscription = null;
    _userId = userId;
    _favoriteKeys.clear();
    if (userId == null || userId.isEmpty) {
      notifyListeners();
      return;
    }
    _subscription = _firestore
        .collection('userProfiles')
        .doc(userId)
        .collection('favorites')
        .snapshots()
        .listen((snapshot) {
          _favoriteKeys
            ..clear()
            ..addAll(snapshot.docs.map((document) => document.id));
          notifyListeners();
        });
  }

  Future<void> toggle(FavoriteType type, String itemId) async {
    final userId = _userId;
    if (userId == null || itemId.isEmpty) return;
    final key = _key(type, itemId);
    final reference = _firestore
        .collection('userProfiles')
        .doc(userId)
        .collection('favorites')
        .doc(key);
    if (isFavorite(type, itemId)) {
      await reference.delete();
    } else {
      await reference.set({
        'type': type.name,
        'itemId': itemId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  String _key(FavoriteType type, String itemId) => '${type.name}_$itemId';

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
