import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../models/scheduled_follow_up_model.dart';
import '../../../services/firestore_service.dart';
import '../../auth/providers/auth_provider.dart';

/// Ana sayfanın ihtiyaç duyduğu verileri ve durumu yöneten Provider.
class HomeProvider with ChangeNotifier {
  final FirestoreService _firestoreService;
  final AuthProvider _authProvider;

  String? _currentUserId;
  StreamSubscription<List<ScheduledFollowUpModel>>?
  _upcomingFollowUpsSubscription;

  List<ScheduledFollowUpModel> _upcomingFollowUps = [];
  List<ScheduledFollowUpModel> get upcomingFollowUps => _upcomingFollowUps;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  HomeProvider(this._firestoreService, this._authProvider) {
    _currentUserId = _authProvider.firebaseUser?.uid;
    _authProvider.addListener(_authListener);
    if (_currentUserId != null) {
      _listenToUpcomingFollowUps(_currentUserId!);
    }
  }

  void _authListener() {
    final newUserId = _authProvider.firebaseUser?.uid;
    if (newUserId != _currentUserId) {
      _currentUserId = newUserId;
      _upcomingFollowUpsSubscription?.cancel();
      _upcomingFollowUps = [];
      if (_currentUserId != null) {
        _listenToUpcomingFollowUps(_currentUserId!);
      } else {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Danışmana ait, önümüzdeki 7 gün içindeki tamamlanmamış görevleri dinler.
  void _listenToUpcomingFollowUps(String userId) {
    _isLoading = true;
    notifyListeners();

    _upcomingFollowUpsSubscription?.cancel();

    // Gelecek 7 günü kapsayacak şekilde bitiş tarihini hesapla.
    final inTheNext = DateTime.now().add(const Duration(days: 7));

    _upcomingFollowUpsSubscription = _firestoreService
        .getUpcomingFollowUpsForConsultant(userId, inTheNext)
        .listen(
          (data) {
            _upcomingFollowUps = data;
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            print("HomeProvider Hata (listenToUpcomingFollowUps): $error");
            _isLoading = false;
            _upcomingFollowUps = [];
            notifyListeners();
          },
        );
  }

  @override
  void dispose() {
    _upcomingFollowUpsSubscription?.cancel();
    _authProvider.removeListener(_authListener);
    super.dispose();
  }
}
